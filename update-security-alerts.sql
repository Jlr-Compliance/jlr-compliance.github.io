-- Security alert emails to every active Admin (12 Nov 2026)
-- Sent through the existing mail queue (mail_jobs) by the office mailbox script within about a minute.

create or replace function public.sec_alert(p_subject text, p_body text) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
declare rcpt text; who text;
begin
  select string_agg(distinct lower(email), ',') into rcpt from public.profiles where role = 'admin' and active and coalesce(email, '') <> '';
  who := coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = auth.uid()),
                  case when auth.uid() is null then 'Supabase dashboard or an automatic job' else 'a login without a profile' end);
  if rcpt is not null then
    insert into public.mail_jobs (kind, to_addr, subject, body, status)
    values ('security', rcpt, '[JLR security] ' || p_subject,
      'Security alert from the JLR Compliance tracker' || E'\n\n' || p_body ||
      E'\n\nDone by: ' || who || E'\nWhen: ' || to_char(now() at time zone 'Asia/Kolkata', 'DD Mon YYYY, HH12:MI AM') || ' IST' ||
      E'\n\nIf you did not expect this: open the tracker → Settings → Staff & senior → Sign-in security → "Sign out everyone except me", then change passwords.',
      'new');
  end if;
  insert into public.audit_log (user_id, user_name, area, action, summary) values (auth.uid(), who, 'security', 'alert', left(p_subject, 300));
end $$;

create or replace function public.sec_role_label(r text) returns text language sql immutable set search_path = public, pg_temp as $$
  select case r when 'staff' then 'Team member' when 'manager' then 'Manager' when 'partner' then 'Partner' when 'admin' then 'Admin' else coalesce(r, '?') end
$$;

-- 1. logins: new login, role change, (de)activation
create or replace function public.sec_profiles_trg() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
declare nm text := coalesce(nullif(new.full_name, ''), new.email, 'someone');
begin
  if tg_op = 'INSERT' then
    perform public.sec_alert('New login created: ' || coalesce(new.email, nm) || ' (' || public.sec_role_label(new.role) || ')',
      'A new tracker login was created for ' || nm || ' <' || coalesce(new.email, '') || '> with the role ' || public.sec_role_label(new.role) || '.');
  elsif new.role is distinct from old.role then
    perform public.sec_alert('Role changed: ' || coalesce(new.email, nm) || ' — ' || public.sec_role_label(old.role) || ' → ' || public.sec_role_label(new.role),
      nm || ' <' || coalesce(new.email, '') || '> was changed from ' || public.sec_role_label(old.role) || ' to ' || public.sec_role_label(new.role) || '.');
  elsif new.active is distinct from old.active then
    perform public.sec_alert(case when new.active then 'Login switched back on: ' else 'Login switched off: ' end || coalesce(new.email, nm),
      nm || ' <' || coalesce(new.email, '') || '> can ' || case when new.active then 'now sign in again.' else 'no longer sign in.' end);
  end if;
  return null;
end $$;
drop trigger if exists zz_sec_alert on public.profiles;
create trigger zz_sec_alert after insert or update of role, active on public.profiles for each row execute function public.sec_profiles_trg();

-- 2. large deletes in one go (threshold = trigger argument); skipped while sample data is cleared
create or replace function public.sec_bulk_delete_trg() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
declare n integer; lim integer := coalesce(nullif(tg_argv[0], '')::int, 10);
begin
  if coalesce(current_setting('jlr.no_audit', true), '') = 'on' then return null; end if;
  select count(*) into n from old_rows;
  if n >= lim then
    perform public.sec_alert('Large delete: ' || n || ' ' || replace(tg_table_name, '_', ' ') || ' records',
      n || ' records were deleted from "' || replace(tg_table_name, '_', ' ') || '" in one go. If this was not planned, restore them from the latest backup (Settings → Backup).');
  end if;
  return null;
end $$;
do $$ declare t record; begin
  for t in select * from (values ('clients', 3), ('tasks', 10), ('notices', 10), ('invoices', 5), ('payments', 5), ('filing_acks', 10),
                                 ('client_logins', 3), ('tds_returns', 10), ('mca_companies', 5), ('renewals', 10), ('gst_months', 10)) v(tbl, lim)
  loop
    if to_regclass('public.' || t.tbl) is null then continue; end if;
    execute format('drop trigger if exists zz_sec_bulk on public.%I', t.tbl);
    execute format('create trigger zz_sec_bulk after delete on public.%I referencing old table as old_rows for each statement execute function public.sec_bulk_delete_trg(%L)', t.tbl, t.lim::text);
  end loop;
end $$;

-- 3. mailbox / backup keys replaced, 2-step requirement switched off
create or replace function public.sec_settings_trg() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if tg_table_name = 'settings' then
    if new.mailjob_key_hash is distinct from old.mailjob_key_hash and old.mailjob_key_hash is not null then
      perform public.sec_alert('New key made for senior-approval & filing mails', 'The MAILJOB_KEY was replaced. The mailbox script stops sending these mails until the new key is pasted into it.');
    end if;
    if new.backup_key_hash is distinct from old.backup_key_hash and old.backup_key_hash is not null then
      perform public.sec_alert('New backup key made', 'The BACKUP_KEY was replaced. The daily OneDrive backup stops until the new key is pasted into the mailbox script.');
    end if;
    if coalesce(old.mfa_enforced, false) and not coalesce(new.mfa_enforced, false) then
      perform public.sec_alert('2-step login requirement switched OFF', 'Admin, Partner and Manager can now sign in with only a password.');
    end if;
  elsif new.key_hash is distinct from old.key_hash and old.key_hash is not null then
    perform public.sec_alert('New key made for ' || case tg_table_name when 'mail_settings' then 'client mail (INTAKE_KEY)' else 'notice watch (NOTICE_KEY)' end,
      'A mailbox key was replaced. The mailbox script stops that job until the new key is pasted into it.');
  end if;
  return null;
end $$;
drop trigger if exists zz_sec_alert on public.settings;
create trigger zz_sec_alert after update on public.settings for each row execute function public.sec_settings_trg();
drop trigger if exists zz_sec_alert on public.mail_settings;
create trigger zz_sec_alert after update of key_hash on public.mail_settings for each row execute function public.sec_settings_trg();
drop trigger if exists zz_sec_alert on public.notice_watch;
create trigger zz_sec_alert after update of key_hash on public.notice_watch for each row execute function public.sec_settings_trg();

-- 4. Admin actions on sign-in security
create or replace function public.admin_reset_mfa(p_user uuid) returns void
language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare nm text;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_user = auth.uid() then raise exception 'Ask the other Admin to reset your own 2-step login.'; end if;
  select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = p_user;
  delete from auth.mfa_factors where user_id = p_user;
  delete from auth.sessions where user_id = p_user;
  perform public.sec_alert('2-step login reset for ' || coalesce(nm, 'a user'), coalesce(nm, 'A user') || ' must set up the authenticator again at the next sign-in, and was signed out everywhere.');
end $$;

create or replace function public.admin_sign_out(p_user uuid default null) returns integer
language plpgsql security definer set search_path = public, auth, pg_temp as $$
declare n integer; nm text;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_user is null then
    delete from auth.sessions where user_id <> auth.uid();
    get diagnostics n = row_count;
    perform public.sec_alert('Everyone signed out', 'All logins except the Admin who did this were signed out on every device (' || n || ' sessions).');
  else
    select coalesce(nullif(full_name, ''), email) into nm from public.profiles where id = p_user;
    delete from auth.sessions where user_id = p_user;
    get diagnostics n = row_count;
  end if;
  return n;
end $$;

revoke all on function public.sec_alert(text, text) from public, anon, authenticated;
revoke all on function public.sec_role_label(text) from public, anon;
revoke all on function public.sec_profiles_trg() from public, anon, authenticated;
revoke all on function public.sec_bulk_delete_trg() from public, anon, authenticated;
revoke all on function public.sec_settings_trg() from public, anon, authenticated;
revoke all on function public.admin_reset_mfa(uuid) from public, anon;
revoke all on function public.admin_sign_out(uuid) from public, anon;
grant execute on function public.admin_reset_mfa(uuid) to authenticated;
grant execute on function public.admin_sign_out(uuid) to authenticated;
