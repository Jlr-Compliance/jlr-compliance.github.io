// Supabase Edge Function: backup-export  (Verify JWT OFF — checked by header x-backup-key)
// Used by the office mailbox script's daily OneDrive backup.
//   POST {action:"data"}                 -> { tables: { <name>: [rows] }, at }
//   POST {action:"files", since:"<iso>"} -> { files: [{bucket,name,created_at,size,url}] }  (signed URLs, 1 hour)
//   POST {action:"report", ok, note, files_upto} -> { ok:true }
import { createClient } from 'jsr:@supabase/supabase-js@2';

const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'content-type, x-backup-key' };
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } });

async function sha(t: string) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(t));
  return [...new Uint8Array(d)].map(x => x.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async req => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'POST only' }, 405);
  const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
  const key = req.headers.get('x-backup-key') || '';
  const { data: st } = await sb.from('settings').select('backup_key_hash').eq('id', 1).maybeSingle();
  if (!key || !st?.backup_key_hash || (await sha(key)) !== st.backup_key_hash) return json({ error: 'Wrong or missing backup key' }, 401);
  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch (_) { /* empty */ }

  if (body.action === 'data') {
    const { data: names, error } = await sb.rpc('backup_tables');
    if (error) return json({ error: error.message }, 500);
    const tables: Record<string, unknown[]> = {};
    for (const n of (names as string[])) {
      const rows: unknown[] = [];
      for (let from = 0; ; from += 1000) {
        const { data, error: e } = await sb.from(n).select('*').range(from, from + 999);
        if (e) { tables[n] = [{ _error: e.message }]; break; }
        rows.push(...(data || []));
        if (!data || data.length < 1000) { tables[n] = rows; break; }
      }
    }
    return json({ at: new Date().toISOString(), tables });
  }

  if (body.action === 'files') {
    const { data: list, error } = await sb.rpc('backup_files_since', { p_since: body.since || null });
    if (error) return json({ error: error.message }, 500);
    const files = [];
    for (const f of (list as { bucket_id: string; name: string; created_at: string; size: number }[])) {
      const { data: s } = await sb.storage.from(f.bucket_id).createSignedUrl(f.name, 3600);
      files.push({ bucket: f.bucket_id, name: f.name, created_at: f.created_at, size: f.size, url: s?.signedUrl || null });
    }
    return json({ files });
  }

  if (body.action === 'report') {
    const patch: Record<string, unknown> = { backup_last_at: new Date().toISOString(), backup_last_ok: !!body.ok, backup_last_note: String(body.note || '').slice(0, 300) };
    if (body.files_upto) patch.backup_files_upto = body.files_upto;
    await sb.from('settings').update(patch).eq('id', 1);
    return json({ ok: true });
  }
  return json({ error: 'Unknown action' }, 400);
});
