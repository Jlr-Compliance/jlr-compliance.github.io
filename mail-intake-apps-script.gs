/* =====================================================================
   JLR TRACKER - office mailbox -> tracker (runs every minute in Google Apps Script)   v4.2 (Nov 2026)
   A. Client mail: sends attachments from client emails to the tracker. The tracker decides who is
      a client; mail from anyone else is only labelled "JLR/Not a client" and nothing is stored.
      To retry such a mail (after saving that email on the client), remove the label in Gmail.
   B. Notice watch: emails from the GST, Income-tax, TRACES and MCA portals (and client emails that
      forward a notice) are read and added to Notices. Managers and Partners get an email for each
      new notice, and a summary every morning (8 AM) and night (8 PM). "Check now" on the Notices
      page makes this script check within a minute.
   C. Data reminders: sends the "please send your documents" emails that the tracker prepares
      (Settings -> Automatic data chasing) from this mailbox. Client replies with files come back
      here and are picked up by A.
   D. Senior verification & filing mails (v4): sends the tracker's emails WITH attachments (GST workings to the
      senior, acknowledgement + workings to the client, daily status reminders) and reads the senior's replies
      to "[JLR-REVIEW:…]" emails ("Approved" on the first line approves; anything else goes back as remarks).

   E. Daily backup to OneDrive (v4.1): every night about 1 AM all tracker data goes to OneDrive as one zip
      (Excel-ready CSV per table + all-data.json), and new client files / acknowledgements are copied once.
      Extra properties: BACKUP_KEY (Tracker: Settings -> Backup), MS_CLIENT_ID (your Microsoft app).
      Run connectOneDrive once, open the link it prints, enter the code, sign in; then run finishOneDrive.

   Setup (once, signed in to the office Gmail):
   1. script.google.com -> open "JLR mail intake" (or New project) -> replace the code with this file -> Save
   2. Project Settings (gear) -> Script properties:
        INTAKE_KEY = <key from Tracker: Settings -> Client mail>
        NOTICE_KEY = <key from Tracker: Settings -> Notice watch -> Make key>
        MAILJOB_KEY = <key from Tracker: Settings -> Senior verification & filing mails -> Make the key>
   3. Run "setup" once and allow the Gmail + send-email permissions it asks for.
   ===================================================================== */
var SUPABASE = 'https://bakvbqtbhdumvlioenyw.supabase.co';
var ANON = 'sb_publishable_X4i44aDTHxOrFIEzEZMpIg_kEfLfIOI';   // public key (same as the website)
var FUNCTION_URL = SUPABASE + '/functions/v1/mail-intake';
var LOOK_BACK = 'newer_than:2d';                  // first run also catches the last 2 days
var MAX_BYTES = 20 * 1024 * 1024;                 // larger files are skipped (Gmail limit is 25 MB)
var NOTICE_QUERY = '(from:gst.gov.in OR from:gstn.org.in OR from:incometax.gov.in OR from:insight.gov.in OR from:tdscpc.gov.in OR from:mca.gov.in' +
                   ' OR subject:notice OR "show cause" OR "notice u/s" OR "DRC-01" OR "ASMT-10") -in:sent -in:drafts -in:trash -in:spam newer_than:3d';
var SITE = 'https://jlr-compliance.github.io/';

function setup() {
  ScriptApp.getProjectTriggers().forEach(function (t) { ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('everyMinute').timeBased().everyMinutes(1).create();
  ScriptApp.newTrigger('dailyBackup').timeBased().everyDays(1).atHour(1).inTimezone('Asia/Kolkata').create();
  everyMinute();
}

function everyMinute() {
  var lock = LockService.getScriptLock(); if (!lock.tryLock(5000)) return;
  try {
    var props = PropertiesService.getScriptProperties();
    if (props.getProperty('INTAKE_KEY')) { try { checkMail_(); } catch (e) { console.error('Client mail: ' + e); } }
    if (props.getProperty('NOTICE_KEY')) { try { noticeWatch_(); } catch (e) { console.error('Notice watch: ' + e); } }
    if (props.getProperty('NOTICE_KEY')) { try { chaseMail_(); } catch (e) { console.error('Data reminders: ' + e); } }
    if (props.getProperty('MAILJOB_KEY')) { try { mailJobs_(); } catch (e) { console.error('Tracker mails: ' + e); } }
    if (props.getProperty('MAILJOB_KEY')) { try { reviewReplies_(); } catch (e) { console.error('Senior replies: ' + e); } }
  } finally { lock.releaseLock(); }
}
function checkMail() { everyMinute(); }                  // old trigger name still works

/* ---------------- A. client mail (unchanged) ---------------- */
function checkMail_() {
  var props = PropertiesService.getScriptProperties(), key = props.getProperty('INTAKE_KEY');
  var seen = JSON.parse(props.getProperty('SEEN') || '[]');
  var done = label_('JLR/Imported'), skip = label_('JLR/Not a client');
  var threads = GmailApp.search('has:attachment -in:sent -in:drafts -in:trash -in:spam -label:"JLR/Not a client" ' + LOOK_BACK, 0, 30);
  threads.forEach(function (th) {
    th.getMessages().forEach(function (m) {
      var id = m.getId();
      if (seen.indexOf(id) >= 0 || m.isDraft()) return;
      var atts = m.getAttachments({ includeInlineImages: false, includeAttachments: true });
      var result = 'none', ok = true;
      atts.forEach(function (a) {
        if (!ok || a.getSize() > MAX_BYTES) return;
        var payload = { id: id, from: m.getFrom(), to: [m.getTo(), m.getCc()].join(','), subject: m.getSubject(), date: m.getDate().toISOString(),
          snippet: m.getPlainBody().slice(0, 400), file: { name: a.getName(), mime: a.getContentType(), data: Utilities.base64Encode(a.getBytes()) } };
        var r = UrlFetchApp.fetch(FUNCTION_URL, { method: 'post', contentType: 'application/json', payload: JSON.stringify(payload),
          headers: { 'x-intake-key': key }, muteHttpExceptions: true });
        if (r.getResponseCode() >= 300) { ok = false; console.error(r.getResponseCode() + ' ' + r.getContentText()); return; }
        var out = JSON.parse(r.getContentText() || '{}');
        if (out.result === 'stored' || out.result === 'duplicate') result = 'stored';
        else if (result === 'none') result = out.result;          // not_client / filtered / disabled
      });
      if (!ok || result === 'disabled') return;                    // try again next minute
      if (result === 'not_client') { th.addLabel(skip); return; }    // remove the label to try again (e.g. after saving the client's email)
      if (result === 'stored') th.addLabel(done);
      seen.push(id);
    });
  });
  props.setProperty('SEEN', JSON.stringify(seen.slice(-400)));
}

/* ---------------- B. notice watch ---------------- */
function rpc_(fn, body) {
  var r = UrlFetchApp.fetch(SUPABASE + '/rest/v1/rpc/' + fn, { method: 'post', contentType: 'application/json', payload: JSON.stringify(body),
    headers: { apikey: ANON, Authorization: 'Bearer ' + ANON }, muteHttpExceptions: true });
  if (r.getResponseCode() >= 300) throw new Error(fn + ' ' + r.getResponseCode() + ' ' + r.getContentText().slice(0, 300));
  var t = r.getContentText(); return t ? JSON.parse(t) : null;
}

function noticeWatch_() {
  var props = PropertiesService.getScriptProperties(), key = props.getProperty('NOTICE_KEY');
  var now = new Date(), hh = +Utilities.formatDate(now, 'Asia/Kolkata', 'H'), day = Utilities.formatDate(now, 'Asia/Kolkata', 'yyyy-MM-dd');
  var slot = hh >= 20 ? day + ' night' : hh >= 8 ? day + ' morning' : '';
  var digestDue = slot && props.getProperty('DIGEST_LAST') !== slot;
  var poll = rpc_('notice_poll', { p_key: key });
  if (!poll || !poll.enabled) return;
  if (!poll.run && !digestDue) return;                     // nothing asked; next scheduled check later

  var found = 0, err = null;
  try { found = scanNotices_(key); } catch (e) { err = String(e).slice(0, 300); }
  rpc_('notice_checked', { p_key: key, p_found: found, p_error: err });

  if (digestDue) { sendDigest_(key, slot.indexOf('night') > 0 ? 'Night' : 'Morning'); props.setProperty('DIGEST_LAST', slot); }
}

function scanNotices_(key) {
  var props = PropertiesService.getScriptProperties();
  var seen = JSON.parse(props.getProperty('SEEN_N') || '[]'), lbl = label_('JLR/Notice'), made = 0;
  GmailApp.search(NOTICE_QUERY, 0, 40).forEach(function (th) {
    th.getMessages().forEach(function (m) {
      var id = m.getId();
      if (seen.indexOf(id) >= 0 || m.isDraft()) return;
      var out = rpc_('notice_intake', { p_key: key, p_mail: { id: id, from: m.getFrom(), subject: m.getSubject(), date: m.getDate().toISOString(),
                                                                body: m.getPlainBody().slice(0, 20000) } });
      if (!out || out.result === 'disabled') return;
      seen.push(id);
      if (out.result === 'created' || out.result === 'unmatched') {
        th.addLabel(lbl); made++;
        if (out.alert_email && out.emails && out.emails.length) alertMail_(out, m);
      }
    });
  });
  props.setProperty('SEEN_N', JSON.stringify(seen.slice(-600)));
  return made;
}

function fmtDate_(d) { return d ? Utilities.formatDate(new Date(d + 'T00:00:00+05:30'), 'Asia/Kolkata', 'dd MMM yyyy') : 'not stated'; }

function alertMail_(out, m) {
  var dept = out.dept === 'ROC/MCA' ? 'MCA' : out.dept, who = out.client || 'a sender not yet matched to a client';
  var subj = (out.result === 'created' ? 'New ' + dept + ' notice: ' : 'Notice email needs a client: ') + who + ' – ' + out.notice_type;
  var body = (out.result === 'created'
      ? 'A new ' + dept + ' notice was added to the tracker.\n\nClient: ' + who + '\nNotice: ' + out.notice_type + (out.ref_no ? '\nReference: ' + out.ref_no : '') +
        '\nReply due: ' + fmtDate_(out.reply_due) + '\n'
      : 'A notice email arrived but the tracker could not tell which client it is for.\nOpen Notices -> "From email – needs a client" to choose the client.\n') +
    '\nEmail: ' + m.getSubject() + '\nFrom: ' + m.getFrom() + '\n\nOpen the tracker: ' + SITE + '#/notices\n\n— JLR Compliance Tracker';
  MailApp.sendEmail({ to: out.emails.join(','), subject: subj, body: body, name: 'JLR Compliance Tracker' });
}

function sendDigest_(key, when) {
  var d = rpc_('notice_digest', { p_key: key });
  if (!d || !d.emails || !d.emails.length) return;
  if (!d.new.length && !d.due.length && !d.unmatched) return;          // nothing to say
  var L = [when + ' notice summary – ' + Utilities.formatDate(new Date(), 'Asia/Kolkata', 'dd MMM yyyy'), ''];
  if (d.new.length) { L.push('New notices (last 12 hours): ' + d.new.length);
    d.new.forEach(function (n) { L.push('  • ' + n.client + ' – ' + n.dept + ' ' + n.type + (n.ref ? ' (' + n.ref + ')' : '') + ', reply by ' + fmtDate_(n.due)); }); L.push(''); }
  if (d.due.length) { L.push('Replies due in the next 7 days or late: ' + d.due.length);
    d.due.forEach(function (n) { L.push('  • ' + (n.late ? 'LATE ' : '') + fmtDate_(n.due) + ' – ' + n.client + ' – ' + n.dept + ' ' + n.type + (n.staff ? ' – ' + n.staff : '')); }); L.push(''); }
  if (d.unmatched) L.push(d.unmatched + ' notice email(s) still need a client (Notices -> From email).', '');
  L.push('Open the tracker: ' + SITE + '#/notices', '', '— JLR Compliance Tracker');
  MailApp.sendEmail({ to: d.emails.join(','), subject: when + ' notice summary: ' + d.new.length + ' new, ' + d.due.length + ' due soon', body: L.join('\n'), name: 'JLR Compliance Tracker' });
}

/* ---------------- C. data reminder emails ---------------- */
function chaseMail_() {
  var key = PropertiesService.getScriptProperties().getProperty('NOTICE_KEY');
  var list = rpc_('chase_outbox', { p_key: key }) || [];
  list.forEach(function (m) {
    var ok = true, err = null;
    try {
      if (MailApp.getRemainingDailyQuota() < 1) throw new Error('Gmail daily sending limit reached — will send tomorrow');
      MailApp.sendEmail({ to: m.to, subject: m.subject, body: m.body, name: 'JLR Compliance' });
    } catch (e) { ok = false; err = String(e).slice(0, 300); if (/limit/i.test(err)) return; }
    rpc_('chase_sent', { p_key: key, p_id: m.id, p_ok: ok, p_error: err });
  });
}

function label_(name) { return GmailApp.getUserLabelByName(name) || GmailApp.createLabel(name); }

/* ---------------- D. senior verification & filing mails (v4) ---------------- */
function mailJobs_() {
  var key = PropertiesService.getScriptProperties().getProperty('MAILJOB_KEY');
  var list = rpc_('mail_jobs_due', { p_key: key }) || [];
  list.forEach(function (m) {
    var ok = true, err = null;
    try {
      if (MailApp.getRemainingDailyQuota() < 1) throw new Error('Gmail daily sending limit reached — will send tomorrow');
      var files = (m.files || []).map(function (f) { return Utilities.newBlob(Utilities.base64Decode(f.b64), f.mime || 'application/octet-stream', f.name || 'file'); });
      var opt = { name: 'JLR Compliance', attachments: files };
      if (m.html) opt.htmlBody = m.html;
      if (m.cc) opt.cc = m.cc;
      GmailApp.sendEmail(m.to, m.subject, m.body, opt);
    } catch (e) { ok = false; err = String(e).slice(0, 300); if (/limit/i.test(err)) return; }
    rpc_('mail_job_done', { p_key: key, p_id: m.id, p_ok: ok, p_error: err });
  });
}

// replies to "[JLR-REVIEW:TAG]" emails: the tracker checks that they come from the senior
function reviewReplies_() {
  var props = PropertiesService.getScriptProperties(), key = props.getProperty('MAILJOB_KEY');
  var done = JSON.parse(props.getProperty('REVIEW_SEEN') || '[]');
  GmailApp.search('subject:"JLR-REVIEW" -in:sent -in:drafts -in:trash -in:spam newer_than:12d', 0, 30).forEach(function (th) {
    th.getMessages().forEach(function (m) {
      var id = m.getId(); if (done.indexOf(id) >= 0) return;
      var tag = (m.getSubject().match(/\[JLR-REVIEW:([A-Z0-9x]+)\]/i) || [])[1];
      var from = m.getFrom(), me = Session.getEffectiveUser().getEmail().toLowerCase();
      if (!tag || from.toLowerCase().indexOf(me) >= 0) { done.push(id); return; }   // our own sent copy
      var text = replyText_(m.getPlainBody());
      try { var r = rpc_('review_reply', { p_key: key, p_tag: tag, p_from: from, p_text: text }); console.log('Review ' + tag + ': ' + r); done.push(id); }
      catch (e) { console.error('Review reply ' + tag + ': ' + e); }
    });
  });
  props.setProperty('REVIEW_SEEN', JSON.stringify(done.slice(-300)));
}
// only what the senior typed: stop at the quoted earlier mail
function replyText_(t) {
  var lines = String(t || '').replace(/\r/g, '').split('\n'), out = [];
  for (var i = 0; i < lines.length; i++) {
    var l = lines[i];
    if (/^\s*>/.test(l) || /^On .+wrote:\s*$/i.test(l) || /^-{2,}\s*Original Message/i.test(l) || /^From:\s/i.test(l) || /^Sent from my /i.test(l)) break;
    out.push(l);
  }
  return out.join('\n').trim().slice(0, 2000);
}

/* ---------------- E. daily backup to OneDrive (v4.1) ---------------- */
var BACKUP_URL = SUPABASE + '/functions/v1/backup-export';
var OD_FOLDER = 'JLR Tracker Backups';
var MS_AUTH = 'https://login.microsoftonline.com/common/oauth2/v2.0/';
var MS_SCOPE = 'Files.ReadWrite offline_access User.Read';

function connectOneDrive() {                       // step 1: run, then follow the message in the log
  var id = PropertiesService.getScriptProperties().getProperty('MS_CLIENT_ID');
  if (!id) throw new Error('Add the script property MS_CLIENT_ID first (Application (client) ID of your Microsoft app).');
  var r = JSON.parse(UrlFetchApp.fetch(MS_AUTH + 'devicecode', { method: 'post', payload: { client_id: id, scope: MS_SCOPE }, muteHttpExceptions: true }).getContentText());
  if (!r.device_code) throw new Error('Microsoft said: ' + (r.error_description || JSON.stringify(r)));
  PropertiesService.getScriptProperties().setProperty('MS_DEVICE', r.device_code);
  console.log('Open ' + r.verification_uri + ' and enter the code  ' + r.user_code + '  — sign in with the Microsoft account that owns the OneDrive, then run finishOneDrive.');
}
function finishOneDrive() {                        // step 2: after signing in
  var props = PropertiesService.getScriptProperties();
  var r = JSON.parse(UrlFetchApp.fetch(MS_AUTH + 'token', { method: 'post', muteHttpExceptions: true, payload: {
    grant_type: 'urn:ietf:params:oauth:grant-type:device_code', client_id: props.getProperty('MS_CLIENT_ID'), device_code: props.getProperty('MS_DEVICE') } }).getContentText());
  if (!r.refresh_token) throw new Error('Not connected yet: ' + (r.error_description || r.error || JSON.stringify(r)));
  props.setProperty('MS_REFRESH', r.refresh_token); props.deleteProperty('MS_DEVICE');
  CacheService.getScriptCache().put('MS_ACCESS', r.access_token, 3000);
  var me = JSON.parse(UrlFetchApp.fetch('https://graph.microsoft.com/v1.0/me', { headers: { Authorization: 'Bearer ' + r.access_token }, muteHttpExceptions: true }).getContentText());
  console.log('OneDrive connected: ' + (me.userPrincipalName || me.displayName || 'ok') + '. Now run dailyBackup once to test.');
}
function msToken_() {
  var c = CacheService.getScriptCache().get('MS_ACCESS'); if (c) return c;
  var props = PropertiesService.getScriptProperties();
  var r = JSON.parse(UrlFetchApp.fetch(MS_AUTH + 'token', { method: 'post', muteHttpExceptions: true, payload: {
    grant_type: 'refresh_token', client_id: props.getProperty('MS_CLIENT_ID'), refresh_token: props.getProperty('MS_REFRESH'), scope: MS_SCOPE } }).getContentText());
  if (!r.access_token) throw new Error('OneDrive sign-in expired — run connectOneDrive again (' + (r.error_description || r.error) + ')');
  if (r.refresh_token) props.setProperty('MS_REFRESH', r.refresh_token);
  CacheService.getScriptCache().put('MS_ACCESS', r.access_token, 3000);
  return r.access_token;
}
function odPath_(p) { return p.split('/').map(function (x) { return encodeURIComponent(x.replace(/[:*?"<>|#%]/g, '_')); }).join('/'); }
function odPut_(path, blob) {
  var tok = msToken_(), bytes = blob.getBytes(), url = 'https://graph.microsoft.com/v1.0/me/drive/root:/' + odPath_(path);
  if (bytes.length < 4 * 1024 * 1024) {
    var r = UrlFetchApp.fetch(url + ':/content', { method: 'put', contentType: 'application/octet-stream', payload: bytes, headers: { Authorization: 'Bearer ' + tok }, muteHttpExceptions: true });
    if (r.getResponseCode() >= 300) throw new Error('OneDrive ' + r.getResponseCode() + ' ' + r.getContentText().slice(0, 200));
    return;
  }
  var s = JSON.parse(UrlFetchApp.fetch(url + ':/createUploadSession', { method: 'post', contentType: 'application/json', payload: JSON.stringify({ item: { '@microsoft.graph.conflictBehavior': 'replace' } }),
    headers: { Authorization: 'Bearer ' + tok }, muteHttpExceptions: true }).getContentText());
  if (!s.uploadUrl) throw new Error('OneDrive upload session failed');
  var CH = 327680 * 12;
  for (var i = 0; i < bytes.length; i += CH) {
    var part = bytes.slice(i, Math.min(i + CH, bytes.length));
    var r2 = UrlFetchApp.fetch(s.uploadUrl, { method: 'put', payload: part, muteHttpExceptions: true,
      headers: { 'Content-Range': 'bytes ' + i + '-' + (i + part.length - 1) + '/' + bytes.length } });
    if (r2.getResponseCode() >= 300) throw new Error('OneDrive chunk ' + r2.getResponseCode());
  }
}
function backupCall_(body) {
  var r = UrlFetchApp.fetch(BACKUP_URL, { method: 'post', contentType: 'application/json', payload: JSON.stringify(body), muteHttpExceptions: true,
    headers: { apikey: ANON, Authorization: 'Bearer ' + ANON, 'x-backup-key': PropertiesService.getScriptProperties().getProperty('BACKUP_KEY') } });
  if (r.getResponseCode() >= 300) throw new Error('backup ' + r.getResponseCode() + ' ' + r.getContentText().slice(0, 200));
  return JSON.parse(r.getContentText());
}
function csv_(rows) {
  if (!rows.length) return '';
  var cols = []; rows.forEach(function (r) { Object.keys(r).forEach(function (k) { if (cols.indexOf(k) < 0) cols.push(k); }); });
  var cell = function (v) { if (v === null || v === undefined) return ''; if (typeof v === 'object') v = JSON.stringify(v); v = String(v); return /[",\n\r]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; };
  return '﻿' + [cols.join(',')].concat(rows.map(function (r) { return cols.map(function (c) { return cell(r[c]); }).join(','); })).join('\r\n');
}
function dailyBackup() {
  var props = PropertiesService.getScriptProperties();
  if (!props.getProperty('BACKUP_KEY') || !props.getProperty('MS_REFRESH')) return;
  var day = Utilities.formatDate(new Date(), 'Asia/Kolkata', 'yyyy-MM-dd'), note = [], ok = true, upto = props.getProperty('BACKUP_FILES_UPTO') || null;
  try {
    var d = backupCall_({ action: 'data' }), blobs = [], total = 0;
    Object.keys(d.tables).forEach(function (t) { var rows = d.tables[t] || []; total += rows.length; if (rows.length) blobs.push(Utilities.newBlob(csv_(rows), 'text/csv', t + '.csv')); });
    blobs.push(Utilities.newBlob(JSON.stringify(d), 'application/json', 'all-data.json'));
    odPut_(OD_FOLDER + '/JLR-backup-' + day + '.zip', Utilities.zip(blobs, 'JLR-backup-' + day + '.zip'));
    note.push(total + ' records');
  } catch (e) { ok = false; note.push('Data: ' + String(e).slice(0, 150)); }
  try {
    var n = 0, start = Date.now();
    while (Date.now() - start < 240000) {
      var f = backupCall_({ action: 'files', since: upto }).files || [];
      if (!f.length) break;
      f.forEach(function (x) {
        if (Date.now() - start > 240000) return;
        if (x.url) odPut_(OD_FOLDER + '/files/' + x.bucket + '/' + x.name, UrlFetchApp.fetch(x.url).getBlob());
        upto = x.created_at; n++;
      });
      props.setProperty('BACKUP_FILES_UPTO', upto);
    }
    note.push(n + ' new files');
  } catch (e) { ok = false; note.push('Files: ' + String(e).slice(0, 150)); }
  try { backupCall_({ action: 'report', ok: ok, note: note.join(' · '), files_upto: upto }); } catch (e) { console.error(e); }
  if (!ok) throw new Error(note.join(' · '));
  console.log('Backup done: ' + note.join(' · '));
}

