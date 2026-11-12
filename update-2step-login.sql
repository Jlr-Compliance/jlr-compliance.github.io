-- 2-step login (authenticator code) — 12 Nov 2026
-- The code is enforced in the database, not only on screen: once switched on, an Admin/Partner/Manager
-- session without the code (aal1) is treated as "not a member" by every security rule and function.

alter table public.settings add column if not exists mfa_enforced boolean not null default false;

-- true when this session may use the tracker's data
create or replace function public.mfa_ok() returns boolean
language sql stable security definer set search_path = public, auth, pg_temp as $$
  select coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
     or (
       not exists (select 1 from auth.mfa_factors f where f.user_id = auth.uid() and f.status = 'verified')
       and not (
         coalesce((select s.mfa_enforced from public.settings s where s.id = 1), false)
         and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin', 'partner', 'manager'))
       )
     )
$$;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (select 1 from public.profiles where id = auth.uid() and active) and public.mfa_ok();
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin' and active) and public.mfa_ok();
$$;
create or replace function public.is_manager() returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'partner', 'manager') and active) and public.mfa_ok();
$$;
create or replace function public.is_partner() returns boolean
language sql stable security definer set search_path = public, extensions, pg_temp as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'partner') and active) and public.mfa_ok();
$$;

-- everyone can always read their own profile (needed before the code is entered)
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles for select to authenticated using (id = auth.uid());

-- what the sign-in screen needs to know
create or replace function public.mfa_policy() returns jsonb
language sql stable security definer set search_path = public, auth, pg_temp as $$
  select jsonb_build_object(
    'enforced', coalesce((select s.mfa_enforced from public.settings s where s.id = 1), false),
    'required', coalesce((select s.mfa_enforced from public.settings s where s.id = 1), false)
                and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin', 'partner', 'manager') and p.active),
    'has_factor', exists (select 1 from auth.mfa_factors f where f.user_id = auth.uid() and f.status = 'verified'),
    'aal', coalesce(auth.jwt() ->> 'aal', 'aal1'));
$$;

-- Admin: who has 2-step, last sign-in, open sessions
create or replace function public.admin_security_list() returns jsonb
language plpgsql stable security definer set search_path = public, auth, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'id', p.id, 'name', coalesce(p.full_name, p.email), 'email', p.email, 'role', p.role, 'active', p.active,
      'mfa', exists (select 1 from auth.mfa_factors f where f.user_id = p.id and f.status = 'verified'),
      'last_sign_in', u.last_sign_in_at,
      'sessions', (select count(*) from auth.sessions s where s.user_id = p.id)
    ) order by p.role, coalesce(p.full_name, p.email))
    from public.profiles p left join auth.users u on u.id = p.id), '[]'::jsonb);
end $$;

-- Admin: remove someone's authenticator (lost phone) and sign them out
create or replace function public.admin_reset_mfa(p_user uuid) returns void
language plpgsql security definer set search_path = public, auth, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_user = auth.uid() then raise exception 'Ask the other Admin to reset your own 2-step login.'; end if;
  delete from auth.mfa_factors where user_id = p_user;
  delete from auth.sessions where user_id = p_user;
end $$;

-- Admin: sign out one person on all devices, or everyone except me (p_user null)
create or replace function public.admin_sign_out(p_user uuid default null) returns integer
language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare n integer;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_user is null then delete from auth.sessions where user_id <> auth.uid();
  else delete from auth.sessions where user_id = p_user; end if;
  get diagnostics n = row_count;
  return n;
end $$;

-- Admin: switch the requirement on/off (only if you have set up your own code first)
create or replace function public.set_mfa_enforced(p_on boolean) returns void
language plpgsql security definer set search_path = public, auth, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_on and not exists (select 1 from auth.mfa_factors f where f.user_id = auth.uid() and f.status = 'verified') then
    raise exception 'Set up your own 2-step login first (name menu → 2-step login), then switch this on.';
  end if;
  update public.settings set mfa_enforced = p_on where id = 1;
end $$;

revoke all on function public.mfa_ok() from public, anon;
revoke all on function public.mfa_policy() from public, anon;
revoke all on function public.admin_security_list() from public, anon;
revoke all on function public.admin_reset_mfa(uuid) from public, anon;
revoke all on function public.admin_sign_out(uuid) from public, anon;
revoke all on function public.set_mfa_enforced(boolean) from public, anon;
grant execute on function public.mfa_ok() to authenticated;
grant execute on function public.mfa_policy() to authenticated;
grant execute on function public.admin_security_list() to authenticated;
grant execute on function public.admin_reset_mfa(uuid) to authenticated;
grant execute on function public.admin_sign_out(uuid) to authenticated;
grant execute on function public.set_mfa_enforced(boolean) to authenticated;
