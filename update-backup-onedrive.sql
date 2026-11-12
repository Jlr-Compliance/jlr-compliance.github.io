-- Daily backup to OneDrive (12 Nov 2026)
alter table public.settings
  add column if not exists backup_key_hash text,
  add column if not exists backup_key_set_at timestamptz,
  add column if not exists backup_last_at timestamptz,
  add column if not exists backup_last_ok boolean,
  add column if not exists backup_last_note text,
  add column if not exists backup_files_upto timestamptz;

create or replace function public.set_backup_key(p_hash text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Only the Admin can do that.'; end if;
  if p_hash !~ '^[0-9a-f]{64}$' then raise exception 'Bad key'; end if;
  update public.settings set backup_key_hash = p_hash, backup_key_set_at = now() where id = 1;
end $$;
revoke all on function public.set_backup_key(text) from public, anon;
grant execute on function public.set_backup_key(text) to authenticated;

-- used only by the backup-export function (service role)
create or replace function public.backup_tables() returns setof text
language sql security definer set search_path = public as $$
  select c.relname::text from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and c.relname not in ('backups', '_export') order by 1
$$;
create or replace function public.backup_files_since(p_since timestamptz)
returns table (bucket_id text, name text, created_at timestamptz, size bigint)
language sql security definer set search_path = public, storage as $$
  select o.bucket_id, o.name, o.created_at, coalesce((o.metadata->>'size')::bigint, 0)
  from storage.objects o
  where o.created_at > coalesce(p_since, '1970-01-01'::timestamptz)
    and o.bucket_id in ('client-docs', 'filing-acks')
    and o.name not like '%.emptyFolderPlaceholder'
  order by o.created_at limit 60
$$;
revoke all on function public.backup_tables() from public, anon, authenticated;
revoke all on function public.backup_files_since(timestamptz) from public, anon, authenticated;
grant execute on function public.backup_tables() to service_role;
grant execute on function public.backup_files_since(timestamptz) to service_role;
