-- Arattai daily work reminders through IFTTT webhooks (13 Nov 2026)
-- A: one message to the team group (everyone's work, by name)   B: one message per person to their own private group
create table if not exists public.arattai_settings (
  id integer primary key default 1 check (id = 1),
  enabled boolean not null default false,
  team_on boolean not null default true,
  personal_on boolean not null default false,
  team_event text not null default 'jlr_team',
  last_run_at timestamptz,
  last_note text
);
insert into public.arattai_settings (id) values (1) on conflict do nothing;
alter table public.arattai_settings enable row level security;
revoke all on public.arattai_settings from anon, authenticated;
alter table public.profiles add column if not exists arattai_event text;

-- one person's work as plain text
create or replace function public.arattai_person_text(p_user uuid, p_today date) returns text
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare n_over int; n_soon int; n_wait int; l_over text; l_soon text;
begin
  select count(*) filter (where due_date < p_today), count(*) filter (where due_date between p_today and p_today + 3), count(*) filter (where status = 'Pending data')
    into n_over, n_soon, n_wait
    from public.tasks where assigned_to = p_user and status not in ('Filed', 'Not applicable');
  if n_over + n_soon + n_wait = 0 then return null; end if;
  select string_agg('  • ' || t.return_name || ' — ' || c.name || ' (due ' || to_char(t.due_date, 'DD Mon') || ')', E'\n' order by t.due_date)
    into l_over from (select * from public.tasks where assigned_to = p_user and status not in ('Filed', 'Not applicable') and due_date < p_today order by due_date limit 8) t
    join public.clients c on c.id = t.client_id;
  select string_agg('  • ' || t.return_name || ' — ' || c.name || ' (' || to_char(t.due_date, 'DD Mon') || ')', E'\n' order by t.due_date)
    into l_soon from (select * from public.tasks where assigned_to = p_user and status not in ('Filed', 'Not applicable') and due_date between p_today and p_today + 3 order by due_date limit 8) t
    join public.clients c on c.id = t.client_id;
  return concat_ws(E'\n',
    case when n_over > 0 then '🔴 Overdue: ' || n_over || E'\n' || l_over || case when n_over > 8 then E'\n  … and ' || (n_over - 8) || ' more' else '' end end,
    case when n_soon > 0 then '🟠 Due in next 3 days: ' || n_soon || E'\n' || l_soon || case when n_soon > 8 then E'\n  … and ' || (n_soon - 8) || ' more' else '' end end,
    case when n_wait > 0 then '⏳ Waiting for client data: ' || n_wait end);
end $$;

create or replace function public.arattai_post(p_event text, p_text text) returns bigint
language plpgsql security definer set search_path = public, pg_temp as $$
declare k text; req bigint;
begin
  select decrypted_secret into k from vault.decrypted_secrets where name = 'ifttt_key' limit 1;
  if k is null or coalesce(p_event, '') = '' or coalesce(p_text, '') = '' then return null; end if;
  select net.http_post(url := 'https://maker.ifttt.com/trigger/' || p_event || '/with/key/' || k,
                       headers := '{"Content-Type":"application/json"}'::jsonb,
                       body := jsonb_build_object('value1', left(p_text, 3800)), timeout_milliseconds := 20000) into req;
  return req;
end $$;

-- daily job (9:30 AM IST, Mon–Sat)
create or replace function public.arattai_daily(p_force boolean default false) returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
declare s public.arattai_settings; today date := (now() at time zone 'Asia/Kolkata')::date; p record; txt text; team text := ''; sent int := 0; site text;
begin
  select * into s from public.arattai_settings where id = 1;
  if not s.enabled and not p_force then return 0; end if;
  if not p_force and s.last_run_at is not null and (s.last_run_at at time zone 'Asia/Kolkata')::date = today then return 0; end if;
  site := coalesce((select regexp_replace(app_url, '/?$', '/') from public.wa_settings where id = 1), '');
  for p in select * from public.profiles where active and role in ('staff', 'manager', 'partner', 'admin') order by coalesce(full_name, email) loop
    txt := public.arattai_person_text(p.id, today);
    continue when txt is null;
    team := team || E'\n\n👤 ' || coalesce(nullif(p.full_name, ''), p.email) || E'\n' || txt;
    if s.personal_on and coalesce(p.arattai_event, '') <> '' then
      if public.arattai_post(p.arattai_event, 'Good morning ' || split_part(coalesce(nullif(p.full_name, ''), 'there'), ' ', 1) || ' — your work for ' || to_char(today, 'DD Mon') || E'\n\n' || txt || E'\n\nOpen the tracker: ' || site) is not null then sent := sent + 1; end if;
    end if;
  end loop;
  if s.team_on then
    if public.arattai_post(s.team_event, 'JLR — today''s work, ' || to_char(today, 'Dy DD Mon') || coalesce(nullif(team, ''), E'\n\nNothing overdue or due in the next 3 days 🎉') || E'\n\nOpen the tracker: ' || site) is not null then sent := sent + 1; end if;
  end if;
  update public.arattai_settings set last_run_at = now(), last_note = sent || ' message(s) sent' where id = 1;
  return sent;
end $$;

-- admin functions for Settings
create or replace function public.arattai_admin_status() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  return (select to_jsonb(s) || jsonb_build_object('key_saved', exists (select 1 from vault.secrets where name = 'ifttt_key'),
      'people', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', coalesce(nullif(p.full_name, ''), p.email), 'role', p.role, 'event', p.arattai_event) order by coalesce(p.full_name, p.email)), '[]'::jsonb)
                 from public.profiles p where p.active and p.role in ('staff', 'manager', 'partner', 'admin')))
    from public.arattai_settings s where s.id = 1);
end $$;
create or replace function public.arattai_admin_save(p jsonb) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
declare x jsonb;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  update public.arattai_settings set enabled = coalesce((p->>'enabled')::boolean, enabled), team_on = coalesce((p->>'team_on')::boolean, team_on),
    personal_on = coalesce((p->>'personal_on')::boolean, personal_on),
    team_event = coalesce(nullif(regexp_replace(lower(p->>'team_event'), '[^a-z0-9_]', '', 'g'), ''), team_event) where id = 1;
  for x in select * from jsonb_array_elements(coalesce(p->'people', '[]'::jsonb)) loop
    update public.profiles set arattai_event = nullif(regexp_replace(lower(x->>'event'), '[^a-z0-9_]', '', 'g'), '') where id = (x->>'id')::uuid;
  end loop;
end $$;
create or replace function public.arattai_admin_set_key(p_key text) returns void
language plpgsql security definer set search_path = public, pg_temp as $$
declare sid uuid;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  select id into sid from vault.secrets where name = 'ifttt_key';
  if coalesce(trim(p_key), '') = '' then if sid is not null then delete from vault.secrets where id = sid; end if; return; end if;
  if sid is null then perform vault.create_secret(trim(p_key), 'ifttt_key', 'IFTTT webhooks key for Arattai reminders');
  else perform vault.update_secret(sid, trim(p_key)); end if;
end $$;
create or replace function public.arattai_admin_test(p_target text) returns text
language plpgsql security definer set search_path = public, pg_temp as $$
declare s public.arattai_settings; p public.profiles; txt text; today date := (now() at time zone 'Asia/Kolkata')::date;
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  select * into s from public.arattai_settings where id = 1;
  if p_target = 'team' then
    if public.arattai_post(s.team_event, 'Test from the JLR tracker ✅ — the daily team work list will arrive here at 9:30 AM (Mon–Sat).') is null then return 'Save the IFTTT key first'; end if;
    return 'Test sent to event ' || s.team_event;
  end if;
  select * into p from public.profiles where id = p_target::uuid;
  if coalesce(p.arattai_event, '') = '' then return 'Save an event name for this person first'; end if;
  txt := coalesce(public.arattai_person_text(p.id, today), 'Nothing overdue or due in the next 3 days.');
  if public.arattai_post(p.arattai_event, 'Test from the JLR tracker ✅ for ' || coalesce(p.full_name, p.email) || E'\n\n' || txt) is null then return 'Save the IFTTT key first'; end if;
  return 'Test sent to event ' || p.arattai_event;
end $$;

revoke all on function public.arattai_person_text(uuid, date) from public, anon, authenticated;
revoke all on function public.arattai_post(text, text) from public, anon, authenticated;
revoke all on function public.arattai_daily(boolean) from public, anon, authenticated;
revoke all on function public.arattai_admin_status() from public, anon;
revoke all on function public.arattai_admin_save(jsonb) from public, anon;
revoke all on function public.arattai_admin_set_key(text) from public, anon;
revoke all on function public.arattai_admin_test(text) from public, anon;
grant execute on function public.arattai_admin_status() to authenticated;
grant execute on function public.arattai_admin_save(jsonb) to authenticated;
grant execute on function public.arattai_admin_set_key(text) to authenticated;
grant execute on function public.arattai_admin_test(text) to authenticated;

select cron.unschedule('arattai-daily') where exists (select 1 from cron.job where jobname = 'arattai-daily');
select cron.schedule('arattai-daily', '0 4 * * 1-6', 'select public.arattai_daily()');

-- "Send today's lists now" button (Admin): sends even if already sent today
create or replace function public.arattai_send_now() returns integer
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  return public.arattai_daily(true);
end $$;
revoke all on function public.arattai_send_now() from public, anon;
grant execute on function public.arattai_send_now() to authenticated;
