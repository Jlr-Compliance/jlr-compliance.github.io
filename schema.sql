-- JLR Compliance tracker: full structure (exported from demo 12 Nov 2026, no client data)

-- ==== head ====
set check_function_bodies = off;
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;
create sequence if not exists public.audit_log_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.backups_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.due_dates_id_seq as integer increment 1 minvalue 1 maxvalue 2147483647 start 1 cache 1;
create sequence if not exists public.fee_rates_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.gst_checks_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.login_access_log_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.mail_jobs_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create sequence if not exists public.wa_log_id_seq as bigint increment 1 minvalue 1 maxvalue 9223372036854775807 start 1 cache 1;
create table if not exists public.ai_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  model text default 'claude-haiku-5-5'::text not null,
  max_per_month integer default 2000 not null,
  price_in numeric(10,4) default 0.10 not null,
  price_out numeric(10,4) default 0.50 not null,
  usd_inr numeric(10,2) default 88 not null,
  key_secret uuid,
  key_set_at timestamp with time zone,
  key_hint text
);
create table if not exists public.ai_usage (
  id uuid default gen_random_uuid() not null,
  at timestamp with time zone default now() not null,
  user_id uuid,
  client_id uuid,
  file_name text,
  model text,
  in_tokens integer default 0 not null,
  out_tokens integer default 0 not null,
  cost_inr numeric(10,4) default 0 not null,
  ok boolean,
  error text
);
create table if not exists public.audit_log (
  id bigint default nextval('audit_log_id_seq'::regclass) not null,
  at timestamp with time zone default now() not null,
  user_id uuid,
  user_name text,
  area text not null,
  row_id text,
  client_id uuid,
  action text not null,
  summary text,
  changes jsonb
);
create table if not exists public.auto_work_done (
  client_id uuid not null,
  return_name text not null,
  period text not null,
  made_at timestamp with time zone default now() not null
);
create table if not exists public.auto_work_settings (
  id integer default 1 not null,
  gst_enabled boolean default true not null,
  last_run_at timestamp with time zone,
  last_made integer,
  last_note text
);
create table if not exists public.backups (
  id bigint default nextval('backups_id_seq'::regclass) not null,
  taken_at timestamp with time zone default now() not null,
  kind text default 'auto'::text not null,
  rows integer default 0 not null,
  size_kb integer default 0 not null,
  data jsonb not null
);
create table if not exists public.bank_rules (
  id uuid default gen_random_uuid() not null,
  client_id uuid,
  match text not null,
  dir text default 'any'::text not null,
  ledger text not null,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null
);
create table if not exists public.bank_statements (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  bank text,
  account text,
  ifsc text,
  holder text,
  period_from date,
  period_to date,
  opening numeric(16,2) default 0 not null,
  closing numeric(16,2) default 0 not null,
  total_dr numeric(16,2) default 0 not null,
  total_cr numeric(16,2) default 0 not null,
  n_rows integer default 0 not null,
  bad integer default 0 not null,
  file_name text,
  method text,
  status text default 'Draft'::text not null,
  rows jsonb default '[]'::jsonb not null,
  tally jsonb default '{}'::jsonb not null,
  notes jsonb default '[]'::jsonb not null,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.chase_log (
  id uuid default gen_random_uuid() not null,
  client_id uuid,
  kind text default 'client'::text not null,
  channel text not null,
  round_no integer,
  to_addr text,
  subject text,
  body text,
  items text,
  status text not null,
  error text,
  created_at timestamp with time zone default now() not null,
  sent_at timestamp with time zone
);
create table if not exists public.chase_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  start_days integer default 7 not null,
  every_days integer default 3 not null,
  max_month integer default 4 not null,
  use_wa boolean default true not null,
  use_email boolean default true not null,
  escalate_after integer default 2 not null,
  last_run_at timestamp with time zone,
  last_note text
);
create table if not exists public.checklist_templates (
  id integer not null,
  work_type text not null,
  name text not null,
  matches text[] default '{}'::text[] not null,
  steps jsonb default '[]'::jsonb not null,
  updated_at timestamp with time zone default now() not null,
  docs text[] default '{}'::text[] not null
);
create table if not exists public.client_logins (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  portal text not null,
  login_id text not null,
  url text,
  otp_contact text,
  notes text,
  secret_id uuid,
  pw_changed_on date,
  updated_at timestamp with time zone default now() not null,
  updated_by uuid,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.client_reports (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  period date not null,
  data jsonb default '{}'::jsonb not null,
  html text,
  made_at timestamp with time zone default now() not null,
  published boolean default false not null,
  published_at timestamp with time zone,
  published_by uuid,
  sent_on date,
  sent_via text
);
create table if not exists public.client_rules (
  id uuid default gen_random_uuid() not null,
  client_id uuid,
  applies text not null,
  field text not null,
  op text not null,
  val text,
  action text not null,
  note text,
  active boolean default true not null,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null
);
create table if not exists public.client_uploads (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  task_id uuid,
  doc_id uuid,
  path text not null,
  file_name text not null,
  size_bytes bigint,
  uploaded_by uuid,
  uploaded_at timestamp with time zone default now() not null,
  source text default 'Portal'::text not null
);
create table if not exists public.client_users (
  user_id uuid not null,
  client_id uuid not null,
  name text,
  email text not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid,
  last_seen timestamp with time zone
);
create table if not exists public.clients (
  id uuid default gen_random_uuid() not null,
  name text not null,
  gstin text,
  pan text,
  tan text,
  cin text,
  contact_person text,
  phone text,
  email text,
  gst_scheme text default 'Monthly'::text not null,
  services text[] default '{}'::text[] not null,
  default_staff uuid,
  notes text,
  status_token uuid default gen_random_uuid() not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  address text,
  zoho_contact_id text,
  chase_off boolean default false not null,
  client_code text,
  tds_pay_work boolean default false not null,
  tds_return boolean default false not null,
  is_demo boolean default false not null,
  itc_method text default 'books_2b'::text not null
);
create table if not exists public.data_request_log (
  client_id uuid not null,
  kind text not null,
  period text not null,
  to_addr text,
  sent_at timestamp with time zone default now() not null,
  chase_id uuid
);
create table if not exists public.data_request_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  gst_reply_day integer default 5 not null,
  tdsp_reply_day integer default 4 not null,
  tdsr_reply_day integer default 10 not null,
  last_run_at timestamp with time zone,
  last_note text
);
create table if not exists public.data_request_templates (
  kind text not null,
  subject text not null,
  body text not null,
  updated_at timestamp with time zone,
  updated_by uuid
);
create table if not exists public.demo_rows (
  tbl text not null,
  row_id text not null
);
create table if not exists public.due_dates (
  id integer default nextval('due_dates_id_seq'::regclass) not null,
  work_type text not null,
  return_name text not null,
  description text,
  applies_to text,
  due_day integer not null,
  months integer[] not null,
  period_rule text default 'prev_month'::text not null,
  sort integer default 0 not null
);
create table if not exists public.fee_rates (
  id bigint default nextval('fee_rates_id_seq'::regclass) not null,
  client_id uuid,
  return_name text not null,
  amount numeric(12,2) not null
);
create table if not exists public.filing_acks (
  id uuid default gen_random_uuid() not null,
  task_id uuid,
  client_id uuid,
  kind text,
  return_name text,
  period text,
  arn text,
  filed_on date,
  file_name text,
  file_path text,
  uploaded_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null
);
create table if not exists public.followups (
  id uuid default gen_random_uuid() not null,
  kind text default 'task'::text not null,
  task_id uuid,
  client_id uuid not null,
  on_date date default CURRENT_DATE not null,
  mode text default 'Phone call'::text not null,
  note text,
  promised_on date,
  next_on date,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null
);
create table if not exists public.gst_checks (
  id bigint default nextval('gst_checks_id_seq'::regclass) not null,
  client_id uuid,
  fy text not null,
  request_id bigint,
  requested_at timestamp with time zone default now() not null,
  processed_at timestamp with time zone,
  status_code integer,
  updated_count integer,
  result text
);
create table if not exists public.gst_months (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  period date not null,
  sales jsonb,
  purchases jsonb,
  gstr2b jsonb,
  gstr3b jsonb,
  gstr1 jsonb,
  summary jsonb,
  status text default 'Draft'::text not null,
  verified_by uuid,
  verified_at timestamp with time zone,
  notes text,
  updated_at timestamp with time zone default now() not null,
  updated_by uuid,
  g1 jsonb,
  reco jsonb
);
create table if not exists public.gst_reviews (
  client_id uuid not null,
  period date not null,
  state text default 'draft'::text not null,
  sent_at timestamp with time zone,
  sent_by uuid,
  sends integer default 0 not null,
  token_hash text,
  token_exp timestamp with time zone,
  tag text,
  summary jsonb,
  decided_at timestamp with time zone,
  decided_via text,
  remarks jsonb default '[]'::jsonb not null,
  client_sent jsonb default '[]'::jsonb not null,
  updated_at timestamp with time zone default now() not null,
  kind text default 'gstr3b'::text not null,
  draft jsonb
);
create table if not exists public.gst_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  base_url text default 'https://api.sandbox.co.in'::text not null,
  start_day integer default 10 not null,
  end_day integer default 25 not null,
  token text,
  token_expires timestamp with time zone,
  auth_request_id bigint,
  auth_requested timestamp with time zone,
  last_error text
);
create table if not exists public.gst_tp_sessions (
  client_id uuid not null,
  gstin text,
  username text,
  token text,
  expires_at timestamp with time zone,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.invoices (
  id uuid default gen_random_uuid() not null,
  inv_no text not null,
  client_id uuid not null,
  inv_date date default CURRENT_DATE not null,
  items jsonb default '[]'::jsonb not null,
  subtotal numeric(12,2) default 0 not null,
  gst_rate numeric default 0 not null,
  gst_amount numeric(12,2) default 0 not null,
  total numeric(12,2) default 0 not null,
  paid numeric(12,2) default 0 not null,
  notes text,
  created_at timestamp with time zone default now() not null,
  created_by uuid,
  zoho_invoice_id text,
  zoho_status text,
  zoho_error text,
  source text default 'tracker'::text not null
);
create table if not exists public.law_updates (
  id uuid default gen_random_uuid() not null,
  dept text default 'GST'::text not null,
  title text not null,
  summary text,
  action_needed text,
  source_url text,
  effective_on date,
  status text default 'draft'::text not null,
  created_at timestamp with time zone default now() not null,
  created_by uuid,
  published_at timestamp with time zone
);
create table if not exists public.linked_rules (
  id integer not null,
  trigger_event text not null,
  matches text[] default '{}'::text[] not null,
  action text not null,
  form text,
  due_rule text,
  applies_to text,
  law text,
  task_return text not null,
  work_type text not null,
  due_days integer
);
create table if not exists public.login_access_log (
  id bigint default nextval('login_access_log_id_seq'::regclass) not null,
  login_id uuid,
  client_id uuid,
  portal text,
  user_id uuid,
  action text not null,
  at timestamp with time zone default now() not null
);
create table if not exists public.mail_inbox (
  id uuid default gen_random_uuid() not null,
  msg_id text not null,
  received_at timestamp with time zone default now() not null,
  from_email text not null,
  from_name text,
  subject text,
  snippet text,
  client_id uuid,
  period date,
  period_guess boolean default false not null,
  task_ids uuid[] default '{}'::uuid[] not null,
  files jsonb default '[]'::jsonb not null,
  status text default 'New'::text not null,
  note text,
  handled_by uuid,
  handled_at timestamp with time zone
);
create table if not exists public.mail_jobs (
  id bigint default nextval('mail_jobs_id_seq'::regclass) not null,
  kind text not null,
  to_addr text not null,
  cc text,
  subject text not null,
  body text not null,
  html text,
  files jsonb default '[]'::jsonb not null,
  client_id uuid,
  period date,
  status text default 'new'::text not null,
  tries integer default 0 not null,
  error text,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null,
  sent_at timestamp with time zone,
  kind2 text
);
create table if not exists public.mail_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  key_hash text,
  key_set_at timestamp with time zone,
  subject_filter text,
  mailbox text,
  last_mail_at timestamp with time zone,
  last_error text
);
create table if not exists public.mca_companies (
  client_id uuid not null,
  entity_type text,
  cin text,
  incorporated_on date,
  first_fy_end date,
  roc text,
  small_company boolean default false not null,
  listed boolean default false not null,
  auth_capital numeric(16,2),
  paid_capital numeric(16,2),
  reg_office text,
  company_email text,
  auditor jsonb default '{}'::jsonb not null,
  agms jsonb default '[]'::jsonb not null,
  applies jsonb default '{"cfs": false, "dpt3": true, "xbrl": false, "msme1": false}'::jsonb not null,
  remarks text,
  updated_by uuid default auth.uid(),
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.mca_directors (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  name text not null,
  din text,
  designation text,
  pan text,
  email text,
  phone text,
  appointed_on date,
  ceased_on date,
  kyc_on date,
  kyc_next date,
  remarks text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.notice_mails (
  id uuid default gen_random_uuid() not null,
  mail_id text not null,
  received_at timestamp with time zone,
  sender text,
  subject text,
  excerpt text,
  dept text,
  notice_type text,
  ref_no text,
  period text,
  reply_due date,
  amount numeric(16,2),
  client_id uuid,
  notice_id uuid,
  result text not null,
  note text,
  wa_sent integer default 0 not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.notice_watch (
  id integer default 1 not null,
  enabled boolean default true not null,
  key_hash text,
  key_set_at timestamp with time zone,
  check_requested_at timestamp with time zone,
  last_check_at timestamp with time zone,
  last_found integer,
  last_error text,
  alert_email boolean default true not null,
  alert_wa boolean default true not null,
  wa_template text default 'notice_alert'::text not null,
  every_minutes integer default 15 not null
);
create table if not exists public.notices (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  dept text default 'GST'::text not null,
  notice_type text not null,
  ref_no text,
  period text,
  notice_date date,
  reply_due date,
  hearing_date date,
  amount numeric(14,2),
  assigned_to uuid,
  status text default 'Open'::text not null,
  replied_on date,
  ack_no text,
  remarks text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  updated_by uuid,
  source text,
  mail_id text,
  auto boolean default false not null,
  draft_reply text,
  draft_at timestamp with time zone
);
create table if not exists public.onboarding (
  client_id uuid not null,
  items jsonb default '[]'::jsonb not null,
  fees jsonb default '[]'::jsonb not null,
  letter jsonb default '{}'::jsonb not null,
  status text default 'In progress'::text not null,
  started_on date default CURRENT_DATE not null,
  completed_on date,
  created_by uuid default auth.uid(),
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.payment_claims (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  invoice_id uuid,
  amount numeric(14,2) not null,
  paid_on date not null,
  mode text default 'UPI'::text not null,
  ref text,
  note text,
  status text default 'New'::text not null,
  payment_id uuid,
  reply text,
  created_at timestamp with time zone default now() not null,
  handled_by uuid,
  handled_at timestamp with time zone
);
create table if not exists public.payments (
  id uuid default gen_random_uuid() not null,
  invoice_id uuid not null,
  paid_on date default CURRENT_DATE not null,
  amount numeric(12,2) not null,
  mode text,
  ref text,
  created_at timestamp with time zone default now() not null,
  zoho_payment_id text
);
create table if not exists public.profiles (
  id uuid not null,
  full_name text,
  email text,
  phone text,
  role text default 'staff'::text not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.renewals (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  kind text not null,
  holder text,
  ref_no text,
  issued_on date,
  expires_on date,
  repeat_months integer default 12 not null,
  assigned_to uuid,
  status text default 'Active'::text not null,
  reminders jsonb default '{}'::jsonb not null,
  history jsonb default '[]'::jsonb not null,
  remarks text,
  created_by uuid default auth.uid(),
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.settings (
  id integer default 1 not null,
  firm_name text default 'Our Office'::text not null,
  board_token uuid default gen_random_uuid() not null,
  board_enabled boolean default false not null,
  firm_address text,
  firm_gstin text,
  firm_pan text,
  firm_phone text,
  firm_email text,
  bank_details text,
  invoice_prefix text default 'JLR'::text not null,
  next_invoice_no integer default 1 not null,
  gst_rate numeric default 18 not null,
  sac_code text,
  onboard_items jsonb,
  gst_bill_day integer default 25 not null,
  upi_id text,
  notices_off boolean default false not null,
  senior_id uuid,
  auto_send_filed boolean default false not null,
  mailjob_key_hash text,
  mailjob_seen_at timestamp with time zone,
  mail_greeting text default 'Respected Sir,'::text not null,
  mail_signature text
);
create table if not exists public.task_checks (
  id uuid default gen_random_uuid() not null,
  task_id uuid not null,
  seq integer not null,
  check_name text not null,
  who text,
  status text default 'Pending'::text not null,
  completed_on date,
  completed_by uuid,
  remarks text
);
create table if not exists public.task_docs (
  id uuid default gen_random_uuid() not null,
  task_id uuid not null,
  seq integer default 0 not null,
  name text not null,
  received boolean default false not null,
  received_on date
);
create table if not exists public.tasks (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  work_type text not null,
  return_name text not null,
  period text not null,
  due_date date,
  status text default 'Pending data'::text not null,
  assigned_to uuid,
  filed_on date,
  arn text,
  remarks text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  updated_by uuid,
  data_received_on date,
  data_source text,
  checks_total integer default 0 not null,
  checks_done integer default 0 not null,
  parent_task uuid,
  fee numeric(12,2),
  invoice_id uuid,
  fu_count integer default 0 not null,
  fu_last date,
  fu_next date
);
create table if not exists public.tax_intimations (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  kind text not null,
  period text not null,
  due_date date,
  amounts jsonb default '{}'::jsonb not null,
  total numeric(14,2) default 0 not null,
  sent_on date,
  sent_via text,
  sent_by uuid,
  sent_count integer default 0 not null,
  paid_on date,
  paid_amount numeric(14,2),
  challan text,
  remarks text,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.tds_challans (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  month date not null,
  sec text not null,
  tds numeric(14,2) default 0 not null,
  intr numeric(14,2) default 0 not null,
  fee numeric(14,2) default 0 not null,
  paid_on date,
  bsr text,
  chno text,
  cin text,
  remarks text,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.tds_entries (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  fy text not null,
  month date not null,
  line integer default 0 not null,
  paid_on date,
  name text,
  pan text,
  dtype text,
  sec text,
  amount numeric(14,2) default 0 not null,
  reason text,
  rate numeric(7,3),
  tds_man numeric(14,2),
  tds numeric(14,2) default 0 not null,
  ded_on date,
  cert text,
  bill text,
  remarks text,
  created_by uuid default auth.uid(),
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.tds_returns (
  id uuid default gen_random_uuid() not null,
  client_id uuid not null,
  fy text not null,
  q integer not null,
  form text not null,
  status text default 'Not started'::text not null,
  prepared_on date,
  filed_on date,
  token text,
  late_fee numeric(14,2),
  remarks text,
  cert_dl_on date,
  certs jsonb default '{}'::jsonb not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.wa_log (
  id bigint default nextval('wa_log_id_seq'::regclass) not null,
  sent_at timestamp with time zone default now() not null,
  kind text not null,
  profile_id uuid,
  phone text,
  summary text,
  request_id bigint
);
create table if not exists public.wa_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  phone_number_id text,
  api_version text default 'v23.0'::text not null,
  app_url text default 'https://jlr-compliance.github.io/jlr-tracker'::text not null,
  daily_template text default 'staff_daily_reminder'::text not null,
  monthly_template text default 'monthly_due_dates'::text not null,
  template_lang text default 'en'::text not null,
  client_enabled boolean default false not null,
  client_template text default 'client_data_reminder'::text not null,
  client_days integer[] default '{5,2}'::integer[] not null
);
create table if not exists public.work_requests (
  id uuid default gen_random_uuid() not null,
  title text not null,
  details text,
  client_id uuid,
  assigned_to uuid not null,
  requested_by uuid default auth.uid(),
  due_date date,
  priority text default 'Normal'::text not null,
  status text default 'New'::text not null,
  reply text,
  started_at timestamp with time zone,
  done_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.zoho_items (
  name text not null,
  item_id text not null
);
create table if not exists public.zoho_settings (
  id integer default 1 not null,
  enabled boolean default false not null,
  auto_push boolean default true not null,
  client_id text,
  org_id text,
  org_name text,
  orgs jsonb,
  sync_from date,
  last_sync timestamp with time zone,
  last_result text,
  last_error text,
  function_url text default 'https://bakvbqtbhdumvlioenyw.supabase.co/functions/v1/zoho'::text not null,
  push_as_draft boolean default false not null
);
create table if not exists public.zoho_state (
  id integer default 1 not null,
  access_token text,
  expires_at timestamp with time zone
);
alter sequence public.due_dates_id_seq owned by public.due_dates.id;
alter sequence public.wa_log_id_seq owned by public.wa_log.id;
alter sequence public.fee_rates_id_seq owned by public.fee_rates.id;
alter sequence public.gst_checks_id_seq owned by public.gst_checks.id;
alter sequence public.backups_id_seq owned by public.backups.id;
alter sequence public.login_access_log_id_seq owned by public.login_access_log.id;
alter sequence public.audit_log_id_seq owned by public.audit_log.id;
alter sequence public.mail_jobs_id_seq owned by public.mail_jobs.id;

-- ==== cons ====
alter table public.ai_settings add constraint ai_settings_pkey PRIMARY KEY (id);
alter table public.ai_settings add constraint ai_settings_id_check CHECK ((id = 1));
alter table public.ai_usage add constraint ai_usage_pkey PRIMARY KEY (id);
alter table public.audit_log add constraint audit_log_pkey PRIMARY KEY (id);
alter table public.auto_work_done add constraint auto_work_done_pkey PRIMARY KEY (client_id, return_name, period);
alter table public.auto_work_settings add constraint auto_work_settings_pkey PRIMARY KEY (id);
alter table public.auto_work_settings add constraint auto_work_settings_id_check CHECK ((id = 1));
alter table public.backups add constraint backups_pkey PRIMARY KEY (id);
alter table public.bank_rules add constraint bank_rules_pkey PRIMARY KEY (id);
alter table public.bank_rules add constraint bank_rules_dir_check CHECK ((dir = ANY (ARRAY['any'::text, 'dr'::text, 'cr'::text])));
alter table public.bank_statements add constraint bank_statements_pkey PRIMARY KEY (id);
alter table public.bank_statements add constraint bank_statements_status_check CHECK ((status = ANY (ARRAY['Draft'::text, 'Checked'::text, 'Exported'::text])));
alter table public.chase_log add constraint chase_log_pkey PRIMARY KEY (id);
alter table public.chase_settings add constraint chase_settings_pkey PRIMARY KEY (id);
alter table public.chase_settings add constraint chase_settings_id_check CHECK ((id = 1));
alter table public.checklist_templates add constraint checklist_templates_pkey PRIMARY KEY (id);
alter table public.client_logins add constraint client_logins_pkey PRIMARY KEY (id);
alter table public.client_logins add constraint client_logins_client_id_portal_login_id_key UNIQUE (client_id, portal, login_id);
alter table public.client_reports add constraint client_reports_pkey PRIMARY KEY (id);
alter table public.client_reports add constraint client_reports_client_id_period_key UNIQUE (client_id, period);
alter table public.client_rules add constraint client_rules_pkey PRIMARY KEY (id);
alter table public.client_rules add constraint client_rules_action_check CHECK ((action = ANY (ARRAY['exclude'::text, 'nil'::text, 'exempt'::text, 'nongst'::text, 'exp'::text, 'expg'::text, 'sez'::text, 'rc'::text, 'noitc'::text])));
alter table public.client_rules add constraint client_rules_applies_check CHECK ((applies = ANY (ARRAY['sales'::text, 'purchases'::text, 'both'::text])));
alter table public.client_rules add constraint client_rules_field_check CHECK ((field = ANY (ARRAY['inv'::text, 'party'::text, 'gstin'::text, 'hsn'::text])));
alter table public.client_rules add constraint client_rules_op_check CHECK ((op = ANY (ARRAY['ends'::text, 'starts'::text, 'contains'::text, 'equals'::text, 'blank'::text])));
alter table public.client_rules add constraint client_rules_val_chk CHECK (((op = 'blank'::text) OR (COALESCE(TRIM(BOTH FROM val), ''::text) <> ''::text)));
alter table public.client_uploads add constraint client_uploads_pkey PRIMARY KEY (id);
alter table public.client_uploads add constraint client_uploads_path_key UNIQUE (path);
alter table public.client_users add constraint client_users_pkey PRIMARY KEY (user_id);
alter table public.clients add constraint clients_pkey PRIMARY KEY (id);
alter table public.clients add constraint clients_gst_scheme_check CHECK ((gst_scheme = ANY (ARRAY['Monthly'::text, 'QRMP'::text, 'Composition'::text, 'Not registered'::text])));
alter table public.clients add constraint clients_itc_method_chk CHECK ((itc_method = ANY (ARRAY['books_2b'::text, 'books'::text, '2b_confirm'::text])));
alter table public.clients add constraint clients_status_token_key UNIQUE (status_token);
alter table public.data_request_log add constraint data_request_log_pkey PRIMARY KEY (client_id, kind, period);
alter table public.data_request_settings add constraint data_request_settings_pkey PRIMARY KEY (id);
alter table public.data_request_settings add constraint data_request_settings_id_check CHECK ((id = 1));
alter table public.data_request_templates add constraint data_request_templates_pkey PRIMARY KEY (kind);
alter table public.data_request_templates add constraint data_request_templates_kind_check CHECK ((kind = ANY (ARRAY['gst'::text, 'tds_pay'::text, 'tds_return'::text])));
alter table public.demo_rows add constraint demo_rows_pkey PRIMARY KEY (tbl, row_id);
alter table public.due_dates add constraint due_dates_pkey PRIMARY KEY (id);
alter table public.due_dates add constraint due_dates_due_day_check CHECK (((due_day >= 1) AND (due_day <= 31)));
alter table public.due_dates add constraint due_dates_period_rule_check CHECK ((period_rule = ANY (ARRAY['prev_month'::text, 'prev_quarter'::text, 'prev_half'::text, 'prev_fy'::text, 'current_fy'::text, 'none'::text])));
alter table public.due_dates add constraint due_dates_work_type_check CHECK ((work_type = ANY (ARRAY['GST'::text, 'TDS'::text, 'Income Tax'::text, 'ROC/MCA'::text, 'Other'::text])));
alter table public.fee_rates add constraint fee_rates_pkey PRIMARY KEY (id);
alter table public.fee_rates add constraint fee_rates_amount_check CHECK ((amount >= (0)::numeric));
alter table public.fee_rates add constraint fee_rates_client_id_return_name_key UNIQUE NULLS NOT DISTINCT (client_id, return_name);
alter table public.filing_acks add constraint filing_acks_pkey PRIMARY KEY (id);
alter table public.followups add constraint followups_pkey PRIMARY KEY (id);
alter table public.followups add constraint followups_kind_check CHECK ((kind = ANY (ARRAY['task'::text, 'payment'::text])));
alter table public.followups add constraint followups_kind_task CHECK (((kind = 'task'::text) = (task_id IS NOT NULL)));
alter table public.gst_checks add constraint gst_checks_pkey PRIMARY KEY (id);
alter table public.gst_months add constraint gst_months_pkey PRIMARY KEY (id);
alter table public.gst_months add constraint gst_months_client_id_period_key UNIQUE (client_id, period);
alter table public.gst_months add constraint gst_months_status_check CHECK ((status = ANY (ARRAY['Draft'::text, 'Verified'::text])));
alter table public.gst_reviews add constraint gst_reviews_pkey PRIMARY KEY (client_id, period, kind);
alter table public.gst_reviews add constraint gst_reviews_kind_chk CHECK ((kind = ANY (ARRAY['gstr1'::text, 'gstr3b'::text])));
alter table public.gst_reviews add constraint gst_reviews_state_check CHECK ((state = ANY (ARRAY['draft'::text, 'sent'::text, 'changes'::text, 'approved'::text, 'sent_client'::text])));
alter table public.gst_settings add constraint gst_settings_pkey PRIMARY KEY (id);
alter table public.gst_settings add constraint gst_settings_end_day_check CHECK (((end_day >= 1) AND (end_day <= 31)));
alter table public.gst_settings add constraint gst_settings_id_check CHECK ((id = 1));
alter table public.gst_settings add constraint gst_settings_start_day_check CHECK (((start_day >= 1) AND (start_day <= 31)));
alter table public.gst_tp_sessions add constraint gst_tp_sessions_pkey PRIMARY KEY (client_id);
alter table public.invoices add constraint invoices_pkey PRIMARY KEY (id);
alter table public.invoices add constraint invoices_inv_no_key UNIQUE (inv_no);
alter table public.invoices add constraint invoices_zoho_invoice_id_key UNIQUE (zoho_invoice_id);
alter table public.law_updates add constraint law_updates_pkey PRIMARY KEY (id);
alter table public.law_updates add constraint law_updates_dept_check CHECK ((dept = ANY (ARRAY['GST'::text, 'TDS'::text, 'Income Tax'::text, 'ROC/MCA'::text, 'Other'::text])));
alter table public.law_updates add constraint law_updates_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'published'::text])));
alter table public.linked_rules add constraint linked_rules_pkey PRIMARY KEY (id);
alter table public.login_access_log add constraint login_access_log_pkey PRIMARY KEY (id);
alter table public.mail_inbox add constraint mail_inbox_pkey PRIMARY KEY (id);
alter table public.mail_inbox add constraint mail_inbox_msg_id_key UNIQUE (msg_id);
alter table public.mail_inbox add constraint mail_inbox_status_check CHECK ((status = ANY (ARRAY['New'::text, 'Done'::text, 'Ignored'::text])));
alter table public.mail_jobs add constraint mail_jobs_pkey PRIMARY KEY (id);
alter table public.mail_jobs add constraint mail_jobs_status_check CHECK ((status = ANY (ARRAY['new'::text, 'sent'::text, 'failed'::text])));
alter table public.mail_settings add constraint mail_settings_pkey PRIMARY KEY (id);
alter table public.mail_settings add constraint mail_settings_id_check CHECK ((id = 1));
alter table public.mca_companies add constraint mca_companies_pkey PRIMARY KEY (client_id);
alter table public.mca_directors add constraint mca_directors_pkey PRIMARY KEY (id);
alter table public.notice_mails add constraint notice_mails_pkey PRIMARY KEY (id);
alter table public.notice_mails add constraint notice_mails_mail_id_key UNIQUE (mail_id);
alter table public.notice_watch add constraint notice_watch_pkey PRIMARY KEY (id);
alter table public.notice_watch add constraint notice_watch_id_check CHECK ((id = 1));
alter table public.notices add constraint notices_pkey PRIMARY KEY (id);
alter table public.notices add constraint notices_status_check CHECK ((status = ANY (ARRAY['Open'::text, 'Reply drafted'::text, 'Replied'::text, 'Hearing'::text, 'Closed'::text])));
alter table public.onboarding add constraint onboarding_pkey PRIMARY KEY (client_id);
alter table public.onboarding add constraint onboarding_status_check CHECK ((status = ANY (ARRAY['In progress'::text, 'Completed'::text])));
alter table public.payment_claims add constraint payment_claims_pkey PRIMARY KEY (id);
alter table public.payment_claims add constraint payment_claims_amount_check CHECK ((amount > (0)::numeric));
alter table public.payment_claims add constraint payment_claims_status_check CHECK ((status = ANY (ARRAY['New'::text, 'Confirmed'::text, 'Rejected'::text])));
alter table public.payments add constraint payments_pkey PRIMARY KEY (id);
alter table public.payments add constraint payments_amount_check CHECK ((amount > (0)::numeric));
alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);
alter table public.profiles add constraint profiles_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'partner'::text, 'manager'::text, 'staff'::text])));
alter table public.renewals add constraint renewals_pkey PRIMARY KEY (id);
alter table public.renewals add constraint renewals_status_check CHECK ((status = ANY (ARRAY['Active'::text, 'Renewal in progress'::text, 'Not renewing'::text, 'Closed'::text])));
alter table public.settings add constraint settings_pkey PRIMARY KEY (id);
alter table public.settings add constraint settings_id_check CHECK ((id = 1));
alter table public.task_checks add constraint task_checks_pkey PRIMARY KEY (id);
alter table public.task_checks add constraint task_checks_status_check CHECK ((status = ANY (ARRAY['Pending'::text, 'Done'::text, 'N/A'::text])));
alter table public.task_checks add constraint task_checks_task_id_seq_key UNIQUE (task_id, seq);
alter table public.task_docs add constraint task_docs_pkey PRIMARY KEY (id);
alter table public.task_docs add constraint task_docs_task_id_name_key UNIQUE (task_id, name);
alter table public.tasks add constraint tasks_pkey PRIMARY KEY (id);
alter table public.tasks add constraint tasks_client_id_return_name_period_key UNIQUE (client_id, return_name, period);
alter table public.tasks add constraint tasks_status_check CHECK ((status = ANY (ARRAY['Pending data'::text, 'In progress'::text, 'Ready to file'::text, 'Filed'::text, 'Not applicable'::text])));
alter table public.tasks add constraint tasks_work_type_check CHECK ((work_type = ANY (ARRAY['GST'::text, 'TDS'::text, 'Income Tax'::text, 'ROC/MCA'::text, 'Other'::text])));
alter table public.tax_intimations add constraint tax_intimations_pkey PRIMARY KEY (id);
alter table public.tax_intimations add constraint tax_intimations_client_id_kind_period_key UNIQUE (client_id, kind, period);
alter table public.tax_intimations add constraint tax_intimations_kind_check CHECK ((kind = ANY (ARRAY['GST'::text, 'TDS'::text, 'ADV'::text])));
alter table public.tds_challans add constraint tds_challans_pkey PRIMARY KEY (id);
alter table public.tds_challans add constraint tds_challans_client_id_month_sec_key UNIQUE (client_id, month, sec);
alter table public.tds_entries add constraint tds_entries_pkey PRIMARY KEY (id);
alter table public.tds_returns add constraint tds_returns_pkey PRIMARY KEY (id);
alter table public.tds_returns add constraint tds_returns_client_id_fy_q_form_key UNIQUE (client_id, fy, q, form);
alter table public.tds_returns add constraint tds_returns_form_check CHECK ((form = ANY (ARRAY['24Q'::text, '26Q'::text, '27Q'::text])));
alter table public.tds_returns add constraint tds_returns_q_check CHECK (((q >= 1) AND (q <= 4)));
alter table public.tds_returns add constraint tds_returns_status_check CHECK ((status = ANY (ARRAY['Not started'::text, 'Data pending'::text, 'Prepared'::text, 'Filed'::text, 'Revised'::text])));
alter table public.wa_log add constraint wa_log_pkey PRIMARY KEY (id);
alter table public.wa_settings add constraint wa_settings_pkey PRIMARY KEY (id);
alter table public.wa_settings add constraint wa_settings_id_check CHECK ((id = 1));
alter table public.work_requests add constraint work_requests_pkey PRIMARY KEY (id);
alter table public.work_requests add constraint work_requests_priority_check CHECK ((priority = ANY (ARRAY['Normal'::text, 'High'::text, 'Urgent'::text])));
alter table public.work_requests add constraint work_requests_status_check CHECK ((status = ANY (ARRAY['New'::text, 'In progress'::text, 'Done'::text, 'Cancelled'::text])));
alter table public.zoho_items add constraint zoho_items_pkey PRIMARY KEY (name);
alter table public.zoho_settings add constraint zoho_settings_pkey PRIMARY KEY (id);
alter table public.zoho_settings add constraint zoho_settings_id_check CHECK ((id = 1));
alter table public.zoho_state add constraint zoho_state_pkey PRIMARY KEY (id);
alter table public.zoho_state add constraint zoho_state_id_check CHECK ((id = 1));

-- ==== fk ====
alter table public.ai_usage add constraint ai_usage_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
alter table public.ai_usage add constraint ai_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.auto_work_done add constraint auto_work_done_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.bank_rules add constraint bank_rules_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.bank_rules add constraint bank_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.bank_statements add constraint bank_statements_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.bank_statements add constraint bank_statements_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.chase_log add constraint chase_log_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_logins add constraint client_logins_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_logins add constraint client_logins_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.client_reports add constraint client_reports_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_reports add constraint client_reports_published_by_fkey FOREIGN KEY (published_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.client_rules add constraint client_rules_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_rules add constraint client_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.client_uploads add constraint client_uploads_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_uploads add constraint client_uploads_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES task_docs(id) ON DELETE SET NULL;
alter table public.client_uploads add constraint client_uploads_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL;
alter table public.client_users add constraint client_users_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.client_users add constraint client_users_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.client_users add constraint client_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.clients add constraint clients_default_staff_fkey FOREIGN KEY (default_staff) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.data_request_log add constraint data_request_log_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.fee_rates add constraint fee_rates_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.filing_acks add constraint filing_acks_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
alter table public.filing_acks add constraint filing_acks_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL;
alter table public.followups add constraint followups_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.followups add constraint followups_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.followups add constraint followups_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;
alter table public.gst_checks add constraint gst_checks_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.gst_months add constraint gst_months_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.gst_months add constraint gst_months_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.gst_months add constraint gst_months_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.gst_reviews add constraint gst_reviews_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.gst_reviews add constraint gst_reviews_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.gst_tp_sessions add constraint gst_tp_sessions_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.invoices add constraint invoices_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
alter table public.invoices add constraint invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.law_updates add constraint law_updates_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.login_access_log add constraint login_access_log_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
alter table public.login_access_log add constraint login_access_log_login_id_fkey FOREIGN KEY (login_id) REFERENCES client_logins(id) ON DELETE SET NULL;
alter table public.login_access_log add constraint login_access_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.mail_inbox add constraint mail_inbox_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.mail_inbox add constraint mail_inbox_handled_by_fkey FOREIGN KEY (handled_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.mail_jobs add constraint mail_jobs_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.mca_companies add constraint mca_companies_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.mca_companies add constraint mca_companies_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.mca_directors add constraint mca_directors_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.notice_mails add constraint notice_mails_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
alter table public.notice_mails add constraint notice_mails_notice_id_fkey FOREIGN KEY (notice_id) REFERENCES notices(id) ON DELETE SET NULL;
alter table public.notices add constraint notices_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.notices add constraint notices_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.notices add constraint notices_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.onboarding add constraint onboarding_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.onboarding add constraint onboarding_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.payment_claims add constraint payment_claims_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.payment_claims add constraint payment_claims_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL;
alter table public.payments add constraint payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;
alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.renewals add constraint renewals_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.renewals add constraint renewals_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.renewals add constraint renewals_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.settings add constraint settings_senior_id_fkey FOREIGN KEY (senior_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.task_checks add constraint task_checks_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.task_checks add constraint task_checks_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;
alter table public.task_docs add constraint task_docs_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;
alter table public.tasks add constraint tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.tasks add constraint tasks_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.tasks add constraint tasks_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL;
alter table public.tasks add constraint tasks_parent_task_fkey FOREIGN KEY (parent_task) REFERENCES tasks(id) ON DELETE SET NULL;
alter table public.tasks add constraint tasks_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.tax_intimations add constraint tax_intimations_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.tax_intimations add constraint tax_intimations_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.tds_challans add constraint tds_challans_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.tds_entries add constraint tds_entries_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.tds_entries add constraint tds_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.tds_returns add constraint tds_returns_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;
alter table public.wa_log add constraint wa_log_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE SET NULL;
alter table public.work_requests add constraint work_requests_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES profiles(id);
alter table public.work_requests add constraint work_requests_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;
alter table public.work_requests add constraint work_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES profiles(id);

-- ==== idx ====
CREATE INDEX ai_usage_at ON public.ai_usage USING btree (at);
CREATE INDEX audit_at ON public.audit_log USING btree (at DESC);
CREATE INDEX audit_client ON public.audit_log USING btree (client_id, at DESC);
CREATE INDEX audit_row ON public.audit_log USING btree (area, row_id, at DESC);
CREATE INDEX audit_user ON public.audit_log USING btree (user_id, at DESC);
CREATE INDEX backups_taken ON public.backups USING btree (taken_at DESC);
CREATE INDEX bank_rules_client ON public.bank_rules USING btree (client_id);
CREATE INDEX bank_st_client ON public.bank_statements USING btree (client_id, period_to DESC);
CREATE INDEX chase_log_client ON public.chase_log USING btree (client_id, created_at DESC);
CREATE INDEX chase_log_queue ON public.chase_log USING btree (status) WHERE (status = 'queued'::text);
CREATE INDEX client_logins_client ON public.client_logins USING btree (client_id);
CREATE INDEX client_rules_client_idx ON public.client_rules USING btree (client_id);
CREATE INDEX client_uploads_task ON public.client_uploads USING btree (task_id);
CREATE INDEX client_users_client ON public.client_users USING btree (client_id);
CREATE INDEX cr_period ON public.client_reports USING btree (period);
CREATE INDEX filing_acks_client ON public.filing_acks USING btree (client_id, created_at DESC);
CREATE INDEX filing_acks_task ON public.filing_acks USING btree (task_id);
CREATE INDEX followups_client ON public.followups USING btree (client_id, kind);
CREATE INDEX followups_date ON public.followups USING btree (on_date);
CREATE INDEX followups_task ON public.followups USING btree (task_id);
CREATE INDEX gst_checks_req_idx ON public.gst_checks USING btree (requested_at DESC);
CREATE INDEX gst_months_client ON public.gst_months USING btree (client_id, period DESC);
CREATE INDEX gst_reviews_tag_idx ON public.gst_reviews USING btree (tag);
CREATE INDEX gst_reviews_token_idx ON public.gst_reviews USING btree (token_hash);
CREATE INDEX invoices_client ON public.invoices USING btree (client_id);
CREATE INDEX law_updates_pub ON public.law_updates USING btree (status, published_at DESC);
CREATE INDEX login_access_log_at ON public.login_access_log USING btree (at DESC);
CREATE INDEX mail_inbox_client ON public.mail_inbox USING btree (client_id);
CREATE INDEX mail_inbox_recv ON public.mail_inbox USING btree (received_at DESC);
CREATE INDEX mail_jobs_new_idx ON public.mail_jobs USING btree (status, created_at);
CREATE INDEX mcad_client ON public.mca_directors USING btree (client_id);
CREATE INDEX mcad_din ON public.mca_directors USING btree (din);
CREATE INDEX notice_mails_res ON public.notice_mails USING btree (result, created_at DESC);
CREATE INDEX notices_due ON public.notices USING btree (reply_due);
CREATE INDEX pc_status ON public.payment_claims USING btree (status, created_at DESC);
CREATE INDEX renewals_client ON public.renewals USING btree (client_id);
CREATE INDEX renewals_exp ON public.renewals USING btree (expires_on);
CREATE INDEX task_checks_task ON public.task_checks USING btree (task_id);
CREATE INDEX task_docs_task ON public.task_docs USING btree (task_id);
CREATE INDEX tasks_assigned_idx ON public.tasks USING btree (assigned_to);
CREATE INDEX tasks_client_idx ON public.tasks USING btree (client_id);
CREATE INDEX tasks_due_idx ON public.tasks USING btree (due_date);
CREATE INDEX tds_c_month ON public.tds_challans USING btree (month);
CREATE INDEX tds_e_client_fy ON public.tds_entries USING btree (client_id, fy);
CREATE INDEX tds_e_month ON public.tds_entries USING btree (month);
CREATE INDEX ti_due ON public.tax_intimations USING btree (due_date);
CREATE INDEX wa_log_sent_idx ON public.wa_log USING btree (sent_at DESC);
CREATE INDEX wr_assigned ON public.work_requests USING btree (assigned_to, status);
CREATE INDEX wr_requested ON public.work_requests USING btree (requested_by, status);
CREATE UNIQUE INDEX clients_code_uq ON public.clients USING btree (client_code) WHERE (client_code IS NOT NULL);
CREATE UNIQUE INDEX mcad_client_din ON public.mca_directors USING btree (client_id, din) WHERE (din IS NOT NULL);

-- ==== funcs ====
set check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.ai_admin_save(p_enabled boolean, p_model text, p_max integer, p_price_in numeric, p_price_out numeric, p_usd_inr numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only an admin can change AI settings'; end if;
  update public.ai_settings set enabled = p_enabled, model = coalesce(nullif(btrim(p_model), ''), 'claude-haiku-5-5'),
    max_per_month = greatest(0, coalesce(p_max, 0)), price_in = coalesce(p_price_in, 0), price_out = coalesce(p_price_out, 0), usd_inr = coalesce(p_usd_inr, 88) where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.ai_admin_set_key(p_key text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'vault'
AS $function$
declare sid uuid;
begin
  if not public.is_admin() then raise exception 'Only an admin can save the AI key'; end if;
  select key_secret into sid from public.ai_settings where id = 1;
  if p_key is null or btrim(p_key) = '' then
    if sid is not null then delete from vault.secrets where id = sid; end if;
    update public.ai_settings set key_secret = null, key_set_at = null, key_hint = null, enabled = false where id = 1;
    return;
  end if;
  if sid is not null and exists (select 1 from vault.secrets where id = sid) then
    perform vault.update_secret(sid, btrim(p_key));
  else
    sid := vault.create_secret(btrim(p_key), 'ai_api_key_' || substr(md5(random()::text), 1, 6), 'Claude API key for bill reading');
  end if;
  update public.ai_settings set key_secret = sid, key_set_at = now(), key_hint = right(btrim(p_key), 4) where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.ai_admin_status()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.ai_settings; m date := date_trunc('month', now())::date;
begin
  if not public.is_manager() then raise exception 'Only a manager or admin can see AI settings'; end if;
  select * into s from public.ai_settings where id = 1;
  return json_build_object('enabled', s.enabled, 'model', s.model, 'max_per_month', s.max_per_month, 'price_in', s.price_in, 'price_out', s.price_out,
    'usd_inr', s.usd_inr, 'key_set', s.key_secret is not null, 'key_set_at', s.key_set_at, 'key_hint', s.key_hint,
    'month_reads', (select count(*) from public.ai_usage where at >= m and ok),
    'month_cost', (select coalesce(sum(cost_inr), 0) from public.ai_usage where at >= m),
    'month_errors', (select count(*) from public.ai_usage where at >= m and ok = false));
end $function$
;

CREATE OR REPLACE FUNCTION public.ai_can_read(p_client uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.ai_settings; n int;
begin
  select * into s from public.ai_settings where id = 1;
  if auth.uid() is null or not public.can_client_login(p_client) then return json_build_object('ok', false, 'why', 'You cannot read bills for this client'); end if;
  if not s.enabled or s.key_secret is null then return json_build_object('ok', false, 'why', 'AI bill reading is switched off (Settings → Bill reading)'); end if;
  select count(*) into n from public.ai_usage where at >= date_trunc('month', now()) and ok;
  if n >= s.max_per_month then return json_build_object('ok', false, 'why', 'This month''s AI limit (' || s.max_per_month || ' bills) is used up'); end if;
  return json_build_object('ok', true, 'model', s.model, 'user', auth.uid());
end $function$
;

CREATE OR REPLACE FUNCTION public.ai_key()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'vault'
AS $function$
declare s public.ai_settings; k text;
begin
  select * into s from public.ai_settings where id = 1;
  select decrypted_secret into k from vault.decrypted_secrets where id = s.key_secret;
  return json_build_object('key', k, 'model', s.model, 'price_in', s.price_in, 'price_out', s.price_out, 'usd_inr', s.usd_inr);
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_event(p_action text, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then return; end if;
  if p_action not in ('sign_in', 'sign_out', 'idle_sign_out', 'export') then raise exception 'Unknown event'; end if;
  -- one sign-in row per 10 minutes is enough (page reloads)
  if p_action = 'sign_in' and exists (select 1 from public.audit_log where user_id = auth.uid() and action = 'sign_in' and at > now() - interval '10 minutes') then return; end if;
  insert into public.audit_log (user_id, user_name, area, action, summary)
  values (auth.uid(), public.audit_who(), 'login', p_action, left(coalesce(p_note, ''), 300));
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_row()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  o jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  n jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  r jsonb; ch jsonb := '{}'::jsonb; k text; cid uuid; s text;
  skip text[] := array['updated_at', 'updated_by', 'created_at', 'fu_count', 'fu_last', 'fu_next', 'checks_total', 'checks_done', 'html', 'search_text', 'started_at', 'done_at'];
begin
  if coalesce(current_setting('jlr.no_audit', true), '') = 'on' then return null; end if;   -- sample data load / clear
  r := coalesce(n, o);
  if tg_op = 'UPDATE' then
    for k in select jsonb_object_keys(n) loop
      if k = any(skip) then continue; end if;
      if (o -> k) is distinct from (n -> k) then ch := ch || jsonb_build_object(k, jsonb_build_array(public.audit_val(k, o -> k), public.audit_val(k, n -> k))); end if;
    end loop;
    if ch = '{}'::jsonb then return null; end if;
  else
    for k in select jsonb_object_keys(r) loop
      if k = any(skip) or k = 'id' or r -> k = 'null'::jsonb or r -> k = '""'::jsonb or r -> k = '[]'::jsonb then continue; end if;
      ch := ch || jsonb_build_object(k, public.audit_val(k, r -> k));
    end loop;
  end if;
  begin cid := case when tg_table_name = 'clients' then (r ->> 'id')::uuid else (r ->> 'client_id')::uuid end; exception when others then cid := null; end;
  s := case tg_table_name
    when 'clients'   then coalesce(r ->> 'client_code' || ' · ', '') || coalesce(r ->> 'name', '')
    when 'tasks'     then concat_ws(' ', r ->> 'return_name', r ->> 'period')
    when 'notices'   then concat_ws(' ', case r ->> 'dept' when 'ROC/MCA' then 'MCA' else r ->> 'dept' end, r ->> 'notice_type', r ->> 'ref_no')
    when 'invoices'  then 'Invoice ' || coalesce(r ->> 'inv_no', '')
    when 'payments'  then 'Payment ₹' || coalesce(r ->> 'amount', '')
    when 'profiles'  then concat_ws(' ', coalesce(nullif(r ->> 'full_name', ''), r ->> 'email'), '(' || (r ->> 'role') || ')')
    when 'task_docs' then 'File ' || coalesce(r ->> 'file_name', r ->> 'name', '')
    when 'tds_challans' then 'TDS challan ' || concat_ws(' ', r ->> 'section', r ->> 'month')
    when 'work_requests' then 'Request: ' || coalesce(r ->> 'title', '') || coalesce(' → ' || (select coalesce(nullif(full_name, ''), email) from public.profiles where id = (r ->> 'assigned_to')::uuid), '')
    else coalesce(r ->> 'name', r ->> 'title', r ->> 'item', r ->> 'return_name', r ->> 'id') end;
  if cid is not null and tg_table_name <> 'clients' then
    s := coalesce((select coalesce(client_code || ' · ', '') || name from public.clients where id = cid), '') || ' — ' || coalesce(s, '');
  end if;
  insert into public.audit_log (user_id, user_name, area, row_id, client_id, action, summary, changes)
  values (auth.uid(), public.audit_who(), tg_table_name, r ->> 'id', cid, lower(tg_op), left(s, 300), ch);
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_val(k text, v jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when k ~* '(token|secret|password|passwd|key_hash)' then to_jsonb('(changed)'::text)
              when v is not null and length(v::text) > 400 then to_jsonb(left(v #>> '{}', 400) || '…')
              else v end
$function$
;

CREATE OR REPLACE FUNCTION public.audit_who()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when auth.uid() is null then 'System (automatic)' else coalesce((select coalesce(nullif(full_name, ''), email) from public.profiles where id = auth.uid()), 'Unknown user') end
$function$
;

CREATE OR REPLACE FUNCTION public.auto_gst_work(p_day date DEFAULT NULL::date, p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare d date := coalesce(p_day, public.ist_today()); y int := extract(year from d); m int := extract(month from d);
        r record; c record; per text; due date; made int := 0; s record;
begin
  select * into s from public.auto_work_settings where id = 1;
  if not p_force and not coalesce(s.gst_enabled, true) then return 0; end if;
  -- rows with no months / period filled in get the usual GST law defaults
  for r in select dd.*, coalesce(dd.period_rule, case when dd.return_name ~* 'quarter|CMP-08' then 'prev_quarter' else 'prev_month' end) rule
             from public.due_dates dd
            where dd.work_type = 'GST' and dd.applies_to in ('Monthly', 'QRMP', 'Composition') and dd.due_day is not null
              and m = any(coalesce(dd.months, case when dd.return_name ~* 'quarter|CMP-08' then array[1,4,7,10]
                                                   when dd.return_name ~* 'PMT-06|IFF' then array[2,3,5,6,8,9,11,12]
                                                   else array[1,2,3,4,5,6,7,8,9,10,11,12] end)) loop
    per := public.aw_period(r.rule, y, m);
    if per is null then continue; end if;
    due := make_date(y, m, least(r.due_day, extract(day from (make_date(y, m, 1) + interval '1 month - 1 day'))::int));
    for c in select * from public.clients where active and 'GST' = any(services) and gst_scheme = r.applies_to
               -- quarterly GSTR-3B: 22nd or 24th by the state in the GSTIN (Category Y states file on the 24th)
               and (r.return_name !~* 'GSTR-3B \(Quarterly'
                    or (r.return_name ~* 'Cat Y') = (left(coalesce(gstin, ''), 2) in ('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','38'))) loop
      if exists (select 1 from public.auto_work_done x where x.client_id = c.id and x.return_name = r.return_name and x.period = per) then continue; end if;
      insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks)
      values (c.id, 'GST', r.return_name, per, due, c.default_staff, 'Pending data', 'Created automatically')
      on conflict (client_id, return_name, period) do nothing;
      if found then made := made + 1; end if;
      insert into public.auto_work_done (client_id, return_name, period) values (c.id, r.return_name, per) on conflict do nothing;
    end loop;
  end loop;
  update public.auto_work_settings set last_run_at = now(), last_made = made,
    last_note = to_char(d, 'Mon YYYY') || ': ' || made || ' new GST work item' || case when made = 1 then '' else 's' end where id = 1;
  return made;
end $function$
;

CREATE OR REPLACE FUNCTION public.auto_work_run()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  return public.auto_gst_work(null, true);
end $function$
;

CREATE OR REPLACE FUNCTION public.auto_work_save(p_gst boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_partner() then raise exception 'Only a Partner or the Admin can change this'; end if;
  update public.auto_work_settings set gst_enabled = p_gst where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.auto_work_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record;
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  select * into s from public.auto_work_settings where id = 1;
  return jsonb_build_object('gst_enabled', s.gst_enabled, 'last_run_at', s.last_run_at, 'last_made', s.last_made, 'last_note', s.last_note);
end $function$
;

CREATE OR REPLACE FUNCTION public.aw_period(p_rule text, y integer, m integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare mon text[] := array['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        d date; qm int; qy int; q int;
        fy text;
begin
  if p_rule = 'prev_month' then
    d := make_date(y, m, 1) - interval '1 month';
    return mon[extract(month from d)::int] || ' ' || extract(year from d)::int;
  elsif p_rule = 'prev_quarter' then
    qm := m - 1; qy := y; if qm < 1 then qm := 12; qy := qy - 1; end if;
    while qm % 3 <> 0 loop qm := qm - 1; if qm < 1 then qm := 12; qy := qy - 1; end if; end loop;
    q := case qm when 6 then 1 when 9 then 2 when 12 then 3 else 4 end;
    qy := case when qm = 3 then qy - 1 else qy end;
    return 'Q' || q || ' FY ' || qy || '-' || right((qy + 1)::text, 2);
  elsif p_rule = 'prev_fy' then
    qy := case when m >= 4 then y - 1 else y - 2 end; return 'FY ' || qy || '-' || right((qy + 1)::text, 2);
  elsif p_rule = 'current_fy' then
    qy := case when m >= 4 then y else y - 1 end; return 'FY ' || qy || '-' || right((qy + 1)::text, 2);
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.can_client_login(p_client uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_manager() or (public.is_member() and (
    exists (select 1 from public.clients c where c.id = p_client and c.default_staff = auth.uid())
    or exists (select 1 from public.tasks t where t.client_id = p_client and t.assigned_to = auth.uid()
               and t.status not in ('Filed', 'Not applicable'))));
$function$
;

CREATE OR REPLACE FUNCTION public.can_task(tid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_manager() or exists (select 1 from public.tasks t where t.id = tid and t.assigned_to = auth.uid())
$function$
;

CREATE OR REPLACE FUNCTION public.chase_candidates()
 RETURNS TABLE(client_id uuid, name text, contact text, phone text, email text, token text, items text, lines text, earliest date, staff uuid[], sent_30 integer, last_sent timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with s as (select * from public.chase_settings where id = 1), t as (select public.ist_today() d),
  w as (
    select k.id, k.client_id, k.return_name, k.period, k.due_date, k.assigned_to
      from public.tasks k, s, t
     where k.status = 'Pending data' and k.data_received_on is null and k.due_date is not null
       and k.due_date between t.d - 15 and t.d + s.start_days),
  dx as (select distinct w.client_id, x.doc from w, unnest(public.task_missing_docs(w.id, w.return_name)) x(doc)),
  dg as (select dx.client_id, string_agg(dx.doc, ', ' order by dx.doc) docs, string_agg('  • ' || dx.doc, E'\n' order by dx.doc) doc_lines from dx group by dx.client_id),
  g as (
    select w.client_id, string_agg(w.return_name || ' ' || w.period, ', ' order by w.due_date, w.return_name) items,
           string_agg('  • ' || w.return_name || ' – ' || w.period || ' (due ' || to_char(w.due_date, 'DD Mon YYYY') || ')', E'\n' order by w.due_date, w.return_name) lines,
           min(w.due_date) earliest, array_agg(distinct w.assigned_to) filter (where w.assigned_to is not null) staff
      from w group by w.client_id)
  select c.id, c.name, coalesce(nullif(c.contact_person, ''), c.name), nullif(regexp_replace(coalesce(c.phone, ''), '\D', '', 'g'), ''),
         nullif(trim(split_part(coalesce(c.email, ''), ',', 1)), ''), c.status_token::text,
         g.items || coalesce(' — please send: ' || dg.docs, ''),
         g.lines || coalesce(E'\n\nDocuments still needed:\n' || dg.doc_lines, ''),
         g.earliest, g.staff,
         (select count(distinct date_trunc('hour', l.created_at))::int from public.chase_log l where l.client_id = c.id and l.kind = 'client' and l.status in ('sent', 'queued') and l.created_at > now() - interval '30 days'),
         (select max(l.created_at) from public.chase_log l where l.client_id = c.id and l.kind = 'client' and l.status in ('sent', 'queued'))
    from g join public.clients c on c.id = g.client_id left join dg on dg.client_id = g.client_id
   where c.active and not c.chase_off
$function$
;

CREATE OR REPLACE FUNCTION public.chase_outbox(p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.nw_key_ok(p_key) then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'to', to_addr, 'subject', subject, 'body', body) order by created_at)
                     from (select * from public.chase_log where status = 'queued' and channel = 'email' order by created_at limit 20) q), '[]'::jsonb);
end $function$
;

CREATE OR REPLACE FUNCTION public.chase_run(p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare s record; w record; r record; tok text; site text; n int := 0; rn int; sent_wa boolean; sent_em boolean; via text; subj text; body text; url text;
        stf text[]; mgr text[];
begin
  select * into s from public.chase_settings where id = 1;
  if not s.enabled and not p_force then return 0; end if;
  select * into w from public.wa_settings limit 1;
  select decrypted_secret into tok from vault.decrypted_secrets where name = 'whatsapp_token' limit 1;
  site := public.chase_site();
  select array_agg(email) into mgr from public.profiles where active and role in ('admin', 'partner', 'manager') and coalesce(email, '') <> '';

  for r in select * from public.chase_candidates() loop
    if r.last_sent is not null and r.last_sent > now() - make_interval(days => s.every_days) + interval '2 hours' then continue; end if;
    if r.sent_30 >= s.max_month then continue; end if;
    rn := r.sent_30 + 1; sent_wa := false; sent_em := false;
    url := site || 'status.html?c=' || coalesce(r.token, '');

    -- WhatsApp (existing approved template client_data_reminder: name, items, earliest due, status link)
    if s.use_wa and r.phone is not null and tok is not null and w.phone_number_id is not null then
      begin
        perform net.http_post(url := 'https://graph.facebook.com/' || coalesce(w.api_version, 'v25.0') || '/' || w.phone_number_id || '/messages',
          headers := jsonb_build_object('Authorization', 'Bearer ' || tok, 'Content-Type', 'application/json'),
          body := jsonb_build_object('messaging_product', 'whatsapp', 'to', case when length(r.phone) = 10 then '91' || r.phone else r.phone end, 'type', 'template',
            'template', jsonb_build_object('name', coalesce(nullif(w.client_template, ''), 'client_data_reminder'), 'language', jsonb_build_object('code', coalesce(w.template_lang, 'en')),
              'components', jsonb_build_array(jsonb_build_object('type', 'body', 'parameters', jsonb_build_array(
                jsonb_build_object('type', 'text', 'text', left(r.contact, 60)), jsonb_build_object('type', 'text', 'text', left(r.items, 400)),
                jsonb_build_object('type', 'text', 'text', to_char(r.earliest, 'DD Mon YYYY')), jsonb_build_object('type', 'text', 'text', url)))))),
          timeout_milliseconds := 20000);
        insert into public.chase_log (client_id, channel, round_no, to_addr, items, status, sent_at) values (r.client_id, 'wa', rn, r.phone, r.items, 'sent', now());
        sent_wa := true;
      exception when others then
        insert into public.chase_log (client_id, channel, round_no, to_addr, items, status, error) values (r.client_id, 'wa', rn, r.phone, r.items, 'failed', left(sqlerrm, 300));
      end;
    end if;

    -- email: queued here, sent by the office Gmail script within a minute
    if s.use_email and r.email is not null then
      subj := case when rn = 1 then 'Documents needed: ' else 'Reminder ' || rn || ' – documents needed: ' end || left(r.items, 120);
      body := 'Dear ' || r.contact || ',' || E'\n\n' ||
        case when rn = 1 then 'We are getting ready to file your returns and are waiting for your documents for:'
             else 'This is a gentle reminder — we are still waiting for your documents for:' end || E'\n' || r.lines || E'\n\n' ||
        case when r.earliest < public.ist_today() then 'The due date has already passed, so late fee and interest may apply. Please send the documents today.'
             when r.earliest - 2 <= public.ist_today() then 'Please send them as soon as possible so we can file on time and avoid late fees.'
             else 'Please send them before ' || to_char(r.earliest - 2, 'DD Mon YYYY') || ' so we can file on time and avoid late fees.' end || E'\n' ||
        'You can simply reply to this email with the files, or send them on WhatsApp.' || E'\n\n' ||
        'Live status of your work: ' || url || E'\n\n' || 'Regards,' || E'\n' || coalesce((select firm_name from public.settings limit 1), 'JLR Compliance');
      insert into public.chase_log (client_id, channel, round_no, to_addr, subject, body, items, status) values (r.client_id, 'email', rn, r.email, subj, body, r.items, 'queued');
      sent_em := true;
    end if;

    if not (sent_wa or sent_em) then
      insert into public.chase_log (client_id, channel, round_no, items, status, error) values (r.client_id, 'none', rn, r.items, 'skipped', 'No mobile number / email saved for this client');
      continue;
    end if;
    n := n + 1;
    via := case when sent_wa and sent_em then 'WhatsApp + email' when sent_wa then 'WhatsApp' else 'email' end;

    -- show it on the work as a follow-up (best effort: the follow-up table may have its own rules)
    begin      -- logged under the staff member of the work (or the Admin)
      insert into public.followups (kind, task_id, client_id, on_date, mode, note, next_on, created_by)
      select 'task', k.id, k.client_id, public.ist_today(), case when sent_wa then 'WhatsApp' else 'Email' end,
             'Automatic reminder ' || rn || ' (' || via || ')', public.ist_today() + s.every_days,
             coalesce(k.assigned_to, (select id from public.profiles where role = 'admin' and active order by created_at limit 1))
        from public.tasks k where k.client_id = r.client_id and k.status = 'Pending data' and k.data_received_on is null
         and k.due_date between public.ist_today() - 15 and public.ist_today() + s.start_days;
    exception when others then
      begin
        insert into public.followups (kind, task_id, client_id, on_date, mode, note, next_on)
        select 'task', k.id, k.client_id, public.ist_today(), case when sent_wa then 'WhatsApp' else 'Email' end,
               'Automatic reminder ' || rn || ' (' || via || ')', public.ist_today() + s.every_days
          from public.tasks k where k.client_id = r.client_id and k.status = 'Pending data' and k.data_received_on is null
           and k.due_date between public.ist_today() - 15 and public.ist_today() + s.start_days;
      exception when others then null;
      end;
    end;

    -- not responding: tell the staff member(s) and Managers once
    if rn = s.escalate_after then
      select array_agg(distinct e) into stf from (select email e from public.profiles where id = any(coalesce(r.staff, '{}')) and coalesce(email, '') <> '' union select unnest(coalesce(mgr, '{}'))) x;
      if stf is not null then
        insert into public.chase_log (client_id, kind, channel, round_no, to_addr, subject, body, items, status)
        values (r.client_id, 'staff', 'email', rn, array_to_string(stf, ','), 'Client not responding: ' || r.name || ' – ' || left(r.items, 100),
          r.name || ' has not sent documents after ' || rn || ' automatic reminders (' || via || ').' || E'\n\nPending:\n' || r.lines || E'\n\n' ||
          'Please call the client.' || coalesce(' Phone: ' || r.phone, '') || E'\n\nOpen the tracker: ' || site || '#/work', r.items, 'queued');
      end if;
    end if;
  end loop;
  update public.chase_settings set last_run_at = now(), last_note = to_char(now() at time zone 'Asia/Kolkata', 'DD Mon HH24:MI') || ': ' || n || ' client' || case when n = 1 then '' else 's' end || ' reminded' where id = 1;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.chase_run_now()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  return public.chase_run(true);
end $function$
;

CREATE OR REPLACE FUNCTION public.chase_save(p jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_partner() then raise exception 'Only a Partner or the Admin can change this'; end if;
  update public.chase_settings set
    enabled = coalesce((p->>'enabled')::boolean, enabled),
    start_days = greatest(1, least(30, coalesce((p->>'start_days')::int, start_days))),
    every_days = greatest(1, least(15, coalesce((p->>'every_days')::int, every_days))),
    max_month = greatest(1, least(10, coalesce((p->>'max_month')::int, max_month))),
    escalate_after = greatest(1, least(10, coalesce((p->>'escalate_after')::int, escalate_after))),
    use_wa = coalesce((p->>'use_wa')::boolean, use_wa), use_email = coalesce((p->>'use_email')::boolean, use_email) where id = 1;
  -- the older one-message client reminder is replaced by this; switch it off to avoid double messages
  if coalesce((p->>'enabled')::boolean, false) then
    begin execute 'update public.wa_settings set client_enabled = false'; exception when others then null; end;
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.nw_key_ok(p_key) then return; end if;
  update public.chase_log set status = case when p_ok then 'sent' else 'failed' end, sent_at = now(), error = left(p_error, 300) where id = p_id and status = 'queued';
end $function$
;

CREATE OR REPLACE FUNCTION public.chase_site()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select regexp_replace(coalesce(nullif(regexp_replace(regexp_replace(coalesce((select app_url from public.wa_settings limit 1), ''), '#.*$', ''), '[^/]*\.html$', ''), ''),
                  'https://jlr-compliance.github.io/jlr-tracker/'), '/?$', '/')
$function$
;

CREATE OR REPLACE FUNCTION public.chase_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record;
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  select * into s from public.chase_settings where id = 1;
  return to_jsonb(s) || jsonb_build_object(
    'mailbox', (select key_hash is not null from public.notice_watch where id = 1),
    'queued', (select count(*) from public.chase_log where status = 'queued'),
    'sent_7', (select count(distinct client_id) from public.chase_log where kind = 'client' and status = 'sent' and created_at > now() - interval '7 days'),
    'failed_7', (select count(*) from public.chase_log where status = 'failed' and created_at > now() - interval '7 days'),
    'preview', (select coalesce(jsonb_agg(jsonb_build_object('client', name, 'items', items, 'earliest', earliest, 'sent_30', sent_30, 'last_sent', last_sent,
                   'phone', phone is not null, 'email', email is not null,
                   'due_now', (last_sent is null or last_sent <= now() - make_interval(days => s.every_days) + interval '2 hours') and sent_30 < s.max_month) order by earliest), '[]'::jsonb)
                from public.chase_candidates()));
end $function$
;

CREATE OR REPLACE FUNCTION public.client_logins_after_del()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if old.secret_id is not null then delete from vault.secrets where id = old.secret_id; end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.clients_code_tidy()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.client_code := nullif(upper(trim(new.client_code)), '');
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.cr_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.published and (tg_op = 'INSERT' or not coalesce(old.published, false)) and not public.is_manager() then
    raise exception 'Only a manager, partner or admin can publish a report to the client portal';
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_invoice(p_client uuid, p_tasks uuid[], p_extra jsonb DEFAULT '[]'::jsonb, p_date date DEFAULT NULL::date, p_notes text DEFAULT NULL::text, p_gst_rate numeric DEFAULT NULL::numeric)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s     public.settings;
  d     date := coalesce(p_date, (now() at time zone 'Asia/Kolkata')::date);
  fy    text;
  items jsonb;
  sub   numeric; gst numeric; rate numeric;
  iid   uuid;
  no    text;
begin
  if not public.is_manager() then raise exception 'Only admin can create invoices'; end if;
  select * into s from public.settings where id = 1 for update;
  if exists (select 1 from public.tasks where id = any(p_tasks) and (client_id <> p_client or invoice_id is not null)) then
    raise exception 'Some work items belong to another client or are already invoiced';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('desc', t.return_name || ' - ' || t.period, 'amount', coalesce(t.fee, 0), 'task_id', t.id)
                            order by t.due_date nulls last, t.return_name), '[]'::jsonb)
    into items from public.tasks t where t.id = any(p_tasks);
  items := items || coalesce((select jsonb_agg(jsonb_build_object('desc', e->>'desc', 'amount', coalesce((e->>'amount')::numeric, 0)))
                              from jsonb_array_elements(coalesce(p_extra, '[]'::jsonb)) e
                              where coalesce(e->>'desc', '') <> ''), '[]'::jsonb);
  if jsonb_array_length(items) = 0 then raise exception 'Nothing to invoice'; end if;
  select coalesce(sum((x->>'amount')::numeric), 0) into sub from jsonb_array_elements(items) x;
  rate := coalesce(p_gst_rate, s.gst_rate, 0);
  if rate < 0 or rate > 28 then raise exception 'GST rate must be between 0 and 28'; end if;
  gst  := round(sub * rate / 100, 2);
  fy   := case when extract(month from d) >= 4 then extract(year from d)::int else extract(year from d)::int - 1 end || '-' ||
          lpad(((case when extract(month from d) >= 4 then extract(year from d)::int else extract(year from d)::int - 1 end + 1) % 100)::text, 2, '0');
  no   := coalesce(nullif(s.invoice_prefix, ''), 'INV') || '/' || fy || '/' || lpad(s.next_invoice_no::text, 3, '0');
  insert into public.invoices (inv_no, client_id, inv_date, items, subtotal, gst_rate, gst_amount, total, notes, created_by)
  values (no, p_client, d, items, sub, rate, gst, sub + gst, p_notes, auth.uid()) returning id into iid;
  update public.settings set next_invoice_no = next_invoice_no + 1 where id = 1;
  update public.tasks set invoice_id = iid where id = any(p_tasks);
  return iid;
end $function$
;

CREATE OR REPLACE FUNCTION public.demo_clear()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  ids uuid[]; tids uuid[]; iids uuid[]; nids uuid[]; t record; p int; n bigint; total bigint := 0; nc int;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Only the Admin can clear sample data'; end if;
  select array_agg(id) into ids from public.clients where is_demo;
  if ids is null then return jsonb_build_object('clients', 0, 'rows', 0); end if;
  nc := array_length(ids, 1);
  perform set_config('jlr.no_audit', 'on', true);
  select array_agg(id) into tids from public.tasks where client_id = any(ids);
  select array_agg(id) into iids from public.invoices where client_id = any(ids);
  select array_agg(id) into nids from public.notices where client_id = any(ids);

  for p in 1 .. 6 loop
    for t in
      select c.table_name tn, c.column_name cn
        from information_schema.columns c
        join information_schema.tables b on b.table_schema = c.table_schema and b.table_name = c.table_name and b.table_type = 'BASE TABLE'
       where c.table_schema = 'public' and c.data_type = 'uuid' and c.column_name in ('client_id', 'task_id', 'invoice_id', 'notice_id')
         and c.table_name <> 'clients'
       order by case c.column_name when 'client_id' then 2 else 1 end, c.table_name
    loop
      begin
        execute format('delete from public.%I where %I = any($1)', t.tn, t.cn)
          using case t.cn when 'client_id' then ids when 'task_id' then tids when 'invoice_id' then iids else nids end;
        get diagnostics n = row_count; total := total + n;
      exception when foreign_key_violation then null;   -- a child still points here; next pass
      end;
    end loop;
    begin
      delete from public.clients where id = any(ids);
      exit;
    exception when foreign_key_violation then
      if p = 6 then raise; end if;
    end;
  end loop;

  delete from public.fee_rates f using public.demo_rows d where d.tbl = 'fee_rates' and d.row_id = f.id::text;
  delete from public.demo_rows;

  perform set_config('jlr.no_audit', '', true);
  insert into public.audit_log (user_id, user_name, area, row_id, client_id, action, summary, changes)
  values (auth.uid(), public.audit_who(), 'demo', null, null, 'delete', 'Sample data cleared: ' || nc || ' demo clients removed', '{}'::jsonb);
  return jsonb_build_object('clients', nc, 'rows', total);
end $function$
;

CREATE OR REPLACE FUNCTION public.demo_load()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  staff uuid[]; me uuid := auth.uid();
  ids uuid[] := '{}'; cid uuid; c record; i int := 0; k int;
  m1 date := date_trunc('month', current_date - interval '1 month')::date;   -- last month
  m2 date := date_trunc('month', current_date - interval '2 month')::date;   -- month before
  q_end date; q_lbl text; fy_lbl text; ay int;
  tid uuid; due date; st text; tids uuid[]; iid uuid; tot numeric; n_inv int := 0; n_task int := 0;
  fees jsonb := '{"GSTR-1":1500,"GSTR-3B":1500,"CMP-08":1000,"TDS payment":1000,"24Q":2500,"26Q":2500,"AOC-4":5000,"MGT-7":5000}';
  r text;
begin
  if me is null or not public.is_admin() then raise exception 'Only the Admin can load sample data'; end if;
  if exists (select 1 from public.clients where is_demo) then raise exception 'Sample data is already loaded. Clear it first.'; end if;
  perform set_config('jlr.no_audit', 'on', true);

  select array_agg(id order by full_name nulls last, email) into staff from public.profiles where coalesce(active, true) and coalesce(role, '') <> 'client';
  if staff is null then staff := array[me]; end if;

  -- last complete quarter (for TDS returns / CMP-08)
  q_end := (date_trunc('quarter', current_date) - interval '1 day')::date;
  ay := extract(year from q_end)::int - case when extract(month from q_end) <= 3 then 1 else 0 end;
  fy_lbl := ay || '-' || right((ay + 1)::text, 2);
  q_lbl := 'Q' || (case extract(month from q_end)::int when 6 then 1 when 9 then 2 when 12 then 3 else 4 end) || ' ' || fy_lbl;

  -- standard fees (only names the office has not set yet)
  for r in select jsonb_object_keys(fees) loop
    if not exists (select 1 from public.fee_rates where client_id is null and lower(return_name) = lower(r)) then
      with x as (insert into public.fee_rates (client_id, return_name, amount) values (null, r, (fees ->> r)::numeric) returning id)
      insert into public.demo_rows select 'fee_rates', id::text from x;
    end if;
  end loop;

  -- 20 clients
  for c in select * from (values
    ( 1,'Sri Lakshmi Traders','F','Monthly','{GST,TDS}',true,false,'Ramesh K'),
    ( 2,'Annai Textiles Pvt Ltd','C','Monthly','{GST,TDS,ROC/MCA}',true,true,'Meena S'),
    ( 3,'Kaveri Agro Foods','F','Monthly','{GST}',false,false,'Senthil Kumar'),
    ( 4,'Velan Logistics Pvt Ltd','C','Monthly','{GST,TDS,ROC/MCA}',true,true,'Prakash V'),
    ( 5,'Sundaram Hardware Stores','P','Monthly','{GST}',false,false,'Sundaram R'),
    ( 6,'Nila Pharma Distributors','F','Monthly','{GST,TDS}',true,true,'Divya N'),
    ( 7,'Kongu Engineering Works','F','Monthly','{GST}',false,false,'Arul Murugan'),
    ( 8,'Marina Software Labs Pvt Ltd','C','Monthly','{GST,TDS,ROC/MCA}',true,true,'Karthik R'),
    ( 9,'Thamarai Electricals','P','Monthly','{GST}',false,false,'Selvi T'),
    (10,'Vaigai Rice Mills','F','Monthly','{GST,TDS}',true,false,'Muthu Pandian'),
    (11,'Chola Interiors','F','Monthly','{GST}',false,false,'Bala Subramanian'),
    (12,'Pearl City Exports Pvt Ltd','C','Monthly','{GST,TDS,ROC/MCA}',true,true,'Joseph A'),
    (13,'Malar Bakery','P','Composition','{GST}',false,false,'Malarvizhi'),
    (14,'Ganesh Tea Stall','P','Composition','{GST}',false,false,'Ganesan P'),
    (15,'Kurinji Organic Farms','F','Composition','{GST}',false,false,'Anitha K'),
    (16,'Ponni Builders','F','Monthly','{GST,TDS}',true,true,'Rajesh P'),
    (17,'Indus Medicals','P','Monthly','{GST}',false,false,'Imran S'),
    (18,'Blue Wave Travels','F','Monthly','{GST}',false,false,'Vasanth M'),
    (19,'Senthamil Printers','P','Monthly','{GST}',false,false,'Tamilselvan'),
    (20,'Aaradhya Holdings Pvt Ltd','C','Not registered','{ROC/MCA,TDS}',true,true,'Lakshmi Narayanan')
  ) v(n, name, typ, scheme, svc, tdsp, tdsr, contact) loop
    i := c.n;
    insert into public.clients (client_code, name, pan, gstin, tan, email, phone, contact_person, gst_scheme, services,
                                default_staff, active, chase_off, tds_pay_work, tds_return, is_demo)
    values ('DEMO-' || lpad(i::text, 2, '0'), c.name,
            'AAX' || c.typ || 'D' || lpad((1000 + i * 37)::text, 4, '0') || chr(64 + i),
            case when c.scheme = 'Not registered' then null
                 else '33AAX' || c.typ || 'D' || lpad((1000 + i * 37)::text, 4, '0') || chr(64 + i) || '1Z' || chr(64 + ((i * 7) % 26) + 1) end,
            case when c.tdsp or c.tdsr then 'CHED' || lpad((2000 + i * 11)::text, 5, '0') || chr(64 + i) end,
            'demo' || lpad(i::text, 2, '0') || '@example.com', '90000000' || lpad(i::text, 2, '0'), c.contact,
            c.scheme, c.svc::text[], staff[1 + (i % array_length(staff, 1))], true, true, c.tdsp, c.tdsr, true)
    returning id into cid;
    ids := ids || cid;

    -- GST: GSTR-1 and GSTR-3B for the last two months
    if c.scheme = 'Monthly' then
      for k in 0 .. 1 loop
        for r in select unnest(array['GSTR-1', 'GSTR-3B']) loop
          due := (case k when 0 then m2 else m1 end) + interval '1 month' + make_interval(days => case r when 'GSTR-1' then 10 else 19 end);
          st := case
            when k = 0 then case when i in (7, 11) and r = 'GSTR-3B' then 'Pending data' else 'Filed' end             -- 2 overdue from the older month
            when due < current_date then case when i in (5, 9, 17) then 'In progress' else 'Filed' end
            else (array['Pending data', 'In progress', 'Ready to file', 'Filed', 'Pending data'])[1 + (i % 5)] end;
          insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks,
                                    data_received_on, filed_on, fee)
          values (cid, 'GST', r, to_char(case k when 0 then m2 else m1 end, 'Mon YYYY'), due, staff[1 + (i % array_length(staff, 1))], st,
                  'Sample data', case when st <> 'Pending data' then due - 6 end,
                  case when st = 'Filed' then least(current_date, due - (i % 3)) end,
                  case when i = 3 then 1000 else null end)                                                       -- client 3 is under-charged
          on conflict (client_id, return_name, period) do nothing;
          n_task := n_task + 1;
        end loop;
      end loop;
    elsif c.scheme = 'Composition' then
      insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks, filed_on)
      values (cid, 'GST', 'CMP-08', q_lbl, q_end + 18, staff[1 + (i % array_length(staff, 1))], case when i = 15 then 'Pending data' else 'Filed' end,
              'Sample data', case when i <> 15 then q_end + 15 end)
      on conflict (client_id, return_name, period) do nothing;
      n_task := n_task + 1;
    end if;

    -- TDS payment for last month (due 7th) and the quarterly return
    if c.tdsp then
      insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks, filed_on)
      values (cid, 'TDS', 'TDS payment', to_char(m1, 'Mon YYYY'), m1 + interval '1 month' + interval '6 day', staff[1 + ((i + 1) % array_length(staff, 1))],
              case when i = 10 then 'Pending data' else 'Filed' end, 'Sample data', case when i <> 10 then (m1 + interval '1 month' + interval '5 day')::date end)
      on conflict (client_id, return_name, period) do nothing;
      n_task := n_task + 1;
    end if;
    if c.tdsr then
      for r in select unnest(case when c.typ = 'C' then array['24Q', '26Q'] else array['26Q'] end) loop
        insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks, filed_on)
        values (cid, 'TDS', r, q_lbl, q_end + 31, staff[1 + ((i + 1) % array_length(staff, 1))],
                case when i = 16 and r = '26Q' then 'Ready to file' else 'Filed' end, 'Sample data',
                case when not (i = 16 and r = '26Q') then q_end + 28 end)
        on conflict (client_id, return_name, period) do nothing;
        n_task := n_task + 1;
      end loop;
    end if;

    -- MCA annual filings for companies
    if c.typ = 'C' then
      insert into public.tasks (client_id, work_type, return_name, period, due_date, assigned_to, status, remarks, filed_on)
      values (cid, 'ROC/MCA', 'AOC-4', 'FY ' || (extract(year from current_date)::int - 1) || '-' || right(extract(year from current_date)::text, 2),
              make_date(extract(year from current_date)::int, 10, 29), staff[1 + ((i + 2) % array_length(staff, 1))],
              case when i = 12 then 'In progress' else 'Filed' end, 'Sample data', case when i <> 12 then make_date(extract(year from current_date)::int, 10, 24) end),
             (cid, 'ROC/MCA', 'MGT-7', 'FY ' || (extract(year from current_date)::int - 1) || '-' || right(extract(year from current_date)::text, 2),
              make_date(extract(year from current_date)::int, 11, 28), staff[1 + ((i + 2) % array_length(staff, 1))],
              (array['Pending data', 'In progress', 'Ready to file'])[1 + (i % 3)], 'Sample data', null)
      on conflict (client_id, return_name, period) do nothing;
      n_task := n_task + 2;
    end if;
  end loop;

  -- invoices for the older month's filed work (clients 1-8), dated the 25th; payments for most
  for k in 1 .. 8 loop
    select array_agg(id) into tids from public.tasks where client_id = ids[k] and status = 'Filed' and period = to_char(m2, 'Mon YYYY');
    if tids is null then continue; end if;
    begin
      iid := public.create_invoice(ids[k], tids, '[]'::jsonb, (m2 + interval '1 month' + interval '24 day')::date, null, 18);
      n_inv := n_inv + 1;
      select total into tot from public.invoices where id = iid;
      if k <= 5 then
        insert into public.payments (invoice_id, paid_on, amount, mode, ref)
        values (iid, least(current_date, (m2 + interval '1 month' + interval '24 day')::date + 4 + k * 3), tot, (array['UPI', 'Bank transfer'])[1 + k % 2], 'DEMO' || k);
      elsif k = 6 then
        insert into public.payments (invoice_id, paid_on, amount, mode, ref)
        values (iid, least(current_date, (m2 + interval '1 month' + interval '24 day')::date + 10), round(tot / 2), 'Cheque', 'DEMO6');
      end if;
    exception when others then
      raise notice 'invoice for demo client % skipped: %', k, sqlerrm;
    end;
  end loop;

  -- notices
  insert into public.notices (client_id, dept, notice_type, ref_no, period, notice_date, reply_due, hearing_date, amount, assigned_to, status, remarks, draft_reply, draft_at, source, auto)
  values
    (ids[2], 'GST', 'ASMT-10 (scrutiny)', 'ZD330926DEMO01', 'FY 2024-25', current_date - 9, current_date + 4, null, 184500, staff[1], 'Open',
     'Mismatch between GSTR-1 and GSTR-3B turnover for FY 2024-25. Reconciliation to be prepared.', null, null, 'Sample data', false),
    (ids[4], 'GST', 'DRC-01A (intimation)', 'ZD331026DEMO02', 'FY 2023-24', current_date - 20, current_date + 10, null, 62300, staff[1 + 1 % array_length(staff, 1)], 'Reply drafted',
     'Excess ITC claimed compared with GSTR-2B.',
     E'To\nThe Proper Officer,\n\nSub: Reply to intimation in DRC-01A for FY 2023-24\n\nWe refer to the above intimation. The difference arises from invoices of two suppliers who filed their GSTR-1 late; the credit now appears in GSTR-2B for the following month. Copies of the invoices and the supplier filings are enclosed.\n\nWe request that the proposed amount be dropped.\n\nFor Velan Logistics Pvt Ltd\nAuthorised Signatory',
     now() - interval '1 day', 'Sample data', false),
    (ids[6], 'GST', 'DRC-01 (show cause)', 'ZD330826DEMO03', 'FY 2022-23', current_date - 40, current_date - 10, current_date + 6, 215000, staff[1], 'Hearing',
     'Reply filed. Personal hearing fixed.', null, null, 'Sample data', false),
    (ids[9], 'GST', 'REG-03 (registration query)', 'ZA331126DEMO04', null, current_date - 6, current_date + 1, null, null, staff[1 + 2 % array_length(staff, 1)], 'Open',
     'Officer asks for rent agreement and electricity bill for additional place of business.', null, null, 'Sample data', false),
    (ids[10], 'TDS', 'Short payment / interest demand', 'TRACES-DEMO-05', q_lbl, current_date - 12, current_date + 18, null, 3420, staff[1], 'Open',
     'Late payment interest on 26Q.', null, null, 'Sample data', false),
    (ids[12], 'ROC/MCA', 'Other', 'ROC-CHN-DEMO06', 'FY 2024-25', current_date - 60, current_date - 30, null, null, staff[1], 'Closed',
     'Query on charge filing. Replied and closed.', null, null, 'Sample data', false);
  update public.notices set replied_on = current_date - 32 where client_id = ids[12] and source = 'Sample data';

  -- work requests (manager → team member)
  insert into public.work_requests (title, details, client_id, assigned_to, requested_by, due_date, priority, status)
  values
    ('Prepare GSTR-2B reconciliation for the scrutiny notice', 'Annai Textiles — ASMT-10 reply needs month-wise 2B vs books.', ids[2], staff[1 + 1 % array_length(staff, 1)], me, current_date + 2, 'Urgent', 'New'),
    ('Collect rent agreement and EB bill', 'For the REG-03 query of Thamarai Electricals.', ids[9], staff[1], me, current_date + 1, 'High', 'In progress'),
    ('Call client about pending October purchase bills', null, ids[7], staff[1 + 2 % array_length(staff, 1)], me, current_date + 3, 'Normal', 'New'),
    ('Send revised fee proposal', 'Kaveri Agro Foods is billed below the standard fee.', ids[3], staff[1], me, current_date - 1, 'Normal', 'Done');

  -- follow-ups on the overdue work
  insert into public.followups (kind, task_id, client_id, on_date, mode, note, promised_on, next_on, created_by)
  select 'task', t.id, t.client_id, current_date - 3, 'Phone call', 'Client said purchase bills will be sent this week.', current_date + 1, current_date + 2, me
    from public.tasks t where t.client_id in (ids[7], ids[11]) and t.status = 'Pending data' and t.return_name = 'GSTR-3B';
  insert into public.followups (kind, task_id, client_id, on_date, mode, note, next_on, created_by)
  select 'task', t.id, t.client_id, current_date - 1, 'WhatsApp', 'Reminder sent with the list of documents.', current_date + 2, me
    from public.tasks t where t.client_id = ids[10] and t.return_name = 'TDS payment';

  -- nothing is ever sent for demo clients
  delete from public.chase_log where client_id = any(ids) and status = 'queued';

  perform set_config('jlr.no_audit', '', true);
  insert into public.audit_log (user_id, user_name, area, row_id, client_id, action, summary, changes)
  values (me, public.audit_who(), 'demo', null, null, 'insert', 'Sample data loaded: 20 demo clients (DEMO-01 to DEMO-20)', '{}'::jsonb);

  return public.demo_status() || jsonb_build_object('invoices_made', n_inv);
end $function$
;

CREATE OR REPLACE FUNCTION public.demo_status()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'clients', (select count(*) from public.clients where is_demo),
    'tasks',   (select count(*) from public.tasks t join public.clients c on c.id = t.client_id where c.is_demo),
    'notices', (select count(*) from public.notices n join public.clients c on c.id = n.client_id where c.is_demo),
    'invoices',(select count(*) from public.invoices i join public.clients c on c.id = i.client_id where c.is_demo));
$function$
;

CREATE OR REPLACE FUNCTION public.dr_plan(p_day date DEFAULT NULL::date)
 RETURNS TABLE(client_id uuid, client text, contact text, to_addr text, kind text, period text, subject text, body text, already boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  d date := date_trunc('month', coalesce(p_day, public.ist_today()))::date;
  pm date := (d - interval '1 month')::date;                 -- the month the data is for
  s record; f record; t record; c record;
  mon text[] := array['January','February','March','April','May','June','July','August','September','October','November','December'];
  q int; qy int; fy text; qlabel text; qmonths text; per text; subj text; bod text; due text; dline text; rets text; reply text; portal text; site text;
  m int := extract(month from d)::int;
  fmt text := 'FMDD Mon YYYY';
begin
  select * into s from public.data_request_settings where id = 1;
  select firm_name, firm_phone into f from public.settings limit 1;
  site := coalesce(public.chase_site(), '');
  portal := site || 'portal.html';
  -- quarter just ended (for QRMP GST and TDS returns), only in Jan / Apr / Jul / Oct
  if m in (1, 4, 7, 10) then
    q := case m when 7 then 1 when 10 then 2 when 1 then 3 else 4 end;
    qy := case when m in (1, 4) then extract(year from d)::int - 1 else extract(year from d)::int end;   -- FY start year
    fy := 'FY ' || qy || '-' || right((qy + 1)::text, 2);
    qlabel := 'Q' || q;
    qmonths := case q when 1 then 'April – June' when 2 then 'July – September' when 3 then 'October – December' else 'January – March' end;
  end if;

  for c in select * from public.clients where active and not coalesce(chase_off, false) order by name loop
    -- ---- GST ----
    if 'GST' = any(c.services) and coalesce(c.gst_scheme, '') in ('Monthly', 'QRMP') and (c.gst_scheme = 'Monthly' or q is not null) then
      if c.gst_scheme = 'Monthly' then
        per := mon[extract(month from pm)::int] || ' ' || extract(year from pm)::int;
        rets := 'GSTR-1 & GSTR-3B';
        dline := 'GSTR-1 (' || to_char(make_date(extract(year from d)::int, m, 11), fmt) || ') and GSTR-3B (' || to_char(make_date(extract(year from d)::int, m, 20), fmt) || ')';
      else
        per := qlabel || ' ' || fy || ' (' || qmonths || ')';
        rets := 'GSTR-1 & GSTR-3B (quarterly)';
        dline := 'GSTR-1 (' || to_char(make_date(extract(year from d)::int, m, 13), fmt) || ') and GSTR-3B (' ||
                 to_char(make_date(extract(year from d)::int, m, case when left(coalesce(c.gstin, ''), 2) in ('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','38') then 24 else 22 end), fmt) || ')';
      end if;
      reply := to_char(make_date(extract(year from d)::int, m, least(28, greatest(1, s.gst_reply_day))), fmt);
      select t0.subject, t0.body into subj, bod from public.data_request_templates t0 where t0.kind = 'gst';
      client_id := c.id; client := c.name; contact := coalesce(nullif(c.contact_person, ''), c.name);
      to_addr := nullif(regexp_replace(lower(coalesce(c.email, '')), '[;\s]+', ',', 'g'), '');
      to_addr := nullif(trim(both ',' from regexp_replace(coalesce(to_addr, ''), ',+', ',', 'g')), '');
      kind := 'gst'; period := per;
      subject := replace(replace(replace(subj, '{returns}', rets), '{period}', per), '{client}', c.name);
      body := replace(replace(replace(replace(replace(replace(replace(replace(bod, '{contact}', contact), '{period}', per), '{due_line}', dline), '{reply_by}', reply),
              '{portal}', portal), '{firm}', coalesce(f.firm_name, '')), '{firm_phone}', coalesce(f.firm_phone, '')), '{client}', c.name);
      already := exists (select 1 from public.data_request_log l where l.client_id = c.id and l.kind = 'gst' and l.period = per);
      return next;
    end if;
    -- ---- TDS payment workings (every month) ----
    if c.tds_pay_work then
      per := mon[extract(month from pm)::int] || ' ' || extract(year from pm)::int;
      due := to_char(case when extract(month from pm) = 3 then make_date(extract(year from d)::int, 4, 30) else make_date(extract(year from d)::int, m, 7) end, fmt);
      reply := to_char(make_date(extract(year from d)::int, m, least(28, greatest(1, s.tdsp_reply_day))), fmt);
      select t0.subject, t0.body into subj, bod from public.data_request_templates t0 where t0.kind = 'tds_pay';
      client_id := c.id; client := c.name; contact := coalesce(nullif(c.contact_person, ''), c.name);
      to_addr := nullif(trim(both ',' from regexp_replace(regexp_replace(lower(coalesce(c.email, '')), '[;\s]+', ',', 'g'), ',+', ',', 'g')), '');
      kind := 'tds_pay'; period := per;
      subject := replace(replace(subj, '{period}', per), '{client}', c.name);
      body := replace(replace(replace(replace(replace(replace(replace(replace(bod, '{contact}', contact), '{period}', per), '{due}', due), '{reply_by}', reply),
              '{portal}', portal), '{firm}', coalesce(f.firm_name, '')), '{firm_phone}', coalesce(f.firm_phone, '')), '{client}', c.name);
      already := exists (select 1 from public.data_request_log l where l.client_id = c.id and l.kind = 'tds_pay' and l.period = per);
      return next;
    end if;
    -- ---- TDS return filing (after each quarter) ----
    if c.tds_return and q is not null then
      per := qlabel || ' ' || fy;
      due := to_char(case q when 1 then make_date(qy, 7, 31) when 2 then make_date(qy, 10, 31) when 3 then make_date(qy + 1, 1, 31) else make_date(qy + 1, 5, 31) end, fmt);
      reply := to_char(make_date(extract(year from d)::int, m, least(28, greatest(1, s.tdsr_reply_day))), fmt);
      select t0.subject, t0.body into subj, bod from public.data_request_templates t0 where t0.kind = 'tds_return';
      client_id := c.id; client := c.name; contact := coalesce(nullif(c.contact_person, ''), c.name);
      to_addr := nullif(trim(both ',' from regexp_replace(regexp_replace(lower(coalesce(c.email, '')), '[;\s]+', ',', 'g'), ',+', ',', 'g')), '');
      kind := 'tds_return'; period := per;
      subject := replace(replace(replace(replace(subj, '{quarter}', qlabel), '{fy}', fy), '{forms}', '140 [26Q] / 138 [24Q] / 144 [27Q] as applicable'), '{client}', c.name);
      body := replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(bod, '{contact}', contact), '{quarter}', qlabel), '{fy}', fy),
              '{quarter_months}', qmonths), '{due}', due), '{reply_by}', reply), '{portal}', portal), '{firm}', coalesce(f.firm_name, '')), '{firm_phone}', coalesce(f.firm_phone, '')), '{client}', c.name);
      already := exists (select 1 from public.data_request_log l where l.client_id = c.id and l.kind = 'tds_return' and l.period = per);
      return next;
    end if;
  end loop;
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_preview(p_client uuid, p_kind text, p_day date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r record;
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  select * into r from public.dr_plan(coalesce(p_day, (date_trunc('month', public.ist_today()) + interval '1 month')::date)) p where p.client_id = p_client and p.kind = p_kind;
  if not found then return null; end if;
  return jsonb_build_object('to', r.to_addr, 'subject', r.subject, 'body', r.body);
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_run(p_force boolean DEFAULT false, p_day date DEFAULT NULL::date)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; r record; n int := 0; cid uuid; d date := coalesce(p_day, public.ist_today());
begin
  select * into s from public.data_request_settings where id = 1;
  if not s.enabled and not p_force then return 0; end if;
  if not p_force and extract(day from d) <> 1 then return 0; end if;
  if to_regclass('public.chase_log') is null then raise exception 'Install update-session7.sql first (email queue)'; end if;
  for r in select * from public.dr_plan(d) where not already and to_addr is not null loop
    insert into public.chase_log (client_id, kind, channel, to_addr, subject, body, items, status)
    values (r.client_id, 'data_request', 'email', r.to_addr, r.subject, r.body, r.kind || ': ' || r.period, 'queued') returning id into cid;
    insert into public.data_request_log (client_id, kind, period, to_addr, chase_id) values (r.client_id, r.kind, r.period, r.to_addr, cid) on conflict do nothing;
    n := n + 1;
  end loop;
  update public.data_request_settings set last_run_at = now(),
    last_note = to_char(now() at time zone 'Asia/Kolkata', 'DD Mon HH24:MI') || ': ' || n || ' email' || case when n = 1 then '' else 's' end || ' queued' where id = 1;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_run_now()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  return public.dr_run(true, date_trunc('month', public.ist_today())::date);
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_save(p jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_partner() then raise exception 'Only a Partner or the Admin can change this'; end if;
  update public.data_request_settings set enabled = coalesce((p->>'enabled')::boolean, enabled),
    gst_reply_day = greatest(1, least(28, coalesce((p->>'gst_reply_day')::int, gst_reply_day))),
    tdsp_reply_day = greatest(1, least(28, coalesce((p->>'tdsp_reply_day')::int, tdsp_reply_day))),
    tdsr_reply_day = greatest(1, least(28, coalesce((p->>'tdsr_reply_day')::int, tdsr_reply_day))) where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_save_template(p_kind text, p_subject text, p_body text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_partner() then raise exception 'Only a Partner or the Admin can change the email text'; end if;
  if coalesce(trim(p_subject), '') = '' or coalesce(trim(p_body), '') = '' then raise exception 'Subject and text are both needed'; end if;
  update public.data_request_templates set subject = left(p_subject, 300), body = left(p_body, 20000), updated_at = now(), updated_by = auth.uid() where kind = p_kind;
  if not found then raise exception 'Unknown email'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.dr_status(p_day date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s record; d date := coalesce(p_day, (date_trunc('month', public.ist_today()) + interval '1 month')::date);
begin
  if not public.is_manager() then raise exception 'Managers only'; end if;
  select * into s from public.data_request_settings where id = 1;
  return to_jsonb(s) || jsonb_build_object(
    'next_day', d,
    'plan', (select coalesce(jsonb_agg(jsonb_build_object('client_id', p.client_id, 'client', p.client, 'kind', p.kind, 'period', p.period, 'to', p.to_addr, 'already', p.already) order by p.client, p.kind), '[]'::jsonb) from public.dr_plan(d) p),
    'this_month', (select coalesce(jsonb_agg(jsonb_build_object('client', p.client, 'kind', p.kind, 'period', p.period, 'to', p.to_addr, 'already', p.already) order by p.client, p.kind), '[]'::jsonb)
                   from public.dr_plan(date_trunc('month', public.ist_today())::date) p),
    'templates', (select coalesce(jsonb_object_agg(t.kind, jsonb_build_object('subject', t.subject, 'body', t.body, 'updated_at', t.updated_at)), '{}'::jsonb) from public.data_request_templates t),
    'sent_recent', (select count(*) from public.data_request_log where sent_at > now() - interval '35 days'));
end $function$
;

CREATE OR REPLACE FUNCTION public.followups_after()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare tid uuid := coalesce(new.task_id, old.task_id);
begin
  if tid is not null then
    update public.tasks t set
      fu_count = (select count(*) from public.followups f where f.task_id = tid),
      fu_last  = (select max(f.on_date) from public.followups f where f.task_id = tid),
      fu_next  = (select f.next_on from public.followups f where f.task_id = tid
                  order by f.on_date desc, f.created_at desc limit 1)
    where t.id = tid;
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.followups_before()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.kind = 'task' then
    select client_id into new.client_id from public.tasks where id = new.task_id;
    if new.client_id is null then raise exception 'Work item not found'; end if;
  end if;
  if auth.uid() is not null then new.created_by := auth.uid(); end if;
  if new.mode is null or btrim(new.mode) = '' then new.mode := 'Phone call'; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_board_status(p_token uuid)
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when s.id is null then null else json_build_object(
    'firm',  s.firm_name,
    'tasks', coalesce((
        select json_agg(json_build_object(
                 'client', c.name, 'work_type', t.work_type,
                 'return_name', t.return_name, 'period', t.period,
                 'due_date', t.due_date, 'status', t.status)
               order by t.due_date, c.name)
        from public.tasks t join public.clients c on c.id = t.client_id
        where c.active
          and t.status <> 'Not applicable'
          and t.due_date between current_date - 45 and current_date + 45
      ), '[]'::json)
  ) end
  from (select 1) x
  left join public.settings s on s.id = 1 and s.board_enabled and s.board_token = p_token;
$function$
;

CREATE OR REPLACE FUNCTION public.get_client_status(p_token uuid)
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when c.id is null then null else json_build_object(
    'firm',   (select firm_name from public.settings where id = 1),
    'client', json_build_object('name', c.name, 'gstin', c.gstin),
    'tasks',  coalesce((
        select json_agg(json_build_object(
                 'work_type', t.work_type, 'return_name', t.return_name,
                 'period', t.period, 'due_date', t.due_date,
                 'status', t.status, 'filed_on', t.filed_on, 'arn', t.arn,
                 'data_received_on', t.data_received_on,
                 'docs', (select coalesce(json_agg(json_build_object('name', d.name, 'received', d.received) order by d.seq, d.name), '[]'::json)
                          from public.task_docs d where d.task_id = t.id))
               order by t.due_date desc nulls last)
        from public.tasks t
        where t.client_id = c.id
          and t.status <> 'Not applicable'
          and (t.due_date is null or t.due_date >= current_date - 365)
      ), '[]'::json)
  ) end
  from (select 1) x
  left join public.clients c on c.status_token = p_token and c.active;
$function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_log(p_limit integer DEFAULT 30)
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when not public.is_admin() then null else coalesce((
    select json_agg(row_to_json(x) order by x.requested_at desc) from (
      select g.requested_at, g.processed_at, g.fy, g.status_code, g.updated_count, g.result, c.name as client, c.gstin
        from public.gst_checks g left join public.clients c on c.id = g.client_id
       order by g.requested_at desc limit p_limit) x), '[]'::json) end;
$function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_process()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare x record; n int := 0;
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  for x in select id from public.gst_checks where processed_at is null order by id loop
    n := n + public.gst_process_check(x.id);
  end loop;
  return n || ' task(s) marked Filed';
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_run(p_client uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  return public.gst_tick(p_client, p_client is null);
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  update public.gst_settings set enabled = p_enabled, start_day = greatest(1, least(31, p_start)), end_day = greatest(1, least(31, p_end)) where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_set_keys(p_key text, p_secret text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid;
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  if coalesce(trim(p_key), '') = '' or coalesce(trim(p_secret), '') = '' then raise exception 'Both API key and secret are needed'; end if;
  select id into sid from vault.secrets where name = 'sandbox_api_key';
  if sid is null then perform vault.create_secret(trim(p_key), 'sandbox_api_key', 'Sandbox API key');
  else perform vault.update_secret(sid, trim(p_key)); end if;
  select id into sid from vault.secrets where name = 'sandbox_api_secret';
  if sid is null then perform vault.create_secret(trim(p_secret), 'sandbox_api_secret', 'Sandbox API secret');
  else perform vault.update_secret(sid, trim(p_secret)); end if;
  update public.gst_settings set token = null, token_expires = null, auth_request_id = null, last_error = null where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_admin_status()
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when not public.is_admin() then null else json_build_object(
    'keys_saved', exists (select 1 from vault.secrets where name = 'sandbox_api_secret'),
    'logged_in', s.token is not null and s.token_expires > now(),
    'enabled', s.enabled, 'start_day', s.start_day, 'end_day', s.end_day,
    'last_error', s.last_error,
    'job', exists (select 1 from cron.job where jobname = 'gst-tick')
  ) end
  from public.gst_settings s where s.id = 1;
$function$
;

CREATE OR REPLACE FUNCTION public.gst_api_keys()
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select json_build_object(
    'key',    (select decrypted_secret from vault.decrypted_secrets where name = 'sandbox_api_key' limit 1),
    'secret', (select decrypted_secret from vault.decrypted_secrets where name = 'sandbox_api_secret' limit 1),
    'base_url', coalesce((select base_url from public.gst_settings where id = 1), 'https://api.sandbox.co.in'));
$function$
;

CREATE OR REPLACE FUNCTION public.gst_bill_ready(p_upto date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object('clients', count(distinct k.client_id), 'items', count(*),
    'amount', coalesce(sum(coalesce(k.fee, (select f.amount from public.fee_rates f where lower(f.return_name) = lower(k.return_name) and (f.client_id = k.client_id or f.client_id is null)
                                             order by f.client_id nulls last limit 1), 0)), 0))
  from public.tasks k
  where k.status = 'Filed' and k.invoice_id is null and k.work_type = 'GST' and (p_upto is null or coalesce(k.filed_on, k.due_date) <= p_upto)
$function$
;

CREATE OR REPLACE FUNCTION public.gst_bill_reminder()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare d date := public.ist_today(); bd int; r jsonb; toe text; site text;
begin
  select least(28, greatest(1, coalesce(gst_bill_day, 25))) into bd from public.settings limit 1;
  if extract(day from d)::int <> bd then return 0; end if;
  r := public.gst_bill_ready(d);
  if (r->>'clients')::int = 0 or to_regclass('public.chase_log') is null then return 0; end if;
  select string_agg(email, ',') into toe from public.profiles where active and role in ('admin', 'partner') and coalesce(email, '') <> '';
  if toe is null then return 0; end if;
  site := coalesce(public.chase_site(), '');
  insert into public.chase_log (kind, channel, to_addr, subject, body, items, status)
  values ('billing', 'email', toe, 'GST billing day: ' || (r->>'clients') || case when (r->>'clients') = '1' then ' client' else ' clients' end || ' ready to bill',
    'Today (' || to_char(d, 'DD Mon YYYY') || ') is the GST billing day.' || E'\n\n' ||
    (r->>'items') || ' filed GST return(s) for ' || (r->>'clients') || ' client(s) are not billed yet — about ₹' || to_char((r->>'amount')::numeric, 'FM99,99,99,990') || ' before GST.' || E'\n\n' ||
    'Open Billing → To invoice → "GST billing run" to check and create the invoices (dated today): ' || site || '#/billing' || E'\n\n— JLR Compliance Tracker',
    'GST billing', 'queued');
  return 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_fy_of(p_code text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p_code is null then null else
    'FY ' || s || '-' || right((s + 1)::text, 2) end
  from (select case when substr(p_code, 1, 2)::int >= 4 then substr(p_code, 3, 4)::int
                    else substr(p_code, 3, 4)::int - 1 end as s) x;
$function$
;

CREATE OR REPLACE FUNCTION public.gst_months_before()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare data_changed boolean := tg_op = 'UPDATE' and (new.sales, new.purchases, new.gstr2b, new.gstr3b, new.gstr1, new.g1)
                                 is distinct from (old.sales, old.purchases, old.gstr2b, old.gstr3b, old.gstr1, old.g1);
begin
  new.period := date_trunc('month', new.period)::date;
  new.updated_at := now();
  if auth.uid() is not null then new.updated_by := auth.uid(); end if;
  if data_changed and old.status = 'Verified' then
    new.status := 'Draft';
  elsif auth.uid() is not null and not public.is_manager()
     and new.status is distinct from (case when tg_op = 'INSERT' then 'Draft' else old.status end) then
    raise exception 'Only a manager, partner or admin can mark GST data as verified';
  end if;
  if new.status = 'Verified' and (tg_op = 'INSERT' or old.status is distinct from 'Verified') then
    new.verified_by := auth.uid(); new.verified_at := now();
  end if;
  if new.status = 'Draft' then new.verified_by := null; new.verified_at := null; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_period_code(p_period text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
  p  text := trim(coalesce(p_period, ''));
  m  text[];
  mon int; yr int; q int;
begin
  m := regexp_match(p, '^([A-Za-z]{3})[a-z]*\s+(\d{4})$');
  if m is not null then
    mon := (array_position(array['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'], lower(m[1])));
    if mon is null then return null; end if;
    return lpad(mon::text, 2, '0') || m[2];
  end if;
  m := regexp_match(p, '^Q([1-4])\s+FY\s+(\d{4})-\d{2}$');
  if m is not null then
    q := m[1]::int; yr := m[2]::int;
    return case q when 1 then '06' || yr when 2 then '09' || yr when 3 then '12' || yr else '03' || (yr + 1) end;
  end if;
  m := regexp_match(p, '^FY\s+(\d{4})-\d{2}$');
  if m is not null then
    return '03' || (m[1]::int + 1);
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_process_check(p_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  c     public.gst_checks;
  r     record;
  js    jsonb;
  lst   jsonb;
  e     jsonb;
  n     int := 0;
  k     int;
  msg   text;
begin
  select * into c from public.gst_checks where id = p_id;
  if c.id is null or c.processed_at is not null then return 0; end if;
  select status_code, content, error_msg into r from net._http_response where id = c.request_id;
  if not found then
    if c.requested_at < now() - interval '3 minutes' then
      update public.gst_checks set processed_at = now(), result = 'No reply from Sandbox (timed out)' where id = p_id;
    end if;
    return 0;
  end if;
  begin js := r.content::jsonb; exception when others then js := null; end;
  if r.status_code between 200 and 299 and js is not null then
    lst := js #> '{data,data,EFiledlist}';
    if lst is null or jsonb_typeof(lst) <> 'array' then
      msg := coalesce(js #>> '{data,error,message}', js #>> '{data,message}', 'No filed returns found');
      update public.gst_checks set processed_at = now(), status_code = r.status_code, updated_count = 0, result = left(msg, 300) where id = p_id;
      return 0;
    end if;
    for e in select * from jsonb_array_elements(lst) loop
      continue when coalesce(e->>'status', '') !~* 'filed' or coalesce(e->>'valid', 'Y') = 'N';
      update public.tasks t
         set status   = 'Filed',
             arn      = coalesce(nullif(t.arn, ''), e->>'arn'),
             filed_on = coalesce(to_date(e->>'dof', 'DD-MM-YYYY'), current_date),
             remarks  = trim(both ' ' from coalesce(t.remarks, '') || ' [Auto: filed on GST portal]')
       where t.client_id = c.client_id
         and t.work_type = 'GST'
         and t.status not in ('Filed', 'Not applicable')
         and public.gst_rtn_code(t.return_name) = upper(regexp_replace(coalesce(e->>'rtntype', ''), '[^A-Za-z0-9]', '', 'g'))
         and public.gst_period_code(t.period) = e->>'ret_prd';
      get diagnostics k = row_count;
      n := n + k;
    end loop;
    update public.gst_checks set processed_at = now(), status_code = r.status_code, updated_count = n,
      result = jsonb_array_length(lst) || ' filed return(s) on portal; ' || n || ' task(s) marked Filed' where id = p_id;
  else
    msg := coalesce(js #>> '{data,error,message}', js #>> '{message}', r.error_msg, left(r.content, 200), 'Error');
    update public.gst_checks set processed_at = now(), status_code = r.status_code, updated_count = 0, result = left(msg, 300) where id = p_id;
  end if;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_reviews_guard()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if current_setting('jlr.review_ok', true) = '1' then return new; end if;
  if new.state = 'approved' and (tg_op = 'INSERT' or old.state is distinct from 'approved') then
    -- the senior (or a manager) approving inside the tracker goes through review_decide_staff()
    raise exception 'Only the senior can approve — use the link in the email or "Approve" in the tracker.';
  end if;
  new.updated_at := now(); return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.gst_rtn_code(p_name text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when n like 'IFF%'     then 'GSTR1'
    when n like 'GSTR3B%'  then 'GSTR3B'
    when n like 'GSTR9C%'  then 'GSTR9C'
    when n like 'GSTR9%'   then 'GSTR9'
    when n like 'GSTR1%'   then 'GSTR1'
    when n like 'GSTR4%'   then 'GSTR4'
    when n like 'GSTR7%'   then 'GSTR7'
    when n like 'GSTR8%'   then 'GSTR8'
    when n like 'CMP08%'   then 'CMP08'
    else null end
  from (select upper(regexp_replace(coalesce(p_name, ''), '[^A-Za-z0-9]', '', 'g')) as n) x;
$function$
;

CREATE OR REPLACE FUNCTION public.gst_tick(p_force_client uuid DEFAULT NULL::uuid, p_force_all boolean DEFAULT false)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s      public.gst_settings;
  k_key  text; k_sec text;
  r      record;
  js     jsonb;
  req    bigint;
  ist    timestamp := now() at time zone 'Asia/Kolkata';
  sent   int := 0;
  done   int := 0;
  x      record;
begin
  for x in select id from public.gst_checks where processed_at is null order by id loop
    done := done + public.gst_process_check(x.id);
  end loop;

  select * into s from public.gst_settings where id = 1 for update;
  select decrypted_secret into k_key from vault.decrypted_secrets where name = 'sandbox_api_key' limit 1;
  select decrypted_secret into k_sec from vault.decrypted_secrets where name = 'sandbox_api_secret' limit 1;
  if k_key is null or k_sec is null then return 'Sandbox API key/secret not saved'; end if;
  if p_force_client is null and not p_force_all and not s.enabled then return 'Automatic checks are switched off'; end if;

  if s.token is null or s.token_expires < now() + interval '10 minutes' then
    if s.auth_request_id is not null then
      select status_code, content, error_msg into r from net._http_response where id = s.auth_request_id;
      if found then
        begin js := r.content::jsonb; exception when others then js := null; end;
        if r.status_code between 200 and 299 and js #>> '{data,access_token}' is not null then
          update public.gst_settings set token = js #>> '{data,access_token}', token_expires = now() + interval '23 hours',
                 auth_request_id = null, last_error = null where id = 1;
          s.token := js #>> '{data,access_token}'; s.token_expires := now() + interval '23 hours';
        else
          update public.gst_settings set auth_request_id = null,
                 last_error = left('Login to Sandbox failed: ' || coalesce(js #>> '{message}', r.error_msg, r.content, '?'), 300) where id = 1;
          return 'Login to Sandbox failed - check API key/secret';
        end if;
      elsif s.auth_requested > now() - interval '2 minutes' then
        return 'Logging in to Sandbox... try again in a minute';
      else
        update public.gst_settings set auth_request_id = null where id = 1;
        s.auth_request_id := null;
      end if;
    end if;
    if s.token is null or s.token_expires < now() + interval '10 minutes' then
      select net.http_post(
        url := s.base_url || '/authenticate',
        headers := jsonb_build_object('x-api-key', k_key, 'x-api-secret', k_sec, 'x-api-version', '1.0.0', 'Content-Type', 'application/json'),
        body := '{}'::jsonb,
        timeout_milliseconds := 20000) into req;
      update public.gst_settings set auth_request_id = req, auth_requested = now() where id = 1;
      return 'Logging in to Sandbox... try again in a minute';
    end if;
  end if;

  if p_force_client is null and not p_force_all then
    if not s.enabled then return 'Automatic checks are switched off'; end if;
    if extract(day from ist) < s.start_day or extract(day from ist) > s.end_day then return 'Outside check days'; end if;
    if extract(hour from ist) < 8 or extract(hour from ist) >= 21 then return 'Outside check hours (8 AM - 9 PM)'; end if;
  end if;

  for x in
    select q.client_id, q.fy, q.gstin from (
      select t.client_id, public.gst_fy_of(public.gst_period_code(t.period)) as fy, max(c.gstin) as gstin
        from public.tasks t join public.clients c on c.id = t.client_id
       where c.active and c.gstin ~ '^[0-9]{2}[A-Z0-9]{13}$'
         and t.work_type = 'GST' and t.status not in ('Filed', 'Not applicable')
         and public.gst_rtn_code(t.return_name) is not null
         and public.gst_period_code(t.period) is not null
         and (p_force_client is null or t.client_id = p_force_client)
         and (p_force_client is not null or p_force_all or t.due_date is null or t.due_date <= (ist::date + 3))
       group by 1, 2) q
     where p_force_client is not null or p_force_all or not exists (
       select 1 from public.gst_checks g where g.client_id = q.client_id and g.fy = q.fy
          and (g.requested_at at time zone 'Asia/Kolkata')::date = ist::date)
     limit 40
  loop
    select net.http_post(
      url := s.base_url || '/gst/compliance/public/gstrs/track',
      params := jsonb_build_object('financial_year', x.fy),
      headers := jsonb_build_object('authorization', s.token, 'x-api-key', k_key, 'x-api-version', '1.0', 'Content-Type', 'application/json'),
      body := jsonb_build_object('gstin', x.gstin),
      timeout_milliseconds := 20000) into req;
    insert into public.gst_checks (client_id, fy, request_id) values (x.client_id, x.fy, req);
    sent := sent + 1;
  end loop;
  return format('%s check(s) sent, %s task(s) auto-filed', sent, done);
end $function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.raw_user_meta_data->>'kind' = 'client' then
    insert into public.client_users (user_id, client_id, name, email, created_by)
    values (new.id, (new.raw_user_meta_data->>'client_id')::uuid, new.raw_user_meta_data->>'full_name', new.email,
            nullif(new.raw_user_meta_data->>'created_by', '')::uuid)
    on conflict (user_id) do nothing;
    return new;
  end if;
  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
          case when exists (select 1 from public.profiles) then 'staff' else 'admin' end)
  on conflict (id) do nothing;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_manager()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'partner', 'manager') and active);
$function$
;

CREATE OR REPLACE FUNCTION public.is_member()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.profiles where id = auth.uid() and active);
$function$
;

CREATE OR REPLACE FUNCTION public.is_partner()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('admin', 'partner') and active);
$function$
;

CREATE OR REPLACE FUNCTION public.ist_today()
 RETURNS date
 LANGUAGE sql
 STABLE
AS $function$ select (now() at time zone 'Asia/Kolkata')::date $function$
;

CREATE OR REPLACE FUNCTION public.law_updates_before()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then new.created_by := coalesce(new.created_by, auth.uid()); end if;
  if new.status = 'published' and (tg_op = 'INSERT' or old.status <> 'published') then new.published_at := now(); end if;
  if new.status = 'draft' then new.published_at := null; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.login_delete(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.client_logins;
begin
  if not public.is_manager() then raise exception 'Only a manager or above can delete logins'; end if;
  select * into r from public.client_logins where id = p_id;
  if r.id is null then return; end if;
  insert into public.login_access_log(login_id, client_id, portal, user_id, action) values (null, r.client_id, r.portal || ' · ' || r.login_id, auth.uid(), 'delete');
  delete from public.client_logins where id = p_id;     -- trigger below removes the encrypted secret
end $function$
;

CREATE OR REPLACE FUNCTION public.login_reveal(p_id uuid, p_action text DEFAULT 'view'::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.client_logins; pw text;
begin
  select * into r from public.client_logins where id = p_id;
  if r.id is null or not public.can_client_login(r.client_id) then raise exception 'Not allowed'; end if;
  if r.secret_id is null then return null; end if;
  select decrypted_secret into pw from vault.decrypted_secrets where id = r.secret_id;
  insert into public.login_access_log(login_id, client_id, portal, user_id, action)
  values (r.id, r.client_id, r.portal, auth.uid(), case when p_action = 'copy' then 'copy' else 'view' end);
  return pw;
end $function$
;

CREATE OR REPLACE FUNCTION public.login_save(p_id uuid, p_client uuid, p_portal text, p_login text, p_password text, p_url text, p_otp text, p_notes text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.client_logins; sid uuid; nid uuid;
begin
  if p_id is not null then
    select * into r from public.client_logins where id = p_id;
    if r.id is null then raise exception 'Login not found'; end if;
    p_client := r.client_id;
  end if;
  if not public.can_client_login(p_client) then raise exception 'Not allowed'; end if;
  if coalesce(btrim(p_portal), '') = '' or coalesce(btrim(p_login), '') = '' then raise exception 'Portal and login ID are required'; end if;
  if p_password is not null and length(p_password) > 200 then raise exception 'Password is too long'; end if;
  if p_id is null then
    if p_password is not null and p_password <> '' then
      sid := vault.create_secret(p_password, 'login_' || gen_random_uuid(), 'Client portal login');
    end if;
    insert into public.client_logins(client_id, portal, login_id, url, otp_contact, notes, secret_id, pw_changed_on, updated_by)
    values (p_client, btrim(p_portal), btrim(p_login), nullif(btrim(p_url), ''), nullif(btrim(p_otp), ''), nullif(btrim(p_notes), ''),
            sid, case when sid is not null then current_date end, auth.uid())
    returning id into nid;
    insert into public.login_access_log(login_id, client_id, portal, user_id, action) values (nid, p_client, p_portal, auth.uid(), 'add');
    return nid;
  end if;
  sid := r.secret_id;
  if p_password is not null and p_password <> '' then
    if sid is null then sid := vault.create_secret(p_password, 'login_' || gen_random_uuid(), 'Client portal login');
    else perform vault.update_secret(sid, p_password); end if;
  end if;
  update public.client_logins set portal = btrim(p_portal), login_id = btrim(p_login), url = nullif(btrim(p_url), ''),
         otp_contact = nullif(btrim(p_otp), ''), notes = nullif(btrim(p_notes), ''), secret_id = sid,
         pw_changed_on = case when p_password is not null and p_password <> '' then current_date else pw_changed_on end,
         updated_at = now(), updated_by = auth.uid()
   where id = p_id;
  insert into public.login_access_log(login_id, client_id, portal, user_id, action)
  values (p_id, r.client_id, p_portal, auth.uid(), case when p_password is not null and p_password <> '' then 'change password' else 'edit' end);
  return p_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.mail_admin_save(p_enabled boolean, p_filter text, p_mailbox text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only an admin can change mail settings'; end if;
  update public.mail_settings set enabled = p_enabled, subject_filter = nullif(btrim(p_filter), ''), mailbox = nullif(btrim(p_mailbox), '') where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.mail_admin_set_key(p_hash text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only an admin can change the mail key'; end if;
  if p_hash !~ '^[0-9a-f]{64}$' then raise exception 'Bad key'; end if;
  update public.mail_settings set key_hash = p_hash, key_set_at = now() where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.mail_admin_status()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.mail_settings;
begin
  if not public.is_admin() then raise exception 'Only an admin can see mail settings'; end if;
  select * into s from public.mail_settings where id = 1;
  return json_build_object('enabled', s.enabled, 'key_set', s.key_hash is not null, 'key_set_at', s.key_set_at,
    'subject_filter', s.subject_filter, 'mailbox', s.mailbox, 'last_mail_at', s.last_mail_at, 'last_error', s.last_error,
    'today', (select count(*) from public.mail_inbox where received_at >= current_date),
    'new', (select count(*) from public.mail_inbox where status = 'New'));
end $function$
;

CREATE OR REPLACE FUNCTION public.mail_job_done(p_key text, p_id bigint, p_ok boolean, p_error text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.mailjob_key_ok(p_key) then raise exception 'Bad key'; end if;
  update public.mail_jobs set tries = tries + 1, status = case when p_ok then 'sent' when tries + 1 >= 5 then 'failed' else 'new' end,
         sent_at = case when p_ok then now() else sent_at end, error = case when p_ok then null else left(p_error, 300) end
   where id = p_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.mail_jobs_due(p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare res jsonb;
begin
  if not public.mailjob_key_ok(p_key) then raise exception 'Bad key'; end if;
  update public.settings set mailjob_seen_at = now() where id = 1;
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'to', to_addr, 'cc', cc, 'subject', subject, 'body', body, 'html', html, 'files', files) order by id), '[]'::jsonb) into res
  from (select * from public.mail_jobs where status = 'new' and tries < 5 order by id limit 10) j;
  return res;
end $function$
;

CREATE OR REPLACE FUNCTION public.mailjob_key_ok(p_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(length(p_key) >= 20 and encode(sha256(convert_to(p_key, 'UTF8')), 'hex') = (select mailjob_key_hash from public.settings where id = 1), false)
$function$
;

CREATE OR REPLACE FUNCTION public.my_client_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select client_id from public.client_users where user_id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.notice_admin_save(p jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Admin only'; end if;
  update public.notice_watch set enabled = coalesce((p->>'enabled')::boolean, enabled), alert_email = coalesce((p->>'alert_email')::boolean, alert_email),
    alert_wa = coalesce((p->>'alert_wa')::boolean, alert_wa), wa_template = coalesce(nullif(p->>'wa_template', ''), wa_template),
    every_minutes = greatest(5, least(240, coalesce((p->>'every_minutes')::int, every_minutes))) where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_admin_set_key(p_hash text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Admin only'; end if;
  if p_hash !~ '^[0-9a-f]{64}$' then raise exception 'Bad key'; end if;
  update public.notice_watch set key_hash = p_hash, key_set_at = now() where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_checked(p_key text, p_found integer, p_error text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.nw_key_ok(p_key) then return; end if;
  update public.notice_watch set last_check_at = now(), last_found = p_found, last_error = p_error where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_client(p jsonb, p_from text)
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare id uuid; frm text := lower(coalesce((regexp_match(coalesce(p_from, ''), '([A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+)'))[1], ''));
        firm record;
begin
  select upper(coalesce(firm_gstin, '')) g, upper(coalesce(firm_pan, '')) pn into firm from public.settings limit 1;
  if p->>'gstin' is not null and p->>'gstin' <> coalesce(firm.g, '') then
    select c.id into id from public.clients c where upper(c.gstin) = p->>'gstin' and c.active limit 1; if id is not null then return id; end if; end if;
  if p->>'tan' is not null then select c.id into id from public.clients c where upper(c.tan) = p->>'tan' and c.active limit 1; if id is not null then return id; end if; end if;
  if p->>'cin' is not null then select c.id into id from public.clients c where upper(c.cin) = p->>'cin' and c.active limit 1; if id is not null then return id; end if; end if;
  if p->>'pan' is not null and p->>'pan' <> coalesce(firm.pn, '') then
    select c.id into id from public.clients c where c.active and (upper(c.pan) = p->>'pan' or substr(upper(coalesce(c.gstin, '')), 3, 10) = p->>'pan') limit 1; if id is not null then return id; end if; end if;
  if frm <> '' and frm !~ '\.gov\.in$' then
    select c.id into id from public.clients c where c.active and frm = any(string_to_array(regexp_replace(lower(coalesce(c.email, '')), '\s', '', 'g'), ',')) limit 1;
    if id is null then select c.id into id from public.clients c where c.active and lower(coalesce(c.email, '')) like '%' || frm || '%' limit 1; end if;
  end if;
  return id;
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_digest(p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare t date := public.ist_today();
begin
  if not public.nw_key_ok(p_key) then return null; end if;
  return jsonb_build_object(
    'emails', (select coalesce(jsonb_agg(email), '[]') from public.profiles where active and role in ('admin', 'partner', 'manager') and coalesce(email, '') <> ''),
    'new', (select coalesce(jsonb_agg(jsonb_build_object('client', c.name, 'dept', n.dept, 'type', n.notice_type, 'ref', n.ref_no, 'due', n.reply_due) order by n.created_at), '[]')
              from public.notices n join public.clients c on c.id = n.client_id where n.created_at > now() - interval '12 hours'),
    'due', (select coalesce(jsonb_agg(jsonb_build_object('client', c.name, 'dept', n.dept, 'type', n.notice_type, 'due', n.reply_due, 'late', n.reply_due < t,
                     'staff', (select full_name from public.profiles where id = n.assigned_to)) order by n.reply_due), '[]')
              from public.notices n join public.clients c on c.id = n.client_id where n.status in ('Open', 'Reply drafted') and n.reply_due <= t + 7),
    'unmatched', (select count(*) from public.notice_mails where result = 'unmatched'));
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_intake(p_key text, p_mail jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p jsonb; cid uuid; nid uuid; cl record; dup uuid; res text; rd date; dt date; wa int := 0; recips text[];
begin
  if not public.nw_key_ok(p_key) then return jsonb_build_object('result', 'disabled'); end if;
  if exists (select 1 from public.notice_mails where mail_id = p_mail->>'id') then return jsonb_build_object('result', 'seen'); end if;
  dt := ((p_mail->>'date')::timestamptz at time zone 'Asia/Kolkata')::date;
  p := public.notice_parse(p_mail->>'from', p_mail->>'subject', p_mail->>'body', dt);
  if not (p->>'is_notice')::boolean then
    insert into public.notice_mails (mail_id, received_at, sender, subject, excerpt, result, note) values (p_mail->>'id', (p_mail->>'date')::timestamptz, p_mail->>'from', p_mail->>'subject', left(p_mail->>'body', 600), 'ignored', 'Not a notice (OTP, acknowledgement, receipt…)');
    return jsonb_build_object('result', 'ignored');
  end if;
  cid := public.notice_client(p, p_mail->>'from');
  rd := (p->>'reply_due')::date;
  if cid is not null then
    select n.id into dup from public.notices n where n.client_id = cid and (
      (p->>'ref_no' is not null and n.ref_no = p->>'ref_no') or (n.notice_type = p->>'notice_type' and n.notice_date between dt - 3 and dt + 3)) limit 1;
  end if;
  if cid is null then res := 'unmatched';
  elsif dup is not null then res := 'duplicate'; nid := dup;
  else
    select * into cl from public.clients where id = cid;
    insert into public.notices (client_id, dept, notice_type, ref_no, period, notice_date, reply_due, amount, assigned_to, status, remarks, source, mail_id, auto)
    values (cid, p->>'dept', p->>'notice_type', p->>'ref_no', p->>'period', dt, rd, nullif(p->>'amount', '')::numeric, cl.default_staff, 'Open',
            'Added automatically from the email "' || left(coalesce(p_mail->>'subject', ''), 150) || '"' ||
            case when not (p->>'due_found')::boolean then ' — reply date not found in the email, please fill it in' else '' end ||
            case when not (p->>'type_found')::boolean then ' — check the notice type' else '' end, 'email', p_mail->>'id', true)
    returning id into nid;
    res := 'created';
    begin wa := public.notice_wa_alert(case p->>'dept' when 'ROC/MCA' then 'MCA' else p->>'dept' end, cl.name, p->>'notice_type' || coalesce(' ' || (p->>'ref_no'), ''), to_char(rd, 'DD Mon YYYY'));
    exception when others then wa := 0; end;
  end if;
  insert into public.notice_mails (mail_id, received_at, sender, subject, excerpt, dept, notice_type, ref_no, period, reply_due, amount, client_id, notice_id, result, wa_sent, note)
  values (p_mail->>'id', (p_mail->>'date')::timestamptz, p_mail->>'from', p_mail->>'subject', left(p_mail->>'body', 600), p->>'dept', p->>'notice_type', p->>'ref_no', p->>'period', rd,
          nullif(p->>'amount', '')::numeric, cid, nid, res, wa, case when res = 'unmatched' then 'No client found for ' || coalesce(p->>'gstin', p->>'tan', p->>'cin', p->>'pan', 'this sender') end);
  select array_agg(email) into recips from public.profiles where active and role in ('admin', 'partner', 'manager') and coalesce(email, '') <> '';
  return jsonb_build_object('result', res, 'notice_id', nid, 'dept', p->>'dept', 'notice_type', p->>'notice_type', 'ref_no', p->>'ref_no', 'reply_due', rd,
    'client', (select name from public.clients where id = cid), 'emails', coalesce(to_jsonb(recips), '[]'::jsonb), 'alert_email', (select alert_email from public.notice_watch where id = 1));
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_parse(p_from text, p_subject text, p_body text, p_date date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
  frm text := lower(coalesce(p_from, ''));
  subj text := coalesce(p_subject, '');
  txt text := coalesce(p_subject, '') || E'\n' || left(coalesce(p_body, ''), 20000);
  low text := lower(txt);
  portal text; dept text; ntype text; ref text; per text; due date; amt numeric; m text[]; days int;
  gstin text; pan text; tan text; cin text; is_notice boolean; dflt int;
  nd date := coalesce(p_date, public.ist_today());
begin
  portal := case when frm ~ '(gst\.gov\.in|gstn\.org\.in)' then 'GST'
                 when frm ~ '(tdscpc\.gov\.in|traces)' then 'TRACES'
                 when frm ~ '(incometax\.gov\.in|insight\.gov\.in|incometaxindia)' then 'IT'
                 when frm ~ '(mca\.gov\.in)' then 'MCA' else null end;
  gstin := (regexp_match(upper(txt), '\m(\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z])\M'))[1];
  tan   := (regexp_match(upper(txt), '\m([A-Z]{4}\d{5}[A-Z])\M'))[1];
  cin   := coalesce((regexp_match(upper(txt), '\m([UL]\d{5}[A-Z]{2}\d{4}[A-Z]{3}\d{6})\M'))[1], (regexp_match(upper(txt), '\m([A-Z]{3}-\d{4})\M'))[1]);
  pan   := coalesce((regexp_match(upper(txt), '\m([A-Z]{3}[PCHFATBLJG][A-Z]\d{4}[A-Z])\M'))[1], substr(gstin, 3, 10));

  -- type
  m := regexp_match(upper(txt), '\m(ASMT|DRC|REG|RFD|ADT|MOV|CMP|PMT|GSTR)[\s-]?0?(\d{1,2}[A-Z]?)\M');
  if m is not null and m[1] = 'GSTR' and m[2] not in ('3A') then m := null; end if;
  if m is not null then ntype := m[1] || '-' || lpad(regexp_replace(m[2], '[A-Z]$', ''), 2, '0') || coalesce((regexp_match(m[2], '[A-Z]$'))[1], '');
    if m[1] = 'GSTR' then ntype := 'GSTR-3A (non-filer notice)'; end if;
  end if;
  if ntype is null then
    m := regexp_match(low, '(?:u/s\.?|under section|sec(?:tion)?\.?)\s*(\d{3}[a-z]?(?:\(\d+[a-z]?\))?(?:\([a-z]+\))?)');
    if m is not null then ntype := 'Notice u/s ' || m[1]; end if;
  end if;
  if ntype is null and low ~ 'short payment|short deduction|late filing|late deduction|interest on late' then
    ntype := 'TDS default (' || coalesce((regexp_match(low, '(short payment|short deduction|late filing|late deduction|interest on late \w+)'))[1], 'default') || ')';
  end if;
  if ntype is null and upper(txt) ~ '\mSTK-?\d' then ntype := 'STK-' || (regexp_match(upper(txt), 'STK-?(\d)'))[1]; end if;
  if ntype is null and low ~ 'adjudicat' then ntype := 'Adjudication notice'; end if;
  if ntype is null and low ~ 'show cause' then ntype := 'Show cause notice'; end if;

  is_notice := (ntype is not null) or low ~ '(\mnotice\M|show cause|\mscn\M|scrutiny|discrepanc|demand|intimation u/s|e-?proceeding|hearing|non-?compliance|default|penalty|adjudicat|query raised|clarification)';
  -- not notices: OTPs, filing acknowledgements, receipts, newsletters
  if ntype is null and (low ~ '(one time password|\motp\M|verification code|successfully filed|filed successfully|has been filed|acknowledg(e)?ment (number|no)|payment (was |has been )?(successful|received)|challan .{0,20}generated|refund (has been )?(issued|credited|paid)|newsletter|webinar|password|login alert|registration certificate|has been approved)'
                        or subj ~* '^(re:\s*)?(otp|acknowledg)') then is_notice := false; end if;
  if portal is null and ntype is null and not (low ~ '(\mnotice\M|show cause|\mscn\M)') then is_notice := false; end if;   -- forwarded by a client: needs the word "notice"

  dept := case
    when portal = 'GST' or ntype ~ '^(ASMT|DRC|REG|RFD|ADT|MOV|CMP|PMT|GSTR)' then 'GST'
    when portal = 'TRACES' or ntype ~ '^TDS' or (portal = 'IT' and (tan is not null or low ~ '\m(tds|tcs|26q|24q|27q|27eq|tan)\M')) then 'TDS'
    when portal = 'MCA' or ntype ~ '^(STK|Adjudication)' or cin is not null and portal is null and low ~ '(roc|registrar of companies|mca)' then 'ROC/MCA'
    when gstin is not null and portal is null and low ~ '\mgst\M' then 'GST'
    else 'Other' end;

  ref := (regexp_match(txt, '(?:DIN|Document Identification Number|Reference\s*(?:No\.?|Number|ID)|Ref\.?\s*No\.?|Notice\s*(?:No\.?|Number)|SCN\s*No\.?)\s*[:.\-]*\s*([A-Z0-9][A-Z0-9/\-]{6,40})', 'i'))[1];

  m := regexp_match(upper(txt), '\m(Q[1-4])\s*(?:OF\s*)?(?:FY\s*)?(20\d{2}-\d{2})'); if m is not null then per := m[1] || ' FY ' || m[2]; end if;
  if per is null then
  m := regexp_match(txt, '(?:F\.?Y\.?|Financial Year|A\.?Y\.?|Assessment Year)\s*[:\-]?\s*(20\d{2})\s*[-–/]\s*(\d{2,4})', 'i');
  if m is not null then per := case when txt ~* '(A\.?Y\.?|Assessment Year)\s*[:\-]?\s*20\d{2}' then 'AY ' else 'FY ' end || m[1] || '-' || right(m[2], 2); end if;
  if per is null then
    m := regexp_match(txt, '(?:Tax\s*Period|Period)\s*[:\-]?\s*([A-Za-z]{3,9}[\s,-]*\d{4}(?:\s*(?:to|-|–)\s*[A-Za-z]{3,9}[\s,-]*\d{4})?)', 'i');
    if m is not null then per := initcap(m[1]); end if;
  end if;
  end if;

  m := regexp_match(txt, '(?:on or before|latest by|not later than|before|by|due date[^0-9]{0,20}|within the due date of)\s*:?\s*(\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}|\d{1,2}(?:st|nd|rd|th)?[\s-]+[A-Za-z]{3,9}[\s,.-]+\d{4})', 'i');
  if m is not null then due := public.np_date(m[1]); end if;
  if due is null or due < nd then
    days := (regexp_match(low, 'within\s+(\d{1,3})\s*(?:\(\w+\)\s*)?(?:working\s+)?days'))[1]::int;
    if days is not null then due := nd + days; end if;
  end if;
  if due is null then
    dflt := case when ntype in ('ASMT-10', 'DRC-01', 'DRC-01A', 'ADT-01') then 30 when ntype in ('REG-03', 'REG-17', 'REG-23') then 7
                 when ntype like 'GSTR-3A%' then 15 when ntype like 'Notice u/s 139(9)%' or ntype like 'Notice u/s 142%' then 15
                 when ntype like 'Notice u/s 143(1)%' or ntype like 'Notice u/s 148%' or ntype like 'Notice u/s 245%' then 30 else null end;
    if dflt is not null then due := nd + dflt; end if;
  end if;

  select max(regexp_replace(x[1], ',', '', 'g')::numeric) into amt
    from regexp_matches(txt, '(?:Rs\.?|INR|₹)\s*([0-9][0-9,]*(?:\.\d{1,2})?)', 'gi') as x;

  return jsonb_build_object('portal', portal, 'is_notice', coalesce(is_notice, false), 'dept', dept, 'notice_type', coalesce(ntype, left(regexp_replace(subj, '^(re|fw|fwd)\s*:\s*', '', 'i'), 80)),
    'type_found', ntype is not null, 'ref_no', ref, 'period', per, 'reply_due', due, 'due_found', due is not null, 'amount', amt,
    'gstin', gstin, 'pan', pan, 'tan', tan, 'cin', cin, 'notice_date', nd);
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_poll(p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare w record;
begin
  if not public.nw_key_ok(p_key) then return jsonb_build_object('run', false, 'enabled', false); end if;
  select * into w from public.notice_watch where id = 1;
  return jsonb_build_object('enabled', true, 'run', w.last_check_at is null or coalesce(w.check_requested_at > w.last_check_at, false) or w.last_check_at < now() - make_interval(mins => w.every_minutes));
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_request_check()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'Sign in'; end if;
  update public.notice_watch set check_requested_at = now() where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_status()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare w record;
begin
  if auth.uid() is null then raise exception 'Sign in'; end if;
  select * into w from public.notice_watch where id = 1;
  return jsonb_build_object('enabled', w.enabled, 'connected', w.key_hash is not null, 'key_set_at', w.key_set_at, 'last_check_at', w.last_check_at, 'last_found', w.last_found,
    'last_error', w.last_error, 'check_requested_at', w.check_requested_at, 'alert_email', w.alert_email, 'alert_wa', w.alert_wa, 'wa_template', w.wa_template, 'every_minutes', w.every_minutes,
    'unmatched', case when public.is_manager() then (select count(*) from public.notice_mails where result = 'unmatched') else 0 end);
end $function$
;

CREATE OR REPLACE FUNCTION public.notice_wa_alert(p_dept text, p_client text, p_what text, p_due text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare w record; s record; tok text; n int := 0; p record; url text;
begin
  select * into s from public.notice_watch where id = 1;
  if not coalesce(s.alert_wa, false) then return 0; end if;
  select * into w from public.wa_settings limit 1;
  if w.phone_number_id is null then return 0; end if;
  select decrypted_secret into tok from vault.decrypted_secrets where name = 'whatsapp_token' limit 1;
  if tok is null then return 0; end if;
  url := 'https://graph.facebook.com/' || coalesce(w.api_version, 'v25.0') || '/' || w.phone_number_id || '/messages';
  for p in select * from public.profiles where active and role in ('admin', 'partner', 'manager') and coalesce(phone, '') <> '' loop
    perform net.http_post(url := url,
      headers := jsonb_build_object('Authorization', 'Bearer ' || tok, 'Content-Type', 'application/json'),
      body := jsonb_build_object('messaging_product', 'whatsapp', 'to', regexp_replace(p.phone, '\D', '', 'g'), 'type', 'template',
        'template', jsonb_build_object('name', s.wa_template, 'language', jsonb_build_object('code', coalesce(w.template_lang, 'en')),
          'components', jsonb_build_array(jsonb_build_object('type', 'body', 'parameters', jsonb_build_array(
            jsonb_build_object('type', 'text', 'text', left(p_dept, 30)), jsonb_build_object('type', 'text', 'text', left(p_client, 60)),
            jsonb_build_object('type', 'text', 'text', left(p_what, 120)), jsonb_build_object('type', 'text', 'text', coalesce(p_due, 'not stated')),
            jsonb_build_object('type', 'text', 'text', coalesce(w.app_url, 'the tracker'))))))),
      timeout_milliseconds := 20000);
    n := n + 1;
  end loop;
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.notices_before()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'UPDATE' and not public.is_manager() and auth.uid() is not null then
    new.client_id := old.client_id; new.assigned_to := old.assigned_to; new.dept := old.dept;
    new.notice_type := old.notice_type; new.reply_due := old.reply_due; new.amount := old.amount;
  end if;
  if new.status = 'Replied' and new.replied_on is null then new.replied_on := (now() at time zone 'Asia/Kolkata')::date; end if;
  new.updated_at := now(); new.updated_by := auth.uid();
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.np_date(t text)
 RETURNS date
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare m text[]; mon int; y int;
begin
  if t is null then return null; end if;
  m := regexp_match(t, '(\d{4})-(\d{2})-(\d{2})');
  if m is not null then begin return make_date(m[1]::int, m[2]::int, m[3]::int); exception when others then return null; end; end if;
  m := regexp_match(t, '(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})');
  if m is not null then y := m[3]::int; if y < 100 then y := y + 2000; end if;
    begin return make_date(y, m[2]::int, m[1]::int); exception when others then return null; end; end if;
  m := regexp_match(t, '(\d{1,2})(?:st|nd|rd|th)?[\s-]+([A-Za-z]{3,9})[\s,.-]+(\d{4})');
  if m is not null then
    mon := array_position(array['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'], lower(left(m[2], 3)));
    if mon is null then return null; end if;
    begin return make_date(m[3]::int, mon, m[1]::int); exception when others then return null; end;
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.nw_key_ok(p_key text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
  select exists (select 1 from public.notice_watch w where w.id = 1 and w.enabled and w.key_hash is not null and w.key_hash = encode(extensions.digest(coalesce(p_key, ''), 'sha256'), 'hex'))
$function$
;

CREATE OR REPLACE FUNCTION public.payments_sum()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare iid uuid := coalesce(new.invoice_id, old.invoice_id);
begin
  update public.invoices set paid = coalesce((select sum(amount) from public.payments where invoice_id = iid), 0)
   where id = iid and zoho_invoice_id is null;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_claim_payment(p_invoice uuid, p_amount numeric, p_date date, p_mode text, p_ref text, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.portal_client_id(); new_id uuid; inv record; toe text; cname text;
begin
  if cid is null then raise exception 'Sign in to the client portal first'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Enter the amount paid'; end if;
  if p_date is null or p_date > current_date + 1 or p_date < current_date - 120 then raise exception 'Check the payment date'; end if;
  if coalesce(trim(p_ref), '') = '' then raise exception 'Enter the UTR / transaction reference'; end if;
  if p_invoice is not null then
    select * into inv from public.invoices where id = p_invoice and client_id = cid;
    if not found then raise exception 'Invoice not found'; end if;
  end if;
  if (select count(*) from public.payment_claims where client_id = cid and created_at > now() - interval '1 day') >= 10 then raise exception 'Too many reports today — please contact the office'; end if;
  insert into public.payment_claims (client_id, invoice_id, amount, paid_on, mode, ref, note)
  values (cid, p_invoice, round(p_amount, 2), p_date, coalesce(nullif(p_mode, ''), 'UPI'), left(trim(p_ref), 60), left(p_note, 300)) returning id into new_id;
  -- tell the office (sent by the mailbox script)
  if to_regclass('public.chase_log') is not null then
    select string_agg(email, ',') into toe from public.profiles where active and role in ('admin', 'partner', 'manager') and coalesce(email, '') <> '';
    select coalesce(client_code || ' · ', '') || name into cname from public.clients where id = cid;
    if toe is not null then
      insert into public.chase_log (client_id, kind, channel, to_addr, subject, body, items, status)
      values (cid, 'payment', 'email', toe, 'Client reports payment: ' || cname || ' – ₹' || to_char(p_amount, 'FM99,99,99,990.00'),
        cname || ' says they paid ₹' || to_char(p_amount, 'FM99,99,99,990.00') || ' on ' || to_char(p_date, 'DD Mon YYYY') || ' by ' || coalesce(p_mode, 'UPI') ||
        ' (ref ' || trim(p_ref) || ')' || coalesce(' for invoice ' || inv.inv_no, '') || '.' || coalesce(E'\nNote: ' || p_note, '') ||
        E'\n\nCheck the bank and confirm it in Billing: ' || coalesce(public.chase_site(), '') || '#/billing' || E'\n\n— JLR Compliance Tracker', 'payment', 'queued');
    end if;
  end if;
  return new_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_client_id()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare j jsonb;
begin
  if auth.uid() is null or public.is_member() then return null; end if;
  begin j := public.portal_me(); exception when others then return null; end;
  return nullif(j -> 'client' ->> 'id', '')::uuid;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_extra()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.portal_client_id();
begin
  if cid is null then return null; end if;
  return jsonb_build_object(
    'acks', (select coalesce(jsonb_agg(jsonb_build_object('id', a.id, 'task_id', a.task_id, 'return_name', a.return_name, 'period', a.period, 'arn', a.arn,
                'filed_on', a.filed_on, 'file_name', a.file_name, 'file_path', a.file_path) order by a.filed_on desc nulls last), '[]'::jsonb)
             from public.filing_acks a where a.client_id = cid and a.file_path is not null),
    'claims', (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'invoice_id', p.invoice_id, 'amount', p.amount, 'paid_on', p.paid_on, 'mode', p.mode, 'ref', p.ref,
                'status', p.status, 'reply', p.reply, 'created_at', p.created_at) order by p.created_at desc), '[]'::jsonb)
             from public.payment_claims p where p.client_id = cid and p.created_at > now() - interval '180 days'),
    'upi', (select upi_id from public.settings limit 1));
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_itc_answer(p_period date, p_key text, p_answer text, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.portal_client_id(); r record;
begin
  if cid is null then raise exception 'This login is not linked to a client.'; end if;
  if p_answer not in ('take', 'skip', 'notmine') then raise exception 'Unknown answer'; end if;
  select reco into r from public.gst_months where client_id = cid and period = p_period for update;
  if not found or r.reco->'ask'->'items'->p_key is null then raise exception 'This bill is not on your list.'; end if;
  if coalesce(r.reco->'dec'->p_key->>'a', '') <> '' then raise exception 'Your consultant has already decided this bill — please contact them to change it.'; end if;
  update public.gst_months
     set reco = jsonb_set(coalesce(reco, '{}'::jsonb), '{ans}',
                coalesce(reco->'ans', '{}'::jsonb) || jsonb_build_object(p_key, jsonb_build_object(
                  'a', p_answer, 'note', nullif(left(btrim(coalesce(p_note, '')), 300), ''), 'at', now(), 'via', 'client')))
   where client_id = cid and period = p_period;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_itc_list()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.portal_client_id(); res jsonb;
begin
  if cid is null then return '[]'::jsonb; end if;
  select coalesce(jsonb_agg(x order by (x->>'answer') is not null, x->>'period' desc, x->>'n'), '[]'::jsonb) into res
  from (
    select jsonb_build_object(
             'period', to_char(m.period, 'YYYY-MM-DD'), 'k', it.key,
             'g', it.value->>'g', 'n', it.value->>'n', 'i', it.value->>'i', 'd', it.value->>'d',
             'tax', coalesce((it.value->>'tax')::numeric, 0), 'cn', coalesce((it.value->>'cn')::boolean, false),
             'answer', m.reco->'ans'->it.key->>'a',
             'by_staff', coalesce(m.reco->'ans'->it.key->>'via', '') = 'staff') as x
    from public.gst_months m
    cross join lateral jsonb_each(coalesce(m.reco->'ask'->'items', '{}'::jsonb)) it
    where m.client_id = cid
      and m.period >= (date_trunc('month', current_date) - interval '18 months')::date
      and coalesce(m.reco->'dec'->it.key->>'a', '') = ''                                  -- staff already decided: not asked any more
      and (m.reco->'ans'->it.key is null or (m.reco->'ans'->it.key->>'at')::timestamptz > now() - interval '30 days')
    limit 400
  ) q;
  return res;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_me()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.my_client_id(); s public.settings;
begin
  if cid is null then return null; end if;
  update public.client_users set last_seen = now() where user_id = auth.uid();
  select * into s from public.settings where id = 1;
  return json_build_object(
    'firm', json_build_object('name', s.firm_name, 'address', s.firm_address, 'gstin', s.firm_gstin, 'pan', s.firm_pan,
                              'phone', s.firm_phone, 'email', s.firm_email, 'bank', s.bank_details, 'sac', s.sac_code),
    'client', (select json_build_object('id', c.id, 'name', c.name, 'gstin', c.gstin, 'address', c.address) from public.clients c where c.id = cid),
    'tasks', coalesce((
      select json_agg(json_build_object('id', t.id, 'work_type', t.work_type, 'return_name', t.return_name, 'period', t.period,
               'due_date', t.due_date, 'status', t.status, 'filed_on', t.filed_on, 'arn', t.arn, 'data_received_on', t.data_received_on,
               'docs', (select coalesce(json_agg(json_build_object('id', d.id, 'name', d.name, 'received', d.received) order by d.seq, d.name), '[]'::json)
                        from public.task_docs d where d.task_id = t.id),
               'uploads', (select coalesce(json_agg(json_build_object('name', u.file_name, 'at', u.uploaded_at) order by u.uploaded_at), '[]'::json)
                           from public.client_uploads u where u.task_id = t.id))
             order by t.due_date desc nulls last)
      from public.tasks t
      where t.client_id = cid and t.status <> 'Not applicable' and (t.due_date is null or t.due_date >= current_date - 365)), '[]'::json),
    'invoices', coalesce((
      select json_agg(json_build_object('id', i.id, 'inv_no', i.inv_no, 'inv_date', i.inv_date, 'items', i.items, 'subtotal', i.subtotal,
               'gst_rate', i.gst_rate, 'gst_amount', i.gst_amount, 'total', i.total, 'paid', i.paid, 'notes', i.notes,
               'void', coalesce(i.zoho_status, '') = 'void')
             order by i.inv_date desc)
      from public.invoices i where i.client_id = cid and coalesce(i.zoho_status, '') <> 'draft'), '[]'::json));
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_record_upload(p_task uuid, p_doc uuid, p_path text, p_name text, p_size bigint)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid := public.my_client_id(); uid uuid;
begin
  if cid is null then raise exception 'Not a client login'; end if;
  if split_part(p_path, '/', 1) <> cid::text then raise exception 'Wrong folder'; end if;
  if p_task is not null and not exists (select 1 from public.tasks where id = p_task and client_id = cid) then raise exception 'Not your work item'; end if;
  if p_doc is not null and not exists (select 1 from public.task_docs where id = p_doc and task_id = p_task) then raise exception 'Unknown document'; end if;
  insert into public.client_uploads (client_id, task_id, doc_id, path, file_name, size_bytes, uploaded_by)
  values (cid, p_task, p_doc, p_path, left(p_name, 200), p_size, auth.uid()) returning id into uid;
  if p_doc is not null then update public.task_docs set received = true where id = p_doc; end if;
  return uid;
end $function$
;

CREATE OR REPLACE FUNCTION public.portal_reports()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare cid uuid;
begin
  begin
    cid := nullif(((public.portal_me())::jsonb -> 'client' ->> 'id'), '')::uuid;
  exception when others then cid := null;
  end;
  if cid is null then return '[]'::json; end if;
  return coalesce((select json_agg(json_build_object('period', r.period, 'html', r.html, 'published_at', r.published_at) order by r.period desc)
    from public.client_reports r where r.client_id = cid and r.published), '[]'::json);
end $function$
;

CREATE OR REPLACE FUNCTION public.ret_label(p_kind text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p_kind when 'gstr1' then 'GSTR-1' else 'GSTR-3B' end
$function$
;

CREATE OR REPLACE FUNCTION public.review_apply(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text, p_via text, p_who text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.gst_reviews; c record; staff_mail text; mon text := to_char(p_period, 'Mon YYYY'); sid uuid; ret text := public.ret_label(p_kind);
begin
  select * into r from public.gst_reviews where client_id = p_client and period = p_period and kind = p_kind for update;
  if not found then raise exception 'Review not found'; end if;
  if r.state <> 'sent' then return 'already ' || r.state; end if;
  if p_decision not in ('approve', 'changes') then raise exception 'Unknown decision'; end if;
  if p_decision = 'changes' and coalesce(btrim(p_remarks), '') = '' then raise exception 'Please type the changes needed.'; end if;
  select id, name into c from public.clients where id = p_client;
  select senior_id into sid from public.settings where id = 1;
  perform set_config('jlr.review_ok', '1', true);
  update public.gst_reviews set state = case when p_decision = 'approve' then 'approved' else 'changes' end,
         decided_at = now(), decided_via = p_via, token_hash = null,
         remarks = remarks || case when coalesce(btrim(p_remarks), '') <> '' then jsonb_build_array(jsonb_build_object('at', now(), 'by', p_who, 'text', left(btrim(p_remarks), 2000), 'via', p_via, 'decision', p_decision)) else '[]'::jsonb end
   where client_id = p_client and period = p_period and kind = p_kind;
  if p_decision = 'approve' and p_kind = 'gstr3b' then
    update public.gst_months set status = 'Verified', verified_by = coalesce(sid, verified_by), verified_at = now() where client_id = p_client and period = p_period;
  elsif p_decision = 'changes' then
    update public.gst_months set status = case when p_kind = 'gstr3b' then 'Draft' else status end,
           notes = left(coalesce(notes || E'\n', '') || 'Senior remarks on ' || ret || ' (' || to_char(now() at time zone 'Asia/Kolkata', 'DD Mon HH24:MI') || '): ' || btrim(p_remarks), 4000)
     where client_id = p_client and period = p_period;
  end if;
  perform set_config('jlr.review_ok', '', true);
  -- tell the person who sent it (and the client's staff)
  select string_agg(distinct lower(p.email), ',') into staff_mail from public.profiles p
   where p.email is not null and p.active is not false and (p.id = r.sent_by or p.id = (select default_staff from public.clients where id = p_client));
  if staff_mail is not null then
    insert into public.mail_jobs (kind, kind2, to_addr, subject, body, client_id, period, created_by)
    values ('review_result', p_kind, staff_mail,
      case when p_decision = 'approve' then 'Approved — ' || ret || ' ' || mon || ' — ' || c.name || ' — ready to file'
           else 'Changes needed — ' || ret || ' ' || mon || ' — ' || c.name end,
      case when p_decision = 'approve' then 'The senior approved the ' || ret || ' workings of ' || c.name || ' for ' || mon || '. You can file now.' || E'\n\nAfter filing, upload the ' || ret || ' acknowledgement in the tracker — the workings and acknowledgement then go to the client.'
           else 'The senior asked for changes to the ' || ret || ' workings of ' || c.name || ' for ' || mon || E':\n\n' || btrim(p_remarks) || E'\n\nUpdate the workings in the tracker (GST review) and send for verification again.' end
      || E'\n\n— JLR Compliance Tracker', p_client, p_period, r.sent_by);
  end if;
  return case when p_decision = 'approve' then 'approved' else 'changes' end;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_decide(p_token text, p_decision text, p_remarks text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.gst_reviews; h text := encode(sha256(convert_to(coalesce(p_token, ''), 'UTF8')), 'hex'); who text;
begin
  select * into r from public.gst_reviews where token_hash = h;
  if not found or length(coalesce(p_token, '')) < 30 then raise exception 'This link has already been used or replaced by a newer one.'; end if;
  if r.token_exp < now() then raise exception 'This link has expired.'; end if;
  select coalesce(p.full_name, p.email) into who from public.settings s join public.profiles p on p.id = s.senior_id where s.id = 1;
  return public.review_apply(r.client_id, r.period, r.kind, p_decision, p_remarks, 'link', coalesce(who, 'Senior'));
end $function$
;

CREATE OR REPLACE FUNCTION public.review_decide_staff(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid; who text;
begin
  select senior_id into sid from public.settings where id = 1;
  if not (auth.uid() = sid or public.is_manager()) then raise exception 'Only the senior or a manager can decide.'; end if;
  if not public.can_client_login(p_client) then raise exception 'You do not have permission to do that.'; end if;
  select coalesce(full_name, email) into who from public.profiles where id = auth.uid();
  return public.review_apply(p_client, p_period, p_kind, p_decision, p_remarks, 'tracker', who);
end $function$
;

CREATE OR REPLACE FUNCTION public.review_peek(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.gst_reviews; c record; h text := encode(sha256(convert_to(coalesce(p_token, ''), 'UTF8')), 'hex');
begin
  if length(coalesce(p_token, '')) < 30 then return jsonb_build_object('error', 'This link is not complete.'); end if;
  select * into r from public.gst_reviews where token_hash = h;
  if not found then return jsonb_build_object('error', 'This link has already been used or replaced by a newer one.'); end if;
  if r.token_exp < now() then return jsonb_build_object('error', 'This link has expired. Ask the team to send it again.'); end if;
  select name, gstin into c from public.clients where id = r.client_id;
  return jsonb_build_object('client', c.name, 'gstin', c.gstin, 'period', to_char(r.period, 'YYYY-MM-DD'), 'kind', r.kind, 'ret', public.ret_label(r.kind), 'state', r.state, 'sent_at', r.sent_at,
    'sent_by', (select full_name from public.profiles where id = r.sent_by), 'summary', r.summary, 'remarks', r.remarks, 'sends', r.sends);
end $function$
;

CREATE OR REPLACE FUNCTION public.review_reminders()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p record; n int := 0; lines text; smail text := public.senior_email(); slines text;
begin
  for p in select pr.id, pr.email, coalesce(pr.full_name, pr.email) as name from public.profiles pr where pr.email is not null and pr.active is not false loop
    select string_agg(x.line, E'\n' order by x.ord, x.line) into lines from (
      select case r.state when 'changes' then 1 when 'sent' then 2 else 3 end as ord,
             '  • ' || case r.state when 'changes' then 'CHANGES NEEDED' when 'sent' then 'Waiting for the senior (' || greatest(0, (current_date - (r.sent_at at time zone 'Asia/Kolkata')::date)) || ' day(s))' else 'Approved — file and upload the acknowledgement' end
             || ' — ' || c.name || ' — ' || public.ret_label(r.kind) || ' ' || to_char(r.period, 'Mon YYYY')
             || case when r.state = 'changes' then E'\n      ' || left(coalesce(r.remarks -> -1 ->> 'text', ''), 200) else '' end as line
      from public.gst_reviews r join public.clients c on c.id = r.client_id
      where r.state in ('sent', 'changes', 'approved') and (r.sent_by = p.id or (r.sent_by is null and c.default_staff = p.id))
    ) x;
    if lines is not null then
      insert into public.mail_jobs (kind, to_addr, subject, body, created_by)
      values ('reminder', p.email, 'GST verification status — ' || to_char(now() at time zone 'Asia/Kolkata', 'DD Mon'),
        'Good morning ' || p.name || E',\n\nYour GST returns in verification:\n\n' || lines || E'\n\nOpen the tracker → GST review.\n\n— JLR Compliance Tracker', null);
      n := n + 1;
    end if;
  end loop;
  if smail is not null then
    select string_agg('  • ' || c.name || ' — ' || public.ret_label(r.kind) || ' ' || to_char(r.period, 'Mon YYYY') || ' — sent ' || to_char(r.sent_at at time zone 'Asia/Kolkata', 'DD Mon') || coalesce(' by ' || pr.full_name, ''), E'\n' order by r.sent_at) into slines
      from public.gst_reviews r join public.clients c on c.id = r.client_id left join public.profiles pr on pr.id = r.sent_by
     where r.state = 'sent' and r.sent_at < now() - interval '1 day';
    if slines is not null then
      insert into public.mail_jobs (kind, to_addr, subject, body) values ('reminder', smail, 'Waiting for your verification — GST',
        E'These GST workings are waiting for your verification:\n\n' || slines || E'\n\nOpen each email and click Approve or Needs changes (or reply to it).\n\n— JLR Compliance Tracker');
      n := n + 1;
    end if;
  end if;
  update public.mail_jobs set files = '[]'::jsonb where status = 'sent' and sent_at < now() - interval '30 days' and files <> '[]'::jsonb;
  -- portal drafts of returns sent to the client more than 60 days ago are not needed in the table
  update public.gst_reviews set draft = null where draft is not null and state = 'sent_client' and updated_at < now() - interval '60 days';
  return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_reply(p_key text, p_tag text, p_from text, p_text text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.gst_reviews; t text := btrim(coalesce(p_text, '')); first_line text; who text;
begin
  if not public.mailjob_key_ok(p_key) then raise exception 'Bad key'; end if;
  select * into r from public.gst_reviews where tag = p_tag;
  if not found then return 'unknown tag'; end if;
  if lower(coalesce(p_from, '')) not like '%' || coalesce(public.senior_email(), '#none#') || '%' then return 'not from the senior'; end if;
  if r.state <> 'sent' then return 'already ' || r.state; end if;
  if t = '' then return 'empty'; end if;
  first_line := lower(split_part(t, E'\n', 1));
  select coalesce(p.full_name, p.email) into who from public.settings s join public.profiles p on p.id = s.senior_id where s.id = 1;
  if first_line ~ '^\s*(approved?|ok|okay|fine|go ahead|file it|yes)\y[\s.!,]*$' then
    return public.review_apply(r.client_id, r.period, r.kind, 'approve', null, 'email', coalesce(who, 'Senior'));
  end if;
  return public.review_apply(r.client_id, r.period, r.kind, 'changes', t, 'email', coalesce(who, 'Senior'));
end $function$
;

CREATE OR REPLACE FUNCTION public.senior_email()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select lower(p.email) from public.settings s join public.profiles p on p.id = s.senior_id where s.id = 1
$function$
;

CREATE OR REPLACE FUNCTION public.set_itc_method(p_client uuid, p_method text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_method not in ('books_2b', 'books', '2b_confirm') then raise exception 'Unknown ITC method'; end if;
  if not public.can_client_login(p_client) then raise exception 'You do not have permission to do that.'; end if;
  update public.clients set itc_method = p_method where id = p_client;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_mailjob_key(p_hash text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_partner() then raise exception 'Only a Partner or the Admin can do that.'; end if;
  if p_hash !~ '^[0-9a-f]{64}$' then raise exception 'Bad key'; end if;
  update public.settings set mailjob_key_hash = p_hash where id = 1;
end $function$
;

CREATE OR REPLACE FUNCTION public.take_backup(p_kind text DEFAULT 'auto'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  keys text[] := array['clients','tasks','task_checks','task_docs','notices','invoices','payments','fee_rates','due_dates','checklist_templates','linked_rules','team',
                       'followups','renewals','tax_intimations','onboarding','client_reports','mca_companies','mca_directors','tds_entries','tds_challans','tds_returns','bank_statements','bank_rules','notice_mails','chase_log','work_requests','filing_acks','payment_claims'];
  tabs text[] := array['clients','tasks','task_checks','task_docs','notices','invoices','payments','fee_rates','due_dates','checklist_templates','linked_rules','profiles',
                       'followups','renewals','tax_intimations','onboarding','client_reports','mca_companies','mca_directors','tds_entries','tds_challans','tds_returns','bank_statements','bank_rules','notice_mails','chase_log','work_requests','filing_acks','payment_claims'];
  d jsonb := '{}'::jsonb; v jsonb; c bigint; n bigint := 0; i int;
begin
  if auth.uid() is not null and not public.is_partner() then
    raise exception 'Only a Partner or the Admin can take a backup';
  end if;
  for i in 1 .. array_length(tabs, 1) loop
    if to_regclass('public.' || tabs[i]) is null then continue; end if;
    execute format('select coalesce(jsonb_agg(to_jsonb(x)%s), ''[]''::jsonb), count(*) from public.%I x',
                   case when tabs[i] = 'client_reports' then ' - ''html''' else '' end, tabs[i]) into v, c;
    d := d || jsonb_build_object(keys[i], v);
    n := n + c;
  end loop;
  insert into public.backups (taken_at, kind, data, rows, size_kb)
  values (now(), coalesce(p_kind, 'auto'), d, n, ceil(octet_length(d::text) / 1024.0));
  delete from public.backups where taken_at < now() - interval '30 days';
end $function$
;

CREATE OR REPLACE FUNCTION public.task_checks_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare tid uuid := coalesce(new.task_id, old.task_id);
begin
  update public.tasks t set
    checks_total = (select count(*) from public.task_checks c where c.task_id = tid and c.status <> 'N/A'),
    checks_done  = (select count(*) from public.task_checks c where c.task_id = tid and c.status = 'Done')
  where t.id = tid;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.task_checks_stamp()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.status = 'Done' and (tg_op = 'INSERT' or old.status is distinct from 'Done') then
    new.completed_on := coalesce(new.completed_on, current_date);
    new.completed_by := coalesce(new.completed_by, auth.uid());
  elsif new.status <> 'Done' then
    new.completed_on := null; new.completed_by := null;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.task_docs_after()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare tid uuid := coalesce(new.task_id, old.task_id);
begin
  -- all documents in -> client data received (status moves Pending data -> In progress)
  if exists (select 1 from public.task_docs where task_id = tid)
     and not exists (select 1 from public.task_docs where task_id = tid and not received) then
    update public.tasks set data_received_on = coalesce(data_received_on, (now() at time zone 'Asia/Kolkata')::date),
                            data_source = coalesce(data_source, 'Documents')
     where id = tid and data_received_on is null;
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.task_docs_stamp()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.received and (tg_op = 'INSERT' or not old.received) then
    new.received_on := coalesce(new.received_on, (now() at time zone 'Asia/Kolkata')::date);
  elsif not new.received then new.received_on := null; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.task_missing_docs(p_task uuid, p_return text)
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case
    when exists (select 1 from public.task_docs d where d.task_id = p_task)
      then (select coalesce(array_agg(d.name order by d.seq, d.name), '{}') from public.task_docs d where d.task_id = p_task and not coalesce(d.received, false))
    else coalesce((select t.docs from public.checklist_templates t where lower(p_return) = any(select lower(x) from unnest(t.matches) x) limit 1), '{}')
  end
$function$
;

CREATE OR REPLACE FUNCTION public.tasks_before_write()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'UPDATE' and not public.is_manager() and auth.uid() is not null then
    new.client_id   := old.client_id;
    new.work_type   := old.work_type;
    new.return_name := old.return_name;
    new.period      := old.period;
    new.due_date    := old.due_date;
    new.assigned_to := old.assigned_to;
    new.created_at  := old.created_at;
  end if;
  if new.data_received_on is not null and new.status = 'Pending data'
     and (tg_op = 'INSERT' or old.data_received_on is null) then
    new.status := 'In progress';
  end if;
  if tg_op = 'UPDATE' and old.status = 'Pending data' and new.status in ('In progress', 'Ready to file', 'Filed')
     and new.data_received_on is null then
    new.data_received_on := current_date;
  end if;
  if new.status = 'Filed' and new.filed_on is null then
    new.filed_on := current_date;
  end if;
  if new.status <> 'Filed' then
    new.filed_on := null;
  end if;
  new.updated_at := now();
  new.updated_by := case when public.is_member() then auth.uid() else null end;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.tasks_fee_default()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.fee is null then
    select amount into new.fee from public.fee_rates
     where lower(return_name) = lower(new.return_name) and (client_id = new.client_id or client_id is null)
     order by client_id nulls last limit 1;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.tasks_money_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_manager() and auth.uid() is not null then
    new.fee := old.fee; new.invoice_id := old.invoice_id;
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin new.updated_at := now(); return new; end $function$
;

CREATE OR REPLACE FUNCTION public.wa_admin_log(p_limit integer DEFAULT 30)
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when not public.is_admin() then null else coalesce((
    select json_agg(row_to_json(x) order by x.sent_at desc) from (
      select l.sent_at, l.kind, l.phone, l.summary, p.full_name,
             r.status_code,
             case when r.status_code between 200 and 299 then null
                  else left(coalesce(r.content::text, r.error_msg, ''), 300) end as error
      from public.wa_log l
      left join public.profiles p on p.id = l.profile_id
      left join net._http_response r on r.id = l.request_id
      order by l.sent_at desc limit p_limit) x), '[]'::json) end;
$function$
;

CREATE OR REPLACE FUNCTION public.wa_admin_run(p_kind text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  if p_kind = 'daily'   then return public.wa_daily_reminders(true); end if;
  if p_kind = 'monthly' then return public.wa_monthly_due_list(true); end if;
  if p_kind = 'client'  then return public.wa_client_reminders(true); end if;
  raise exception 'Unknown kind';
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_admin_set_token(p_token text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid;
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  if coalesce(trim(p_token), '') = '' then raise exception 'Token is empty'; end if;
  select id into sid from vault.secrets where name = 'whatsapp_token';
  if sid is null then
    perform vault.create_secret(trim(p_token), 'whatsapp_token', 'Meta WhatsApp Cloud API access token');
  else
    perform vault.update_secret(sid, trim(p_token));
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_admin_status()
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when not public.is_admin() then null else json_build_object(
    'token_saved', exists (select 1 from vault.secrets where name = 'whatsapp_token'),
    'jobs', (select coalesce(json_agg(json_build_object('name', jobname, 'schedule', schedule, 'active', active)), '[]'::json)
             from cron.job where jobname like 'wa-%')
  ) end;
$function$
;

CREATE OR REPLACE FUNCTION public.wa_admin_test(p_phone text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare ph text;
begin
  if not public.is_admin() then raise exception 'Only admin can do this'; end if;
  ph := coalesce(nullif(p_phone, ''), (select phone from public.profiles where id = auth.uid()));
  if coalesce(ph, '') = '' then raise exception 'Add your WhatsApp number in Team first'; end if;
  return public.wa_send(ph, 'jaspers_market_plain_text_v1', null, 'test', auth.uid(), 'connection test');
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_clean(p text, maxlen integer DEFAULT 900)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select left(regexp_replace(regexp_replace(coalesce(nullif(p, ''), '-'), '[\r\n\t]+', ' ', 'g'), ' {2,}', ' ', 'g'), maxlen);
$function$
;

CREATE OR REPLACE FUNCTION public.wa_client_reminders(p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s     public.wa_settings;
  today date := (now() at time zone 'Asia/Kolkata')::date;
  c     record;
  lst   text; first_due date;
  sent  int := 0; rid bigint;
begin
  select * into s from public.wa_settings where id = 1;
  if not s.client_enabled and not p_force then return 0; end if;
  for c in select * from public.clients where active and coalesce(phone, '') <> '' loop
    -- skip if already reminded today
    continue when exists (select 1 from public.wa_log where kind = 'client' and summary like c.id::text || '%'
                          and (sent_at at time zone 'Asia/Kolkata')::date = today);
    select string_agg(t.return_name || ' ' || t.period, ', ' order by t.due_date), min(t.due_date)
      into lst, first_due
      from public.tasks t
     where t.client_id = c.id and t.status = 'Pending data' and t.due_date >= today
       and ((t.due_date - today) = any(s.client_days)
            or (p_force and t.due_date - today <= (select max(x) from unnest(s.client_days) x)));
    continue when lst is null;
    rid := public.wa_send(public.wa_phone(c.phone), s.client_template,
      array[coalesce(c.contact_person, c.name), lst, to_char(first_due, 'DD Mon YYYY'),
            rtrim(s.app_url, '/') || '/status.html?c=' || c.status_token],
      'client', null, c.id::text || ' ' || c.name || ': ' || lst);
    if rid is not null then sent := sent + 1; end if;
  end loop;
  return sent;
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_daily_reminders(p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s      public.wa_settings;
  today  date := (now() at time zone 'Asia/Kolkata')::date;
  p      record;
  n_over int; n_soon int; n_wait int;
  l_over text; l_soon text;
  sent   int := 0;
  rid    bigint;
begin
  select * into s from public.wa_settings where id = 1;
  if not s.enabled and not p_force then return 0; end if;
  if not p_force and exists (select 1 from public.wa_log where kind = 'daily'
                             and (sent_at at time zone 'Asia/Kolkata')::date = today) then
    return 0;
  end if;
  for p in select * from public.profiles where active and coalesce(phone, '') <> '' loop
    select count(*) filter (where due_date < today),
           count(*) filter (where due_date between today and today + 3),
           count(*) filter (where status = 'Pending data')
      into n_over, n_soon, n_wait
      from public.tasks
     where assigned_to = p.id and status not in ('Filed', 'Not applicable');
    continue when n_over + n_soon + n_wait = 0;
    select string_agg(t.return_name || ' ' || c.name, '; ' order by t.due_date)
      into l_over
      from (select * from public.tasks where assigned_to = p.id and status not in ('Filed','Not applicable')
              and due_date < today order by due_date limit 6) t
      join public.clients c on c.id = t.client_id;
    select string_agg(t.return_name || ' ' || c.name || ' (' || to_char(t.due_date, 'DD Mon') || ')', '; ' order by t.due_date)
      into l_soon
      from (select * from public.tasks where assigned_to = p.id and status not in ('Filed','Not applicable')
              and due_date between today and today + 3 order by due_date limit 6) t
      join public.clients c on c.id = t.client_id;
    rid := public.wa_send(
      p.phone, s.daily_template,
      array[
        split_part(coalesce(p.full_name, 'there'), ' ', 1),
        n_over || case when n_over > 0 then ' - ' || coalesce(l_over, '') || case when n_over > 6 then ' and more' else '' end else '' end,
        n_soon || case when n_soon > 0 then ' - ' || coalesce(l_soon, '') || case when n_soon > 6 then ' and more' else '' end else '' end,
        n_wait::text,
        s.app_url
      ],
      'daily', p.id, format('overdue %s, next 3 days %s, waiting %s', n_over, n_soon, n_wait));
    if rid is not null then sent := sent + 1; end if;
  end loop;
  return sent;
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_month_list(p_month date)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select string_agg(to_char(dt, 'DD') || ' ' || return_name, ', ' order by dt, sort)
  from (
    select d.return_name, d.sort,
           make_date(extract(year from p_month)::int, extract(month from p_month)::int,
                     least(d.due_day, extract(day from (date_trunc('month', p_month) + interval '1 month - 1 day'))::int)) as dt
    from public.due_dates d
    where extract(month from p_month)::int = any (d.months)
  ) x;
$function$
;

CREATE OR REPLACE FUNCTION public.wa_monthly_due_list(p_force boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s      public.wa_settings;
  today  date := (now() at time zone 'Asia/Kolkata')::date;
  m      date := date_trunc('month', (now() at time zone 'Asia/Kolkata'))::date;
  list   text;
  p      record;
  sent   int := 0;
  rid    bigint;
begin
  select * into s from public.wa_settings where id = 1;
  if not s.enabled and not p_force then return 0; end if;
  if not p_force and exists (select 1 from public.wa_log where kind = 'monthly'
                             and date_trunc('month', sent_at at time zone 'Asia/Kolkata')::date = m) then
    return 0;
  end if;
  list := public.wa_month_list(m);
  if list is null then return 0; end if;
  for p in select * from public.profiles where active and coalesce(phone, '') <> '' loop
    rid := public.wa_send(p.phone, s.monthly_template,
      array[split_part(coalesce(p.full_name, 'there'), ' ', 1), to_char(m, 'FMMonth YYYY'), list, s.app_url],
      'monthly', p.id, to_char(m, 'Mon YYYY') || ' list');
    if rid is not null then sent := sent + 1; end if;
  end loop;
  return sent;
end $function$
;

CREATE OR REPLACE FUNCTION public.wa_phone(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when length(regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g')) = 10
              then '91' || regexp_replace(p, '[^0-9]', '', 'g')
              else regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') end;
$function$
;

CREATE OR REPLACE FUNCTION public.wa_send(p_phone text, p_template text, p_params text[], p_kind text, p_profile uuid DEFAULT NULL::uuid, p_summary text DEFAULT NULL::text)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  s     public.wa_settings;
  tok   text;
  body  jsonb;
  req   bigint;
  comps jsonb := '[]'::jsonb;
begin
  select * into s from public.wa_settings where id = 1;
  select decrypted_secret into tok from vault.decrypted_secrets where name = 'whatsapp_token' limit 1;
  if s.phone_number_id is null or tok is null or coalesce(p_phone, '') = '' then
    return null;
  end if;
  if p_params is not null and array_length(p_params, 1) > 0 then
    comps := jsonb_build_array(jsonb_build_object(
      'type', 'body',
      'parameters', (select jsonb_agg(jsonb_build_object('type', 'text', 'text', public.wa_clean(x))) from unnest(p_params) x)));
  end if;
  body := jsonb_build_object(
    'messaging_product', 'whatsapp',
    'to', regexp_replace(p_phone, '[^0-9]', '', 'g'),
    'type', 'template',
    'template', jsonb_build_object(
      'name', p_template,
      'language', jsonb_build_object('code', case when p_template = 'hello_world' or p_template like 'jaspers_market%' then 'en_US' else s.template_lang end))
      || case when jsonb_array_length(comps) > 0 then jsonb_build_object('components', comps) else '{}'::jsonb end);
  select net.http_post(
    url     := 'https://graph.facebook.com/' || s.api_version || '/' || s.phone_number_id || '/messages',
    headers := jsonb_build_object('Authorization', 'Bearer ' || tok, 'Content-Type', 'application/json'),
    body    := body,
    timeout_milliseconds := 20000
  ) into req;
  insert into public.wa_log (kind, profile_id, phone, summary, request_id)
  values (p_kind, p_profile, p_phone, p_summary, req);
  return req;
end $function$
;

CREATE OR REPLACE FUNCTION public.wr_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    new.requested_by := coalesce(auth.uid(), new.requested_by);
    new.created_at := now();
  else
    if not public.is_manager() then
      new.title := old.title; new.details := old.details; new.client_id := old.client_id; new.assigned_to := old.assigned_to;
      new.requested_by := old.requested_by; new.due_date := old.due_date; new.priority := old.priority;
      if new.status = 'Cancelled' then new.status := old.status; end if;
    end if;
    new.requested_by := old.requested_by; new.created_at := old.created_at;
  end if;
  if new.status = 'In progress' and new.started_at is null then new.started_at := now(); end if;
  if new.status = 'Done' and (tg_op = 'INSERT' or old.status <> 'Done') then new.done_at := now(); end if;
  if new.status not in ('Done') then new.done_at := null; end if;
  new.updated_at := now();
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.wr_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare toe text; who text; cl text; site text;
begin
  site := coalesce((select public.chase_site()), '');
  cl := (select coalesce(client_code || ' · ', '') || name from public.clients where id = new.client_id);
  if tg_op = 'INSERT' or (old.assigned_to is distinct from new.assigned_to) then
    select email into toe from public.profiles where id = new.assigned_to and active;
    who := (select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.requested_by);
    if coalesce(toe, '') <> '' and new.status not in ('Done', 'Cancelled') then
      insert into public.chase_log (client_id, kind, channel, to_addr, subject, body, items, status)
      values (new.client_id, 'request', 'email', toe,
        case new.priority when 'Normal' then '' else upper(new.priority) || ': ' end || 'Work request from ' || coalesce(who, 'your manager') || ' – ' || left(new.title, 120),
        coalesce(who, 'Your manager') || ' has asked you to do this:' || E'\n\n' || new.title ||
        coalesce(E'\n\n' || new.details, '') || coalesce(E'\n\nClient: ' || cl, '') ||
        coalesce(E'\nDue: ' || to_char(new.due_date, 'DD Mon YYYY'), '') || E'\nPriority: ' || new.priority ||
        E'\n\nOpen your dashboard to start it and mark it done: ' || site || '#/dashboard' || E'\n\n— JLR Compliance Tracker', new.title, 'queued');
    end if;
  elsif new.status = 'Done' and old.status <> 'Done' and new.requested_by is not null then
    select email into toe from public.profiles where id = new.requested_by and active;
    who := (select coalesce(nullif(full_name, ''), email) from public.profiles where id = new.assigned_to);
    if coalesce(toe, '') <> '' then
      insert into public.chase_log (client_id, kind, channel, to_addr, subject, body, items, status)
      values (new.client_id, 'request', 'email', toe, 'Done: ' || left(new.title, 120) || ' (' || coalesce(who, '') || ')',
        coalesce(who, 'The team member') || ' has finished your request:' || E'\n\n' || new.title || coalesce(E'\n\nClient: ' || cl, '') ||
        coalesce(E'\n\nReply: ' || new.reply, '') || E'\n\nOpen the tracker: ' || site || '#/dashboard' || E'\n\n— JLR Compliance Tracker', new.title, 'queued');
    end if;
  end if;
  return null;
end $function$
;

CREATE OR REPLACE FUNCTION public.zoho_cron()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare s public.zoho_settings; k text;
begin
  select * into s from public.zoho_settings where id = 1;
  if not s.enabled then return; end if;
  select decrypted_secret into k from vault.decrypted_secrets where name = 'zoho_cron_key' limit 1;
  perform net.http_post(url := s.function_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-key', k),
    body := jsonb_build_object('action', 'sync'), timeout_milliseconds := 60000);
end $function$
;

CREATE OR REPLACE FUNCTION public.zoho_get_secrets()
 RETURNS json
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select json_build_object(
    'client_secret', (select decrypted_secret from vault.decrypted_secrets where name = 'zoho_client_secret' limit 1),
    'refresh_token', (select decrypted_secret from vault.decrypted_secrets where name = 'zoho_refresh_token' limit 1),
    'cron_key',      (select decrypted_secret from vault.decrypted_secrets where name = 'zoho_cron_key' limit 1));
$function$
;

CREATE OR REPLACE FUNCTION public.zoho_put_secret(p_name text, p_value text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare sid uuid;
begin
  select id into sid from vault.secrets where name = p_name;
  if p_value is null then
    if sid is not null then delete from vault.secrets where id = sid; end if;
    return;
  end if;
  if sid is null then perform vault.create_secret(p_value, p_name, 'Zoho Invoice link');
  else perform vault.update_secret(sid, p_value); end if;
end $function$
;


-- ==== trig ====
CREATE TRIGGER bks_touch BEFORE UPDATE ON public.bank_statements FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.checklist_templates FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER client_logins_after_del AFTER DELETE ON public.client_logins FOR EACH ROW EXECUTE FUNCTION client_logins_after_del();
CREATE TRIGGER cr_guard BEFORE INSERT OR UPDATE ON public.client_reports FOR EACH ROW EXECUTE FUNCTION cr_guard();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.client_rules FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER clients_code_tidy BEFORE INSERT OR UPDATE OF client_code ON public.clients FOR EACH ROW EXECUTE FUNCTION clients_code_tidy();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.due_dates FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.fee_rates FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.filing_acks FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER followups_after AFTER INSERT OR DELETE OR UPDATE ON public.followups FOR EACH ROW EXECUTE FUNCTION followups_after();
CREATE TRIGGER followups_before BEFORE INSERT ON public.followups FOR EACH ROW EXECUTE FUNCTION followups_before();
CREATE TRIGGER gst_months_before BEFORE INSERT OR UPDATE ON public.gst_months FOR EACH ROW EXECUTE FUNCTION gst_months_before();
CREATE TRIGGER gst_reviews_guard BEFORE INSERT OR UPDATE ON public.gst_reviews FOR EACH ROW EXECUTE FUNCTION gst_reviews_guard();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.gst_reviews FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER law_updates_before BEFORE INSERT OR UPDATE ON public.law_updates FOR EACH ROW EXECUTE FUNCTION law_updates_before();
CREATE TRIGGER mc_touch BEFORE UPDATE ON public.mca_companies FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.mca_companies FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER md_touch BEFORE UPDATE ON public.mca_directors FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.mca_directors FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER notices_before BEFORE INSERT OR UPDATE ON public.notices FOR EACH ROW EXECUTE FUNCTION notices_before();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.notices FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER ob_touch BEFORE UPDATE ON public.onboarding FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.onboarding FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.payment_claims FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER payments_sum AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION payments_sum();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER renewals_touch BEFORE UPDATE ON public.renewals FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.renewals FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER task_checks_count AFTER INSERT OR DELETE OR UPDATE ON public.task_checks FOR EACH ROW EXECUTE FUNCTION task_checks_count();
CREATE TRIGGER task_checks_stamp BEFORE INSERT OR UPDATE ON public.task_checks FOR EACH ROW EXECUTE FUNCTION task_checks_stamp();
CREATE TRIGGER task_docs_after AFTER INSERT OR UPDATE ON public.task_docs FOR EACH ROW EXECUTE FUNCTION task_docs_after();
CREATE TRIGGER task_docs_stamp BEFORE INSERT OR UPDATE ON public.task_docs FOR EACH ROW EXECUTE FUNCTION task_docs_stamp();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.task_docs FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER tasks_before_write BEFORE INSERT OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION tasks_before_write();
CREATE TRIGGER tasks_fee_default BEFORE INSERT ON public.tasks FOR EACH ROW EXECUTE FUNCTION tasks_fee_default();
CREATE TRIGGER tasks_money_guard BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION tasks_money_guard();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER ti_touch BEFORE UPDATE ON public.tax_intimations FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.tax_intimations FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER tdc_touch BEFORE UPDATE ON public.tds_challans FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.tds_challans FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER tde_touch BEFORE UPDATE ON public.tds_entries FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER tdr_touch BEFORE UPDATE ON public.tds_returns FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.tds_returns FOR EACH ROW EXECUTE FUNCTION audit_row();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
CREATE TRIGGER wr_guard BEFORE INSERT OR UPDATE ON public.work_requests FOR EACH ROW EXECUTE FUNCTION wr_guard();
CREATE TRIGGER wr_notify AFTER INSERT OR UPDATE ON public.work_requests FOR EACH ROW EXECUTE FUNCTION wr_notify();
CREATE TRIGGER zz_audit AFTER INSERT OR DELETE OR UPDATE ON public.work_requests FOR EACH ROW EXECUTE FUNCTION audit_row();

-- ==== rls ====
alter table public.ai_settings enable row level security;
alter table public.ai_usage enable row level security;
alter table public.audit_log enable row level security;
alter table public.auto_work_done enable row level security;
alter table public.auto_work_settings enable row level security;
alter table public.backups enable row level security;
alter table public.bank_rules enable row level security;
alter table public.bank_statements enable row level security;
alter table public.chase_log enable row level security;
alter table public.chase_settings enable row level security;
alter table public.checklist_templates enable row level security;
alter table public.client_logins enable row level security;
alter table public.client_reports enable row level security;
alter table public.client_rules enable row level security;
alter table public.client_uploads enable row level security;
alter table public.client_users enable row level security;
alter table public.clients enable row level security;
alter table public.data_request_log enable row level security;
alter table public.data_request_settings enable row level security;
alter table public.data_request_templates enable row level security;
alter table public.demo_rows enable row level security;
alter table public.due_dates enable row level security;
alter table public.fee_rates enable row level security;
alter table public.filing_acks enable row level security;
alter table public.followups enable row level security;
alter table public.gst_checks enable row level security;
alter table public.gst_months enable row level security;
alter table public.gst_reviews enable row level security;
alter table public.gst_settings enable row level security;
alter table public.gst_tp_sessions enable row level security;
alter table public.invoices enable row level security;
alter table public.law_updates enable row level security;
alter table public.linked_rules enable row level security;
alter table public.login_access_log enable row level security;
alter table public.mail_inbox enable row level security;
alter table public.mail_jobs enable row level security;
alter table public.mail_settings enable row level security;
alter table public.mca_companies enable row level security;
alter table public.mca_directors enable row level security;
alter table public.notice_mails enable row level security;
alter table public.notice_watch enable row level security;
alter table public.notices enable row level security;
alter table public.onboarding enable row level security;
alter table public.payment_claims enable row level security;
alter table public.payments enable row level security;
alter table public.profiles enable row level security;
alter table public.renewals enable row level security;
alter table public.settings enable row level security;
alter table public.task_checks enable row level security;
alter table public.task_docs enable row level security;
alter table public.tasks enable row level security;
alter table public.tax_intimations enable row level security;
alter table public.tds_challans enable row level security;
alter table public.tds_entries enable row level security;
alter table public.tds_returns enable row level security;
alter table public.wa_log enable row level security;
alter table public.wa_settings enable row level security;
alter table public.work_requests enable row level security;
alter table public.zoho_items enable row level security;
alter table public.zoho_settings enable row level security;
alter table public.zoho_state enable row level security;

-- ==== pol ====
create policy au_sel on public.ai_usage as permissive for select to authenticated using (is_manager());
create policy audit_sel on public.audit_log as permissive for select to authenticated using (is_partner());
create policy bk_read on public.backups as permissive for select to authenticated using (is_partner());
create policy bkr_del on public.bank_rules as permissive for delete to authenticated using (
CASE
    WHEN (client_id IS NULL) THEN is_manager()
    ELSE can_client_login(client_id)
END);
create policy bkr_ins on public.bank_rules as permissive for insert to authenticated with check (
CASE
    WHEN (client_id IS NULL) THEN is_manager()
    ELSE can_client_login(client_id)
END);
create policy bkr_sel on public.bank_rules as permissive for select to authenticated using (((client_id IS NULL) OR can_client_login(client_id)));
create policy bkr_upd on public.bank_rules as permissive for update to authenticated using (
CASE
    WHEN (client_id IS NULL) THEN is_manager()
    ELSE can_client_login(client_id)
END) with check (
CASE
    WHEN (client_id IS NULL) THEN is_manager()
    ELSE can_client_login(client_id)
END);
create policy bks_del on public.bank_statements as permissive for delete to authenticated using ((can_client_login(client_id) AND (is_manager() OR (created_by = auth.uid()))));
create policy bks_ins on public.bank_statements as permissive for insert to authenticated with check (can_client_login(client_id));
create policy bks_sel on public.bank_statements as permissive for select to authenticated using (can_client_login(client_id));
create policy bks_upd on public.bank_statements as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy cl_sel on public.chase_log as permissive for select to authenticated using (is_manager());
create policy ct_read on public.checklist_templates as permissive for select to authenticated using (is_member());
create policy ct_write on public.checklist_templates as permissive for all to authenticated using (is_partner()) with check (is_partner());
create policy cl_read on public.client_logins as permissive for select to authenticated using (can_client_login(client_id));
create policy cr_del on public.client_reports as permissive for delete to authenticated using (is_manager());
create policy cr_ins on public.client_reports as permissive for insert to authenticated with check (can_client_login(client_id));
create policy cr_sel on public.client_reports as permissive for select to authenticated using (can_client_login(client_id));
create policy cr_upd on public.client_reports as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy cr_del on public.client_rules as permissive for delete to authenticated using ((((client_id IS NULL) AND is_manager()) OR ((client_id IS NOT NULL) AND can_client_login(client_id))));
create policy cr_ins on public.client_rules as permissive for insert to authenticated with check ((((client_id IS NULL) AND is_manager()) OR ((client_id IS NOT NULL) AND can_client_login(client_id))));
create policy cr_sel on public.client_rules as permissive for select to authenticated using ((((client_id IS NULL) AND is_member()) OR ((client_id IS NOT NULL) AND can_client_login(client_id))));
create policy cr_upd on public.client_rules as permissive for update to authenticated using ((((client_id IS NULL) AND is_manager()) OR ((client_id IS NOT NULL) AND can_client_login(client_id)))) with check ((((client_id IS NULL) AND is_manager()) OR ((client_id IS NOT NULL) AND can_client_login(client_id))));
create policy cup_read on public.client_uploads as permissive for select to authenticated using ((is_manager() OR ((task_id IS NOT NULL) AND can_task(task_id)) OR (client_id = ( SELECT client_users.client_id
   FROM client_users
  WHERE (client_users.user_id = auth.uid())))));
create policy cu_read on public.client_users as permissive for select to authenticated using ((is_manager() OR (user_id = auth.uid())));
create policy clients_del on public.clients as permissive for delete to authenticated using (is_partner());
create policy clients_ins on public.clients as permissive for insert to authenticated with check (is_manager());
create policy clients_read on public.clients as permissive for select to authenticated using (is_member());
create policy clients_upd on public.clients as permissive for update to authenticated using (is_manager()) with check (is_manager());
create policy drl_sel on public.data_request_log as permissive for select to authenticated using (is_manager());
create policy due_admin on public.due_dates as permissive for all to authenticated using (is_manager()) with check (is_manager());
create policy due_read on public.due_dates as permissive for select to authenticated using (is_member());
create policy fee_admin on public.fee_rates as permissive for all to authenticated using (is_manager()) with check (is_manager());
create policy fa_del on public.filing_acks as permissive for delete to authenticated using (is_manager());
create policy fa_ins on public.filing_acks as permissive for insert to authenticated with check ((is_member() AND (is_manager() OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE ((t.id = filing_acks.task_id) AND (t.assigned_to = auth.uid())))))));
create policy fa_sel on public.filing_acks as permissive for select to authenticated using ((is_member() AND (is_manager() OR (EXISTS ( SELECT 1
   FROM tasks t
  WHERE (t.id = filing_acks.task_id))))));
create policy fu_del on public.followups as permissive for delete to authenticated using ((is_manager() OR (created_by = auth.uid())));
create policy fu_ins on public.followups as permissive for insert to authenticated with check ((((kind = 'task'::text) AND can_task(task_id)) OR ((kind = 'payment'::text) AND is_manager())));
create policy fu_read on public.followups as permissive for select to authenticated using ((((kind = 'task'::text) AND can_task(task_id)) OR ((kind = 'payment'::text) AND is_manager())));
create policy fu_upd on public.followups as permissive for update to authenticated using ((is_manager() OR (created_by = auth.uid()))) with check ((((kind = 'task'::text) AND can_task(task_id)) OR ((kind = 'payment'::text) AND is_manager())));
create policy gm_del on public.gst_months as permissive for delete to authenticated using (is_manager());
create policy gm_ins on public.gst_months as permissive for insert to authenticated with check (can_client_login(client_id));
create policy gm_read on public.gst_months as permissive for select to authenticated using (can_client_login(client_id));
create policy gm_upd on public.gst_months as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy grv_ins on public.gst_reviews as permissive for insert to authenticated with check (can_client_login(client_id));
create policy grv_sel on public.gst_reviews as permissive for select to authenticated using (can_client_login(client_id));
create policy grv_upd on public.gst_reviews as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy inv_admin on public.invoices as permissive for all to authenticated using (is_manager()) with check (is_manager());
create policy lu_read on public.law_updates as permissive for select to authenticated using ((((status = 'published'::text) AND is_member()) OR is_partner()));
create policy lu_write on public.law_updates as permissive for all to authenticated using (is_partner()) with check (is_partner());
create policy lr_read on public.linked_rules as permissive for select to authenticated using (is_member());
create policy lr_write on public.linked_rules as permissive for all to authenticated using (is_partner()) with check (is_partner());
create policy lal_read on public.login_access_log as permissive for select to authenticated using (is_admin());
create policy mi_read on public.mail_inbox as permissive for select to authenticated using (can_client_login(client_id));
create policy mi_upd on public.mail_inbox as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy mj_ins on public.mail_jobs as permissive for insert to authenticated with check ((is_member() AND (COALESCE(created_by, auth.uid()) = auth.uid()) AND ((client_id IS NULL) OR can_client_login(client_id)) AND (octet_length((files)::text) < 15000000)));
create policy mj_sel on public.mail_jobs as permissive for select to authenticated using ((is_manager() OR (created_by = auth.uid())));
create policy mc_del on public.mca_companies as permissive for delete to authenticated using (is_manager());
create policy mc_ins on public.mca_companies as permissive for insert to authenticated with check (can_client_login(client_id));
create policy mc_sel on public.mca_companies as permissive for select to authenticated using (can_client_login(client_id));
create policy mc_upd on public.mca_companies as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy md_del on public.mca_directors as permissive for delete to authenticated using (can_client_login(client_id));
create policy md_ins on public.mca_directors as permissive for insert to authenticated with check (can_client_login(client_id));
create policy md_sel on public.mca_directors as permissive for select to authenticated using (can_client_login(client_id));
create policy md_upd on public.mca_directors as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy nm_sel on public.notice_mails as permissive for select to authenticated using (is_manager());
create policy nm_upd on public.notice_mails as permissive for update to authenticated using (is_manager()) with check (is_manager());
create policy n_del on public.notices as permissive for delete to authenticated using (is_partner());
create policy n_ins on public.notices as permissive for insert to authenticated with check (is_manager());
create policy n_read on public.notices as permissive for select to authenticated using ((is_manager() OR (assigned_to = auth.uid())));
create policy n_upd on public.notices as permissive for update to authenticated using ((is_manager() OR (assigned_to = auth.uid()))) with check ((is_manager() OR (assigned_to = auth.uid())));
create policy ob_del on public.onboarding as permissive for delete to authenticated using (is_manager());
create policy ob_ins on public.onboarding as permissive for insert to authenticated with check (is_manager());
create policy ob_sel on public.onboarding as permissive for select to authenticated using (can_client_login(client_id));
create policy ob_upd on public.onboarding as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy pc_sel on public.payment_claims as permissive for select to authenticated using (is_manager());
create policy pc_upd on public.payment_claims as permissive for update to authenticated using (is_manager()) with check (is_manager());
create policy pay_admin on public.payments as permissive for all to authenticated using (is_manager()) with check (is_manager());
create policy profiles_admin on public.profiles as permissive for update to authenticated using (is_admin()) with check (is_admin());
create policy profiles_read on public.profiles as permissive for select to authenticated using (is_member());
create policy rn_del on public.renewals as permissive for delete to authenticated using (is_manager());
create policy rn_ins on public.renewals as permissive for insert to authenticated with check (can_client_login(client_id));
create policy rn_sel on public.renewals as permissive for select to authenticated using (can_client_login(client_id));
create policy rn_upd on public.renewals as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy settings_admin on public.settings as permissive for update to authenticated using (is_admin()) with check (is_admin());
create policy settings_read on public.settings as permissive for select to authenticated using (is_member());
create policy tc_delete on public.task_checks as permissive for delete to authenticated using (is_manager());
create policy tc_insert on public.task_checks as permissive for insert to authenticated with check (can_task(task_id));
create policy tc_read on public.task_checks as permissive for select to authenticated using (can_task(task_id));
create policy tc_update on public.task_checks as permissive for update to authenticated using (can_task(task_id)) with check (can_task(task_id));
create policy td_del on public.task_docs as permissive for delete to authenticated using (can_task(task_id));
create policy td_ins on public.task_docs as permissive for insert to authenticated with check (can_task(task_id));
create policy td_read on public.task_docs as permissive for select to authenticated using (can_task(task_id));
create policy td_upd on public.task_docs as permissive for update to authenticated using (can_task(task_id)) with check (can_task(task_id));
create policy tasks_delete on public.tasks as permissive for delete to authenticated using (is_partner());
create policy tasks_insert on public.tasks as permissive for insert to authenticated with check (is_manager());
create policy tasks_read on public.tasks as permissive for select to authenticated using ((is_manager() OR (assigned_to = auth.uid())));
create policy tasks_update on public.tasks as permissive for update to authenticated using ((is_manager() OR (assigned_to = auth.uid()))) with check ((is_manager() OR (assigned_to = auth.uid())));
create policy ti_del on public.tax_intimations as permissive for delete to authenticated using (is_manager());
create policy ti_ins on public.tax_intimations as permissive for insert to authenticated with check (can_client_login(client_id));
create policy ti_sel on public.tax_intimations as permissive for select to authenticated using (can_client_login(client_id));
create policy ti_upd on public.tax_intimations as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy tdc_del on public.tds_challans as permissive for delete to authenticated using (is_manager());
create policy tdc_ins on public.tds_challans as permissive for insert to authenticated with check (can_client_login(client_id));
create policy tdc_sel on public.tds_challans as permissive for select to authenticated using (can_client_login(client_id));
create policy tdc_upd on public.tds_challans as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy tde_del on public.tds_entries as permissive for delete to authenticated using (can_client_login(client_id));
create policy tde_ins on public.tds_entries as permissive for insert to authenticated with check (can_client_login(client_id));
create policy tde_sel on public.tds_entries as permissive for select to authenticated using (can_client_login(client_id));
create policy tde_upd on public.tds_entries as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy tdr_del on public.tds_returns as permissive for delete to authenticated using (is_manager());
create policy tdr_ins on public.tds_returns as permissive for insert to authenticated with check (can_client_login(client_id));
create policy tdr_sel on public.tds_returns as permissive for select to authenticated using (can_client_login(client_id));
create policy tdr_upd on public.tds_returns as permissive for update to authenticated using (can_client_login(client_id)) with check (can_client_login(client_id));
create policy wa_log_admin on public.wa_log as permissive for select to authenticated using (is_admin());
create policy wa_settings_admin on public.wa_settings as permissive for all to authenticated using (is_admin()) with check (is_admin());
create policy wr_del on public.work_requests as permissive for delete to authenticated using (is_manager());
create policy wr_ins on public.work_requests as permissive for insert to authenticated with check (is_manager());
create policy wr_sel on public.work_requests as permissive for select to authenticated using ((is_manager() OR (assigned_to = auth.uid()) OR (requested_by = auth.uid())));
create policy wr_upd on public.work_requests as permissive for update to authenticated using ((is_manager() OR (assigned_to = auth.uid()))) with check ((is_manager() OR (assigned_to = auth.uid())));
create policy zs_admin on public.zoho_settings as permissive for select to authenticated using (is_manager());
create policy zs_admin_upd on public.zoho_settings as permissive for update to authenticated using (is_admin()) with check (is_admin());
create policy "client-docs client upload" on storage.objects as permissive for insert to authenticated with check (((bucket_id = 'client-docs'::text) AND ((storage.foldername(name))[1] = (my_client_id())::text)));
create policy "client-docs read" on storage.objects as permissive for select to authenticated using (((bucket_id = 'client-docs'::text) AND (is_member() OR ((storage.foldername(name))[1] = (my_client_id())::text))));
create policy "filing acks add" on storage.objects as permissive for insert to authenticated with check (((bucket_id = 'filing-acks'::text) AND is_member()));
create policy "filing acks read" on storage.objects as permissive for select to authenticated using (((bucket_id = 'filing-acks'::text) AND (is_member() OR ((storage.foldername(name))[1] = (portal_client_id())::text))));
create policy "filing acks remove" on storage.objects as permissive for delete to authenticated using (((bucket_id = 'filing-acks'::text) AND is_manager()));

-- ==== tacl ====
revoke all on public.ai_settings from public, anon, authenticated; grant INSERT on public.ai_settings to service_role; grant SELECT on public.ai_settings to service_role; grant UPDATE on public.ai_settings to service_role; grant DELETE on public.ai_settings to service_role; grant TRUNCATE on public.ai_settings to service_role; grant REFERENCES on public.ai_settings to service_role; grant TRIGGER on public.ai_settings to service_role; grant MAINTAIN on public.ai_settings to service_role;
revoke all on public.ai_usage from public, anon, authenticated; grant INSERT on public.ai_usage to authenticated; grant SELECT on public.ai_usage to authenticated; grant UPDATE on public.ai_usage to authenticated; grant DELETE on public.ai_usage to authenticated; grant TRUNCATE on public.ai_usage to authenticated; grant REFERENCES on public.ai_usage to authenticated; grant TRIGGER on public.ai_usage to authenticated; grant MAINTAIN on public.ai_usage to authenticated; grant INSERT on public.ai_usage to service_role; grant SELECT on public.ai_usage to service_role; grant UPDATE on public.ai_usage to service_role; grant DELETE on public.ai_usage to service_role; grant TRUNCATE on public.ai_usage to service_role; grant REFERENCES on public.ai_usage to service_role; grant TRIGGER on public.ai_usage to service_role; grant MAINTAIN on public.ai_usage to service_role;
revoke all on public.audit_log from public, anon, authenticated; grant INSERT on public.audit_log to service_role; grant SELECT on public.audit_log to service_role; grant UPDATE on public.audit_log to service_role; grant DELETE on public.audit_log to service_role; grant TRUNCATE on public.audit_log to service_role; grant REFERENCES on public.audit_log to service_role; grant TRIGGER on public.audit_log to service_role; grant MAINTAIN on public.audit_log to service_role; grant SELECT on public.audit_log to authenticated;
revoke all on public.audit_log_id_seq from public, anon, authenticated; grant SELECT on public.audit_log_id_seq to anon; grant UPDATE on public.audit_log_id_seq to anon; grant USAGE on public.audit_log_id_seq to anon; grant SELECT on public.audit_log_id_seq to authenticated; grant UPDATE on public.audit_log_id_seq to authenticated; grant USAGE on public.audit_log_id_seq to authenticated; grant SELECT on public.audit_log_id_seq to service_role; grant UPDATE on public.audit_log_id_seq to service_role; grant USAGE on public.audit_log_id_seq to service_role;
revoke all on public.auto_work_done from public, anon, authenticated; grant INSERT on public.auto_work_done to service_role; grant SELECT on public.auto_work_done to service_role; grant UPDATE on public.auto_work_done to service_role; grant DELETE on public.auto_work_done to service_role; grant TRUNCATE on public.auto_work_done to service_role; grant REFERENCES on public.auto_work_done to service_role; grant TRIGGER on public.auto_work_done to service_role; grant MAINTAIN on public.auto_work_done to service_role;
revoke all on public.auto_work_settings from public, anon, authenticated; grant INSERT on public.auto_work_settings to service_role; grant SELECT on public.auto_work_settings to service_role; grant UPDATE on public.auto_work_settings to service_role; grant DELETE on public.auto_work_settings to service_role; grant TRUNCATE on public.auto_work_settings to service_role; grant REFERENCES on public.auto_work_settings to service_role; grant TRIGGER on public.auto_work_settings to service_role; grant MAINTAIN on public.auto_work_settings to service_role;
revoke all on public.backups from public, anon, authenticated; grant INSERT on public.backups to authenticated; grant SELECT on public.backups to authenticated; grant UPDATE on public.backups to authenticated; grant DELETE on public.backups to authenticated; grant TRUNCATE on public.backups to authenticated; grant REFERENCES on public.backups to authenticated; grant TRIGGER on public.backups to authenticated; grant MAINTAIN on public.backups to authenticated; grant INSERT on public.backups to service_role; grant SELECT on public.backups to service_role; grant UPDATE on public.backups to service_role; grant DELETE on public.backups to service_role; grant TRUNCATE on public.backups to service_role; grant REFERENCES on public.backups to service_role; grant TRIGGER on public.backups to service_role; grant MAINTAIN on public.backups to service_role;
revoke all on public.backups_id_seq from public, anon, authenticated; grant SELECT on public.backups_id_seq to anon; grant UPDATE on public.backups_id_seq to anon; grant USAGE on public.backups_id_seq to anon; grant SELECT on public.backups_id_seq to authenticated; grant UPDATE on public.backups_id_seq to authenticated; grant USAGE on public.backups_id_seq to authenticated; grant SELECT on public.backups_id_seq to service_role; grant UPDATE on public.backups_id_seq to service_role; grant USAGE on public.backups_id_seq to service_role;
revoke all on public.bank_rules from public, anon, authenticated; grant INSERT on public.bank_rules to authenticated; grant SELECT on public.bank_rules to authenticated; grant UPDATE on public.bank_rules to authenticated; grant DELETE on public.bank_rules to authenticated; grant TRUNCATE on public.bank_rules to authenticated; grant REFERENCES on public.bank_rules to authenticated; grant TRIGGER on public.bank_rules to authenticated; grant MAINTAIN on public.bank_rules to authenticated; grant INSERT on public.bank_rules to service_role; grant SELECT on public.bank_rules to service_role; grant UPDATE on public.bank_rules to service_role; grant DELETE on public.bank_rules to service_role; grant TRUNCATE on public.bank_rules to service_role; grant REFERENCES on public.bank_rules to service_role; grant TRIGGER on public.bank_rules to service_role; grant MAINTAIN on public.bank_rules to service_role;
revoke all on public.bank_statements from public, anon, authenticated; grant INSERT on public.bank_statements to authenticated; grant SELECT on public.bank_statements to authenticated; grant UPDATE on public.bank_statements to authenticated; grant DELETE on public.bank_statements to authenticated; grant TRUNCATE on public.bank_statements to authenticated; grant REFERENCES on public.bank_statements to authenticated; grant TRIGGER on public.bank_statements to authenticated; grant MAINTAIN on public.bank_statements to authenticated; grant INSERT on public.bank_statements to service_role; grant SELECT on public.bank_statements to service_role; grant UPDATE on public.bank_statements to service_role; grant DELETE on public.bank_statements to service_role; grant TRUNCATE on public.bank_statements to service_role; grant REFERENCES on public.bank_statements to service_role; grant TRIGGER on public.bank_statements to service_role; grant MAINTAIN on public.bank_statements to service_role;
revoke all on public.chase_log from public, anon, authenticated; grant INSERT on public.chase_log to authenticated; grant SELECT on public.chase_log to authenticated; grant UPDATE on public.chase_log to authenticated; grant DELETE on public.chase_log to authenticated; grant TRUNCATE on public.chase_log to authenticated; grant REFERENCES on public.chase_log to authenticated; grant TRIGGER on public.chase_log to authenticated; grant MAINTAIN on public.chase_log to authenticated; grant INSERT on public.chase_log to service_role; grant SELECT on public.chase_log to service_role; grant UPDATE on public.chase_log to service_role; grant DELETE on public.chase_log to service_role; grant TRUNCATE on public.chase_log to service_role; grant REFERENCES on public.chase_log to service_role; grant TRIGGER on public.chase_log to service_role; grant MAINTAIN on public.chase_log to service_role;
revoke all on public.chase_settings from public, anon, authenticated; grant INSERT on public.chase_settings to service_role; grant SELECT on public.chase_settings to service_role; grant UPDATE on public.chase_settings to service_role; grant DELETE on public.chase_settings to service_role; grant TRUNCATE on public.chase_settings to service_role; grant REFERENCES on public.chase_settings to service_role; grant TRIGGER on public.chase_settings to service_role; grant MAINTAIN on public.chase_settings to service_role;
revoke all on public.checklist_templates from public, anon, authenticated; grant INSERT on public.checklist_templates to authenticated; grant SELECT on public.checklist_templates to authenticated; grant UPDATE on public.checklist_templates to authenticated; grant DELETE on public.checklist_templates to authenticated; grant TRUNCATE on public.checklist_templates to authenticated; grant REFERENCES on public.checklist_templates to authenticated; grant TRIGGER on public.checklist_templates to authenticated; grant MAINTAIN on public.checklist_templates to authenticated; grant INSERT on public.checklist_templates to service_role; grant SELECT on public.checklist_templates to service_role; grant UPDATE on public.checklist_templates to service_role; grant DELETE on public.checklist_templates to service_role; grant TRUNCATE on public.checklist_templates to service_role; grant REFERENCES on public.checklist_templates to service_role; grant TRIGGER on public.checklist_templates to service_role; grant MAINTAIN on public.checklist_templates to service_role;
revoke all on public.client_logins from public, anon, authenticated; grant SELECT on public.client_logins to anon; grant TRUNCATE on public.client_logins to anon; grant REFERENCES on public.client_logins to anon; grant TRIGGER on public.client_logins to anon; grant MAINTAIN on public.client_logins to anon; grant SELECT on public.client_logins to authenticated; grant TRUNCATE on public.client_logins to authenticated; grant REFERENCES on public.client_logins to authenticated; grant TRIGGER on public.client_logins to authenticated; grant MAINTAIN on public.client_logins to authenticated; grant INSERT on public.client_logins to service_role; grant SELECT on public.client_logins to service_role; grant UPDATE on public.client_logins to service_role; grant DELETE on public.client_logins to service_role; grant TRUNCATE on public.client_logins to service_role; grant REFERENCES on public.client_logins to service_role; grant TRIGGER on public.client_logins to service_role; grant MAINTAIN on public.client_logins to service_role;
revoke all on public.client_reports from public, anon, authenticated; grant INSERT on public.client_reports to authenticated; grant SELECT on public.client_reports to authenticated; grant UPDATE on public.client_reports to authenticated; grant DELETE on public.client_reports to authenticated; grant TRUNCATE on public.client_reports to authenticated; grant REFERENCES on public.client_reports to authenticated; grant TRIGGER on public.client_reports to authenticated; grant MAINTAIN on public.client_reports to authenticated; grant INSERT on public.client_reports to service_role; grant SELECT on public.client_reports to service_role; grant UPDATE on public.client_reports to service_role; grant DELETE on public.client_reports to service_role; grant TRUNCATE on public.client_reports to service_role; grant REFERENCES on public.client_reports to service_role; grant TRIGGER on public.client_reports to service_role; grant MAINTAIN on public.client_reports to service_role;
revoke all on public.client_rules from public, anon, authenticated; grant INSERT on public.client_rules to anon; grant SELECT on public.client_rules to anon; grant UPDATE on public.client_rules to anon; grant DELETE on public.client_rules to anon; grant TRUNCATE on public.client_rules to anon; grant REFERENCES on public.client_rules to anon; grant TRIGGER on public.client_rules to anon; grant MAINTAIN on public.client_rules to anon; grant INSERT on public.client_rules to authenticated; grant SELECT on public.client_rules to authenticated; grant UPDATE on public.client_rules to authenticated; grant DELETE on public.client_rules to authenticated; grant TRUNCATE on public.client_rules to authenticated; grant REFERENCES on public.client_rules to authenticated; grant TRIGGER on public.client_rules to authenticated; grant MAINTAIN on public.client_rules to authenticated; grant INSERT on public.client_rules to service_role; grant SELECT on public.client_rules to service_role; grant UPDATE on public.client_rules to service_role; grant DELETE on public.client_rules to service_role; grant TRUNCATE on public.client_rules to service_role; grant REFERENCES on public.client_rules to service_role; grant TRIGGER on public.client_rules to service_role; grant MAINTAIN on public.client_rules to service_role;
revoke all on public.client_uploads from public, anon, authenticated; grant INSERT on public.client_uploads to authenticated; grant SELECT on public.client_uploads to authenticated; grant UPDATE on public.client_uploads to authenticated; grant DELETE on public.client_uploads to authenticated; grant TRUNCATE on public.client_uploads to authenticated; grant REFERENCES on public.client_uploads to authenticated; grant TRIGGER on public.client_uploads to authenticated; grant MAINTAIN on public.client_uploads to authenticated; grant INSERT on public.client_uploads to service_role; grant SELECT on public.client_uploads to service_role; grant UPDATE on public.client_uploads to service_role; grant DELETE on public.client_uploads to service_role; grant TRUNCATE on public.client_uploads to service_role; grant REFERENCES on public.client_uploads to service_role; grant TRIGGER on public.client_uploads to service_role; grant MAINTAIN on public.client_uploads to service_role;
revoke all on public.client_users from public, anon, authenticated; grant INSERT on public.client_users to authenticated; grant SELECT on public.client_users to authenticated; grant UPDATE on public.client_users to authenticated; grant DELETE on public.client_users to authenticated; grant TRUNCATE on public.client_users to authenticated; grant REFERENCES on public.client_users to authenticated; grant TRIGGER on public.client_users to authenticated; grant MAINTAIN on public.client_users to authenticated; grant INSERT on public.client_users to service_role; grant SELECT on public.client_users to service_role; grant UPDATE on public.client_users to service_role; grant DELETE on public.client_users to service_role; grant TRUNCATE on public.client_users to service_role; grant REFERENCES on public.client_users to service_role; grant TRIGGER on public.client_users to service_role; grant MAINTAIN on public.client_users to service_role;
revoke all on public.clients from public, anon, authenticated; grant INSERT on public.clients to authenticated; grant SELECT on public.clients to authenticated; grant UPDATE on public.clients to authenticated; grant DELETE on public.clients to authenticated; grant TRUNCATE on public.clients to authenticated; grant REFERENCES on public.clients to authenticated; grant TRIGGER on public.clients to authenticated; grant MAINTAIN on public.clients to authenticated; grant INSERT on public.clients to service_role; grant SELECT on public.clients to service_role; grant UPDATE on public.clients to service_role; grant DELETE on public.clients to service_role; grant TRUNCATE on public.clients to service_role; grant REFERENCES on public.clients to service_role; grant TRIGGER on public.clients to service_role; grant MAINTAIN on public.clients to service_role;
revoke all on public.data_request_log from public, anon, authenticated; grant INSERT on public.data_request_log to authenticated; grant SELECT on public.data_request_log to authenticated; grant UPDATE on public.data_request_log to authenticated; grant DELETE on public.data_request_log to authenticated; grant TRUNCATE on public.data_request_log to authenticated; grant REFERENCES on public.data_request_log to authenticated; grant TRIGGER on public.data_request_log to authenticated; grant MAINTAIN on public.data_request_log to authenticated; grant INSERT on public.data_request_log to service_role; grant SELECT on public.data_request_log to service_role; grant UPDATE on public.data_request_log to service_role; grant DELETE on public.data_request_log to service_role; grant TRUNCATE on public.data_request_log to service_role; grant REFERENCES on public.data_request_log to service_role; grant TRIGGER on public.data_request_log to service_role; grant MAINTAIN on public.data_request_log to service_role;
revoke all on public.data_request_settings from public, anon, authenticated; grant INSERT on public.data_request_settings to service_role; grant SELECT on public.data_request_settings to service_role; grant UPDATE on public.data_request_settings to service_role; grant DELETE on public.data_request_settings to service_role; grant TRUNCATE on public.data_request_settings to service_role; grant REFERENCES on public.data_request_settings to service_role; grant TRIGGER on public.data_request_settings to service_role; grant MAINTAIN on public.data_request_settings to service_role;
revoke all on public.data_request_templates from public, anon, authenticated; grant INSERT on public.data_request_templates to service_role; grant SELECT on public.data_request_templates to service_role; grant UPDATE on public.data_request_templates to service_role; grant DELETE on public.data_request_templates to service_role; grant TRUNCATE on public.data_request_templates to service_role; grant REFERENCES on public.data_request_templates to service_role; grant TRIGGER on public.data_request_templates to service_role; grant MAINTAIN on public.data_request_templates to service_role;
revoke all on public.demo_rows from public, anon, authenticated; grant INSERT on public.demo_rows to anon; grant SELECT on public.demo_rows to anon; grant UPDATE on public.demo_rows to anon; grant DELETE on public.demo_rows to anon; grant TRUNCATE on public.demo_rows to anon; grant REFERENCES on public.demo_rows to anon; grant TRIGGER on public.demo_rows to anon; grant MAINTAIN on public.demo_rows to anon; grant INSERT on public.demo_rows to authenticated; grant SELECT on public.demo_rows to authenticated; grant UPDATE on public.demo_rows to authenticated; grant DELETE on public.demo_rows to authenticated; grant TRUNCATE on public.demo_rows to authenticated; grant REFERENCES on public.demo_rows to authenticated; grant TRIGGER on public.demo_rows to authenticated; grant MAINTAIN on public.demo_rows to authenticated; grant INSERT on public.demo_rows to service_role; grant SELECT on public.demo_rows to service_role; grant UPDATE on public.demo_rows to service_role; grant DELETE on public.demo_rows to service_role; grant TRUNCATE on public.demo_rows to service_role; grant REFERENCES on public.demo_rows to service_role; grant TRIGGER on public.demo_rows to service_role; grant MAINTAIN on public.demo_rows to service_role;
revoke all on public.due_dates from public, anon, authenticated; grant INSERT on public.due_dates to authenticated; grant SELECT on public.due_dates to authenticated; grant UPDATE on public.due_dates to authenticated; grant DELETE on public.due_dates to authenticated; grant TRUNCATE on public.due_dates to authenticated; grant REFERENCES on public.due_dates to authenticated; grant TRIGGER on public.due_dates to authenticated; grant MAINTAIN on public.due_dates to authenticated; grant INSERT on public.due_dates to service_role; grant SELECT on public.due_dates to service_role; grant UPDATE on public.due_dates to service_role; grant DELETE on public.due_dates to service_role; grant TRUNCATE on public.due_dates to service_role; grant REFERENCES on public.due_dates to service_role; grant TRIGGER on public.due_dates to service_role; grant MAINTAIN on public.due_dates to service_role;
revoke all on public.due_dates_id_seq from public, anon, authenticated; grant SELECT on public.due_dates_id_seq to anon; grant UPDATE on public.due_dates_id_seq to anon; grant USAGE on public.due_dates_id_seq to anon; grant SELECT on public.due_dates_id_seq to authenticated; grant UPDATE on public.due_dates_id_seq to authenticated; grant USAGE on public.due_dates_id_seq to authenticated; grant SELECT on public.due_dates_id_seq to service_role; grant UPDATE on public.due_dates_id_seq to service_role; grant USAGE on public.due_dates_id_seq to service_role;
revoke all on public.fee_rates from public, anon, authenticated; grant INSERT on public.fee_rates to authenticated; grant SELECT on public.fee_rates to authenticated; grant UPDATE on public.fee_rates to authenticated; grant DELETE on public.fee_rates to authenticated; grant TRUNCATE on public.fee_rates to authenticated; grant REFERENCES on public.fee_rates to authenticated; grant TRIGGER on public.fee_rates to authenticated; grant MAINTAIN on public.fee_rates to authenticated; grant INSERT on public.fee_rates to service_role; grant SELECT on public.fee_rates to service_role; grant UPDATE on public.fee_rates to service_role; grant DELETE on public.fee_rates to service_role; grant TRUNCATE on public.fee_rates to service_role; grant REFERENCES on public.fee_rates to service_role; grant TRIGGER on public.fee_rates to service_role; grant MAINTAIN on public.fee_rates to service_role;
revoke all on public.fee_rates_id_seq from public, anon, authenticated; grant SELECT on public.fee_rates_id_seq to anon; grant UPDATE on public.fee_rates_id_seq to anon; grant USAGE on public.fee_rates_id_seq to anon; grant SELECT on public.fee_rates_id_seq to authenticated; grant UPDATE on public.fee_rates_id_seq to authenticated; grant USAGE on public.fee_rates_id_seq to authenticated; grant SELECT on public.fee_rates_id_seq to service_role; grant UPDATE on public.fee_rates_id_seq to service_role; grant USAGE on public.fee_rates_id_seq to service_role;
revoke all on public.filing_acks from public, anon, authenticated; grant INSERT on public.filing_acks to authenticated; grant SELECT on public.filing_acks to authenticated; grant UPDATE on public.filing_acks to authenticated; grant DELETE on public.filing_acks to authenticated; grant TRUNCATE on public.filing_acks to authenticated; grant REFERENCES on public.filing_acks to authenticated; grant TRIGGER on public.filing_acks to authenticated; grant MAINTAIN on public.filing_acks to authenticated; grant INSERT on public.filing_acks to service_role; grant SELECT on public.filing_acks to service_role; grant UPDATE on public.filing_acks to service_role; grant DELETE on public.filing_acks to service_role; grant TRUNCATE on public.filing_acks to service_role; grant REFERENCES on public.filing_acks to service_role; grant TRIGGER on public.filing_acks to service_role; grant MAINTAIN on public.filing_acks to service_role;
revoke all on public.followups from public, anon, authenticated; grant INSERT on public.followups to anon; grant SELECT on public.followups to anon; grant UPDATE on public.followups to anon; grant DELETE on public.followups to anon; grant TRUNCATE on public.followups to anon; grant REFERENCES on public.followups to anon; grant TRIGGER on public.followups to anon; grant MAINTAIN on public.followups to anon; grant INSERT on public.followups to authenticated; grant SELECT on public.followups to authenticated; grant UPDATE on public.followups to authenticated; grant DELETE on public.followups to authenticated; grant TRUNCATE on public.followups to authenticated; grant REFERENCES on public.followups to authenticated; grant TRIGGER on public.followups to authenticated; grant MAINTAIN on public.followups to authenticated; grant INSERT on public.followups to service_role; grant SELECT on public.followups to service_role; grant UPDATE on public.followups to service_role; grant DELETE on public.followups to service_role; grant TRUNCATE on public.followups to service_role; grant REFERENCES on public.followups to service_role; grant TRIGGER on public.followups to service_role; grant MAINTAIN on public.followups to service_role;
revoke all on public.gst_checks from public, anon, authenticated; grant INSERT on public.gst_checks to service_role; grant SELECT on public.gst_checks to service_role; grant UPDATE on public.gst_checks to service_role; grant DELETE on public.gst_checks to service_role; grant TRUNCATE on public.gst_checks to service_role; grant REFERENCES on public.gst_checks to service_role; grant TRIGGER on public.gst_checks to service_role; grant MAINTAIN on public.gst_checks to service_role;
revoke all on public.gst_checks_id_seq from public, anon, authenticated; grant SELECT on public.gst_checks_id_seq to anon; grant UPDATE on public.gst_checks_id_seq to anon; grant USAGE on public.gst_checks_id_seq to anon; grant SELECT on public.gst_checks_id_seq to authenticated; grant UPDATE on public.gst_checks_id_seq to authenticated; grant USAGE on public.gst_checks_id_seq to authenticated; grant SELECT on public.gst_checks_id_seq to service_role; grant UPDATE on public.gst_checks_id_seq to service_role; grant USAGE on public.gst_checks_id_seq to service_role;
revoke all on public.gst_months from public, anon, authenticated; grant INSERT on public.gst_months to anon; grant SELECT on public.gst_months to anon; grant UPDATE on public.gst_months to anon; grant DELETE on public.gst_months to anon; grant TRUNCATE on public.gst_months to anon; grant REFERENCES on public.gst_months to anon; grant TRIGGER on public.gst_months to anon; grant MAINTAIN on public.gst_months to anon; grant INSERT on public.gst_months to authenticated; grant SELECT on public.gst_months to authenticated; grant UPDATE on public.gst_months to authenticated; grant DELETE on public.gst_months to authenticated; grant TRUNCATE on public.gst_months to authenticated; grant REFERENCES on public.gst_months to authenticated; grant TRIGGER on public.gst_months to authenticated; grant MAINTAIN on public.gst_months to authenticated; grant INSERT on public.gst_months to service_role; grant SELECT on public.gst_months to service_role; grant UPDATE on public.gst_months to service_role; grant DELETE on public.gst_months to service_role; grant TRUNCATE on public.gst_months to service_role; grant REFERENCES on public.gst_months to service_role; grant TRIGGER on public.gst_months to service_role; grant MAINTAIN on public.gst_months to service_role;
revoke all on public.gst_reviews from public, anon, authenticated; grant INSERT on public.gst_reviews to anon; grant SELECT on public.gst_reviews to anon; grant UPDATE on public.gst_reviews to anon; grant DELETE on public.gst_reviews to anon; grant TRUNCATE on public.gst_reviews to anon; grant REFERENCES on public.gst_reviews to anon; grant TRIGGER on public.gst_reviews to anon; grant MAINTAIN on public.gst_reviews to anon; grant INSERT on public.gst_reviews to authenticated; grant SELECT on public.gst_reviews to authenticated; grant UPDATE on public.gst_reviews to authenticated; grant DELETE on public.gst_reviews to authenticated; grant TRUNCATE on public.gst_reviews to authenticated; grant REFERENCES on public.gst_reviews to authenticated; grant TRIGGER on public.gst_reviews to authenticated; grant MAINTAIN on public.gst_reviews to authenticated; grant INSERT on public.gst_reviews to service_role; grant SELECT on public.gst_reviews to service_role; grant UPDATE on public.gst_reviews to service_role; grant DELETE on public.gst_reviews to service_role; grant TRUNCATE on public.gst_reviews to service_role; grant REFERENCES on public.gst_reviews to service_role; grant TRIGGER on public.gst_reviews to service_role; grant MAINTAIN on public.gst_reviews to service_role;
revoke all on public.gst_settings from public, anon, authenticated; grant INSERT on public.gst_settings to service_role; grant SELECT on public.gst_settings to service_role; grant UPDATE on public.gst_settings to service_role; grant DELETE on public.gst_settings to service_role; grant TRUNCATE on public.gst_settings to service_role; grant REFERENCES on public.gst_settings to service_role; grant TRIGGER on public.gst_settings to service_role; grant MAINTAIN on public.gst_settings to service_role;
revoke all on public.gst_tp_sessions from public, anon, authenticated; grant INSERT on public.gst_tp_sessions to service_role; grant SELECT on public.gst_tp_sessions to service_role; grant UPDATE on public.gst_tp_sessions to service_role; grant DELETE on public.gst_tp_sessions to service_role; grant TRUNCATE on public.gst_tp_sessions to service_role; grant REFERENCES on public.gst_tp_sessions to service_role; grant TRIGGER on public.gst_tp_sessions to service_role; grant MAINTAIN on public.gst_tp_sessions to service_role;
revoke all on public.invoices from public, anon, authenticated; grant INSERT on public.invoices to authenticated; grant SELECT on public.invoices to authenticated; grant UPDATE on public.invoices to authenticated; grant DELETE on public.invoices to authenticated; grant TRUNCATE on public.invoices to authenticated; grant REFERENCES on public.invoices to authenticated; grant TRIGGER on public.invoices to authenticated; grant MAINTAIN on public.invoices to authenticated; grant INSERT on public.invoices to service_role; grant SELECT on public.invoices to service_role; grant UPDATE on public.invoices to service_role; grant DELETE on public.invoices to service_role; grant TRUNCATE on public.invoices to service_role; grant REFERENCES on public.invoices to service_role; grant TRIGGER on public.invoices to service_role; grant MAINTAIN on public.invoices to service_role;
revoke all on public.law_updates from public, anon, authenticated; grant INSERT on public.law_updates to authenticated; grant SELECT on public.law_updates to authenticated; grant UPDATE on public.law_updates to authenticated; grant DELETE on public.law_updates to authenticated; grant TRUNCATE on public.law_updates to authenticated; grant REFERENCES on public.law_updates to authenticated; grant TRIGGER on public.law_updates to authenticated; grant MAINTAIN on public.law_updates to authenticated; grant INSERT on public.law_updates to service_role; grant SELECT on public.law_updates to service_role; grant UPDATE on public.law_updates to service_role; grant DELETE on public.law_updates to service_role; grant TRUNCATE on public.law_updates to service_role; grant REFERENCES on public.law_updates to service_role; grant TRIGGER on public.law_updates to service_role; grant MAINTAIN on public.law_updates to service_role;
revoke all on public.linked_rules from public, anon, authenticated; grant INSERT on public.linked_rules to authenticated; grant SELECT on public.linked_rules to authenticated; grant UPDATE on public.linked_rules to authenticated; grant DELETE on public.linked_rules to authenticated; grant TRUNCATE on public.linked_rules to authenticated; grant REFERENCES on public.linked_rules to authenticated; grant TRIGGER on public.linked_rules to authenticated; grant MAINTAIN on public.linked_rules to authenticated; grant INSERT on public.linked_rules to service_role; grant SELECT on public.linked_rules to service_role; grant UPDATE on public.linked_rules to service_role; grant DELETE on public.linked_rules to service_role; grant TRUNCATE on public.linked_rules to service_role; grant REFERENCES on public.linked_rules to service_role; grant TRIGGER on public.linked_rules to service_role; grant MAINTAIN on public.linked_rules to service_role;
revoke all on public.login_access_log from public, anon, authenticated; grant SELECT on public.login_access_log to anon; grant TRUNCATE on public.login_access_log to anon; grant REFERENCES on public.login_access_log to anon; grant TRIGGER on public.login_access_log to anon; grant MAINTAIN on public.login_access_log to anon; grant SELECT on public.login_access_log to authenticated; grant TRUNCATE on public.login_access_log to authenticated; grant REFERENCES on public.login_access_log to authenticated; grant TRIGGER on public.login_access_log to authenticated; grant MAINTAIN on public.login_access_log to authenticated; grant INSERT on public.login_access_log to service_role; grant SELECT on public.login_access_log to service_role; grant UPDATE on public.login_access_log to service_role; grant DELETE on public.login_access_log to service_role; grant TRUNCATE on public.login_access_log to service_role; grant REFERENCES on public.login_access_log to service_role; grant TRIGGER on public.login_access_log to service_role; grant MAINTAIN on public.login_access_log to service_role;
revoke all on public.login_access_log_id_seq from public, anon, authenticated; grant SELECT on public.login_access_log_id_seq to anon; grant UPDATE on public.login_access_log_id_seq to anon; grant USAGE on public.login_access_log_id_seq to anon; grant SELECT on public.login_access_log_id_seq to authenticated; grant UPDATE on public.login_access_log_id_seq to authenticated; grant USAGE on public.login_access_log_id_seq to authenticated; grant SELECT on public.login_access_log_id_seq to service_role; grant UPDATE on public.login_access_log_id_seq to service_role; grant USAGE on public.login_access_log_id_seq to service_role;
revoke all on public.mail_inbox from public, anon, authenticated; grant INSERT on public.mail_inbox to authenticated; grant SELECT on public.mail_inbox to authenticated; grant UPDATE on public.mail_inbox to authenticated; grant DELETE on public.mail_inbox to authenticated; grant TRUNCATE on public.mail_inbox to authenticated; grant REFERENCES on public.mail_inbox to authenticated; grant TRIGGER on public.mail_inbox to authenticated; grant MAINTAIN on public.mail_inbox to authenticated; grant INSERT on public.mail_inbox to service_role; grant SELECT on public.mail_inbox to service_role; grant UPDATE on public.mail_inbox to service_role; grant DELETE on public.mail_inbox to service_role; grant TRUNCATE on public.mail_inbox to service_role; grant REFERENCES on public.mail_inbox to service_role; grant TRIGGER on public.mail_inbox to service_role; grant MAINTAIN on public.mail_inbox to service_role;
revoke all on public.mail_jobs from public, anon, authenticated; grant INSERT on public.mail_jobs to anon; grant SELECT on public.mail_jobs to anon; grant UPDATE on public.mail_jobs to anon; grant DELETE on public.mail_jobs to anon; grant TRUNCATE on public.mail_jobs to anon; grant REFERENCES on public.mail_jobs to anon; grant TRIGGER on public.mail_jobs to anon; grant MAINTAIN on public.mail_jobs to anon; grant INSERT on public.mail_jobs to authenticated; grant SELECT on public.mail_jobs to authenticated; grant UPDATE on public.mail_jobs to authenticated; grant DELETE on public.mail_jobs to authenticated; grant TRUNCATE on public.mail_jobs to authenticated; grant REFERENCES on public.mail_jobs to authenticated; grant TRIGGER on public.mail_jobs to authenticated; grant MAINTAIN on public.mail_jobs to authenticated; grant INSERT on public.mail_jobs to service_role; grant SELECT on public.mail_jobs to service_role; grant UPDATE on public.mail_jobs to service_role; grant DELETE on public.mail_jobs to service_role; grant TRUNCATE on public.mail_jobs to service_role; grant REFERENCES on public.mail_jobs to service_role; grant TRIGGER on public.mail_jobs to service_role; grant MAINTAIN on public.mail_jobs to service_role;
revoke all on public.mail_jobs_id_seq from public, anon, authenticated; grant SELECT on public.mail_jobs_id_seq to anon; grant UPDATE on public.mail_jobs_id_seq to anon; grant USAGE on public.mail_jobs_id_seq to anon; grant SELECT on public.mail_jobs_id_seq to authenticated; grant UPDATE on public.mail_jobs_id_seq to authenticated; grant USAGE on public.mail_jobs_id_seq to authenticated; grant SELECT on public.mail_jobs_id_seq to service_role; grant UPDATE on public.mail_jobs_id_seq to service_role; grant USAGE on public.mail_jobs_id_seq to service_role;
revoke all on public.mail_settings from public, anon, authenticated; grant INSERT on public.mail_settings to service_role; grant SELECT on public.mail_settings to service_role; grant UPDATE on public.mail_settings to service_role; grant DELETE on public.mail_settings to service_role; grant TRUNCATE on public.mail_settings to service_role; grant REFERENCES on public.mail_settings to service_role; grant TRIGGER on public.mail_settings to service_role; grant MAINTAIN on public.mail_settings to service_role;
revoke all on public.mca_companies from public, anon, authenticated; grant INSERT on public.mca_companies to authenticated; grant SELECT on public.mca_companies to authenticated; grant UPDATE on public.mca_companies to authenticated; grant DELETE on public.mca_companies to authenticated; grant TRUNCATE on public.mca_companies to authenticated; grant REFERENCES on public.mca_companies to authenticated; grant TRIGGER on public.mca_companies to authenticated; grant MAINTAIN on public.mca_companies to authenticated; grant INSERT on public.mca_companies to service_role; grant SELECT on public.mca_companies to service_role; grant UPDATE on public.mca_companies to service_role; grant DELETE on public.mca_companies to service_role; grant TRUNCATE on public.mca_companies to service_role; grant REFERENCES on public.mca_companies to service_role; grant TRIGGER on public.mca_companies to service_role; grant MAINTAIN on public.mca_companies to service_role;
revoke all on public.mca_directors from public, anon, authenticated; grant INSERT on public.mca_directors to authenticated; grant SELECT on public.mca_directors to authenticated; grant UPDATE on public.mca_directors to authenticated; grant DELETE on public.mca_directors to authenticated; grant TRUNCATE on public.mca_directors to authenticated; grant REFERENCES on public.mca_directors to authenticated; grant TRIGGER on public.mca_directors to authenticated; grant MAINTAIN on public.mca_directors to authenticated; grant INSERT on public.mca_directors to service_role; grant SELECT on public.mca_directors to service_role; grant UPDATE on public.mca_directors to service_role; grant DELETE on public.mca_directors to service_role; grant TRUNCATE on public.mca_directors to service_role; grant REFERENCES on public.mca_directors to service_role; grant TRIGGER on public.mca_directors to service_role; grant MAINTAIN on public.mca_directors to service_role;
revoke all on public.notice_mails from public, anon, authenticated; grant INSERT on public.notice_mails to authenticated; grant SELECT on public.notice_mails to authenticated; grant UPDATE on public.notice_mails to authenticated; grant DELETE on public.notice_mails to authenticated; grant TRUNCATE on public.notice_mails to authenticated; grant REFERENCES on public.notice_mails to authenticated; grant TRIGGER on public.notice_mails to authenticated; grant MAINTAIN on public.notice_mails to authenticated; grant INSERT on public.notice_mails to service_role; grant SELECT on public.notice_mails to service_role; grant UPDATE on public.notice_mails to service_role; grant DELETE on public.notice_mails to service_role; grant TRUNCATE on public.notice_mails to service_role; grant REFERENCES on public.notice_mails to service_role; grant TRIGGER on public.notice_mails to service_role; grant MAINTAIN on public.notice_mails to service_role;
revoke all on public.notice_watch from public, anon, authenticated; grant INSERT on public.notice_watch to service_role; grant SELECT on public.notice_watch to service_role; grant UPDATE on public.notice_watch to service_role; grant DELETE on public.notice_watch to service_role; grant TRUNCATE on public.notice_watch to service_role; grant REFERENCES on public.notice_watch to service_role; grant TRIGGER on public.notice_watch to service_role; grant MAINTAIN on public.notice_watch to service_role;
revoke all on public.notices from public, anon, authenticated; grant INSERT on public.notices to authenticated; grant SELECT on public.notices to authenticated; grant UPDATE on public.notices to authenticated; grant DELETE on public.notices to authenticated; grant TRUNCATE on public.notices to authenticated; grant REFERENCES on public.notices to authenticated; grant TRIGGER on public.notices to authenticated; grant MAINTAIN on public.notices to authenticated; grant INSERT on public.notices to service_role; grant SELECT on public.notices to service_role; grant UPDATE on public.notices to service_role; grant DELETE on public.notices to service_role; grant TRUNCATE on public.notices to service_role; grant REFERENCES on public.notices to service_role; grant TRIGGER on public.notices to service_role; grant MAINTAIN on public.notices to service_role;
revoke all on public.onboarding from public, anon, authenticated; grant INSERT on public.onboarding to authenticated; grant SELECT on public.onboarding to authenticated; grant UPDATE on public.onboarding to authenticated; grant DELETE on public.onboarding to authenticated; grant TRUNCATE on public.onboarding to authenticated; grant REFERENCES on public.onboarding to authenticated; grant TRIGGER on public.onboarding to authenticated; grant MAINTAIN on public.onboarding to authenticated; grant INSERT on public.onboarding to service_role; grant SELECT on public.onboarding to service_role; grant UPDATE on public.onboarding to service_role; grant DELETE on public.onboarding to service_role; grant TRUNCATE on public.onboarding to service_role; grant REFERENCES on public.onboarding to service_role; grant TRIGGER on public.onboarding to service_role; grant MAINTAIN on public.onboarding to service_role;
revoke all on public.payment_claims from public, anon, authenticated; grant INSERT on public.payment_claims to authenticated; grant SELECT on public.payment_claims to authenticated; grant UPDATE on public.payment_claims to authenticated; grant DELETE on public.payment_claims to authenticated; grant TRUNCATE on public.payment_claims to authenticated; grant REFERENCES on public.payment_claims to authenticated; grant TRIGGER on public.payment_claims to authenticated; grant MAINTAIN on public.payment_claims to authenticated; grant INSERT on public.payment_claims to service_role; grant SELECT on public.payment_claims to service_role; grant UPDATE on public.payment_claims to service_role; grant DELETE on public.payment_claims to service_role; grant TRUNCATE on public.payment_claims to service_role; grant REFERENCES on public.payment_claims to service_role; grant TRIGGER on public.payment_claims to service_role; grant MAINTAIN on public.payment_claims to service_role;
revoke all on public.payments from public, anon, authenticated; grant INSERT on public.payments to authenticated; grant SELECT on public.payments to authenticated; grant UPDATE on public.payments to authenticated; grant DELETE on public.payments to authenticated; grant TRUNCATE on public.payments to authenticated; grant REFERENCES on public.payments to authenticated; grant TRIGGER on public.payments to authenticated; grant MAINTAIN on public.payments to authenticated; grant INSERT on public.payments to service_role; grant SELECT on public.payments to service_role; grant UPDATE on public.payments to service_role; grant DELETE on public.payments to service_role; grant TRUNCATE on public.payments to service_role; grant REFERENCES on public.payments to service_role; grant TRIGGER on public.payments to service_role; grant MAINTAIN on public.payments to service_role;
revoke all on public.profiles from public, anon, authenticated; grant INSERT on public.profiles to authenticated; grant SELECT on public.profiles to authenticated; grant UPDATE on public.profiles to authenticated; grant DELETE on public.profiles to authenticated; grant TRUNCATE on public.profiles to authenticated; grant REFERENCES on public.profiles to authenticated; grant TRIGGER on public.profiles to authenticated; grant MAINTAIN on public.profiles to authenticated; grant INSERT on public.profiles to service_role; grant SELECT on public.profiles to service_role; grant UPDATE on public.profiles to service_role; grant DELETE on public.profiles to service_role; grant TRUNCATE on public.profiles to service_role; grant REFERENCES on public.profiles to service_role; grant TRIGGER on public.profiles to service_role; grant MAINTAIN on public.profiles to service_role;
revoke all on public.renewals from public, anon, authenticated; grant INSERT on public.renewals to authenticated; grant SELECT on public.renewals to authenticated; grant UPDATE on public.renewals to authenticated; grant DELETE on public.renewals to authenticated; grant TRUNCATE on public.renewals to authenticated; grant REFERENCES on public.renewals to authenticated; grant TRIGGER on public.renewals to authenticated; grant MAINTAIN on public.renewals to authenticated; grant INSERT on public.renewals to service_role; grant SELECT on public.renewals to service_role; grant UPDATE on public.renewals to service_role; grant DELETE on public.renewals to service_role; grant TRUNCATE on public.renewals to service_role; grant REFERENCES on public.renewals to service_role; grant TRIGGER on public.renewals to service_role; grant MAINTAIN on public.renewals to service_role;
revoke all on public.settings from public, anon, authenticated; grant INSERT on public.settings to authenticated; grant SELECT on public.settings to authenticated; grant UPDATE on public.settings to authenticated; grant DELETE on public.settings to authenticated; grant TRUNCATE on public.settings to authenticated; grant REFERENCES on public.settings to authenticated; grant TRIGGER on public.settings to authenticated; grant MAINTAIN on public.settings to authenticated; grant INSERT on public.settings to service_role; grant SELECT on public.settings to service_role; grant UPDATE on public.settings to service_role; grant DELETE on public.settings to service_role; grant TRUNCATE on public.settings to service_role; grant REFERENCES on public.settings to service_role; grant TRIGGER on public.settings to service_role; grant MAINTAIN on public.settings to service_role;
revoke all on public.task_checks from public, anon, authenticated; grant INSERT on public.task_checks to authenticated; grant SELECT on public.task_checks to authenticated; grant UPDATE on public.task_checks to authenticated; grant DELETE on public.task_checks to authenticated; grant TRUNCATE on public.task_checks to authenticated; grant REFERENCES on public.task_checks to authenticated; grant TRIGGER on public.task_checks to authenticated; grant MAINTAIN on public.task_checks to authenticated; grant INSERT on public.task_checks to service_role; grant SELECT on public.task_checks to service_role; grant UPDATE on public.task_checks to service_role; grant DELETE on public.task_checks to service_role; grant TRUNCATE on public.task_checks to service_role; grant REFERENCES on public.task_checks to service_role; grant TRIGGER on public.task_checks to service_role; grant MAINTAIN on public.task_checks to service_role;
revoke all on public.task_docs from public, anon, authenticated; grant INSERT on public.task_docs to authenticated; grant SELECT on public.task_docs to authenticated; grant UPDATE on public.task_docs to authenticated; grant DELETE on public.task_docs to authenticated; grant TRUNCATE on public.task_docs to authenticated; grant REFERENCES on public.task_docs to authenticated; grant TRIGGER on public.task_docs to authenticated; grant MAINTAIN on public.task_docs to authenticated; grant INSERT on public.task_docs to service_role; grant SELECT on public.task_docs to service_role; grant UPDATE on public.task_docs to service_role; grant DELETE on public.task_docs to service_role; grant TRUNCATE on public.task_docs to service_role; grant REFERENCES on public.task_docs to service_role; grant TRIGGER on public.task_docs to service_role; grant MAINTAIN on public.task_docs to service_role;
revoke all on public.tasks from public, anon, authenticated; grant INSERT on public.tasks to authenticated; grant SELECT on public.tasks to authenticated; grant UPDATE on public.tasks to authenticated; grant DELETE on public.tasks to authenticated; grant TRUNCATE on public.tasks to authenticated; grant REFERENCES on public.tasks to authenticated; grant TRIGGER on public.tasks to authenticated; grant MAINTAIN on public.tasks to authenticated; grant INSERT on public.tasks to service_role; grant SELECT on public.tasks to service_role; grant UPDATE on public.tasks to service_role; grant DELETE on public.tasks to service_role; grant TRUNCATE on public.tasks to service_role; grant REFERENCES on public.tasks to service_role; grant TRIGGER on public.tasks to service_role; grant MAINTAIN on public.tasks to service_role;
revoke all on public.tax_intimations from public, anon, authenticated; grant INSERT on public.tax_intimations to authenticated; grant SELECT on public.tax_intimations to authenticated; grant UPDATE on public.tax_intimations to authenticated; grant DELETE on public.tax_intimations to authenticated; grant TRUNCATE on public.tax_intimations to authenticated; grant REFERENCES on public.tax_intimations to authenticated; grant TRIGGER on public.tax_intimations to authenticated; grant MAINTAIN on public.tax_intimations to authenticated; grant INSERT on public.tax_intimations to service_role; grant SELECT on public.tax_intimations to service_role; grant UPDATE on public.tax_intimations to service_role; grant DELETE on public.tax_intimations to service_role; grant TRUNCATE on public.tax_intimations to service_role; grant REFERENCES on public.tax_intimations to service_role; grant TRIGGER on public.tax_intimations to service_role; grant MAINTAIN on public.tax_intimations to service_role;
revoke all on public.tds_challans from public, anon, authenticated; grant INSERT on public.tds_challans to authenticated; grant SELECT on public.tds_challans to authenticated; grant UPDATE on public.tds_challans to authenticated; grant DELETE on public.tds_challans to authenticated; grant TRUNCATE on public.tds_challans to authenticated; grant REFERENCES on public.tds_challans to authenticated; grant TRIGGER on public.tds_challans to authenticated; grant MAINTAIN on public.tds_challans to authenticated; grant INSERT on public.tds_challans to service_role; grant SELECT on public.tds_challans to service_role; grant UPDATE on public.tds_challans to service_role; grant DELETE on public.tds_challans to service_role; grant TRUNCATE on public.tds_challans to service_role; grant REFERENCES on public.tds_challans to service_role; grant TRIGGER on public.tds_challans to service_role; grant MAINTAIN on public.tds_challans to service_role;
revoke all on public.tds_entries from public, anon, authenticated; grant INSERT on public.tds_entries to authenticated; grant SELECT on public.tds_entries to authenticated; grant UPDATE on public.tds_entries to authenticated; grant DELETE on public.tds_entries to authenticated; grant TRUNCATE on public.tds_entries to authenticated; grant REFERENCES on public.tds_entries to authenticated; grant TRIGGER on public.tds_entries to authenticated; grant MAINTAIN on public.tds_entries to authenticated; grant INSERT on public.tds_entries to service_role; grant SELECT on public.tds_entries to service_role; grant UPDATE on public.tds_entries to service_role; grant DELETE on public.tds_entries to service_role; grant TRUNCATE on public.tds_entries to service_role; grant REFERENCES on public.tds_entries to service_role; grant TRIGGER on public.tds_entries to service_role; grant MAINTAIN on public.tds_entries to service_role;
revoke all on public.tds_returns from public, anon, authenticated; grant INSERT on public.tds_returns to authenticated; grant SELECT on public.tds_returns to authenticated; grant UPDATE on public.tds_returns to authenticated; grant DELETE on public.tds_returns to authenticated; grant TRUNCATE on public.tds_returns to authenticated; grant REFERENCES on public.tds_returns to authenticated; grant TRIGGER on public.tds_returns to authenticated; grant MAINTAIN on public.tds_returns to authenticated; grant INSERT on public.tds_returns to service_role; grant SELECT on public.tds_returns to service_role; grant UPDATE on public.tds_returns to service_role; grant DELETE on public.tds_returns to service_role; grant TRUNCATE on public.tds_returns to service_role; grant REFERENCES on public.tds_returns to service_role; grant TRIGGER on public.tds_returns to service_role; grant MAINTAIN on public.tds_returns to service_role;
revoke all on public.wa_log from public, anon, authenticated; grant INSERT on public.wa_log to authenticated; grant SELECT on public.wa_log to authenticated; grant UPDATE on public.wa_log to authenticated; grant DELETE on public.wa_log to authenticated; grant TRUNCATE on public.wa_log to authenticated; grant REFERENCES on public.wa_log to authenticated; grant TRIGGER on public.wa_log to authenticated; grant MAINTAIN on public.wa_log to authenticated; grant INSERT on public.wa_log to service_role; grant SELECT on public.wa_log to service_role; grant UPDATE on public.wa_log to service_role; grant DELETE on public.wa_log to service_role; grant TRUNCATE on public.wa_log to service_role; grant REFERENCES on public.wa_log to service_role; grant TRIGGER on public.wa_log to service_role; grant MAINTAIN on public.wa_log to service_role;
revoke all on public.wa_log_id_seq from public, anon, authenticated; grant SELECT on public.wa_log_id_seq to anon; grant UPDATE on public.wa_log_id_seq to anon; grant USAGE on public.wa_log_id_seq to anon; grant SELECT on public.wa_log_id_seq to authenticated; grant UPDATE on public.wa_log_id_seq to authenticated; grant USAGE on public.wa_log_id_seq to authenticated; grant SELECT on public.wa_log_id_seq to service_role; grant UPDATE on public.wa_log_id_seq to service_role; grant USAGE on public.wa_log_id_seq to service_role;
revoke all on public.wa_settings from public, anon, authenticated; grant INSERT on public.wa_settings to authenticated; grant SELECT on public.wa_settings to authenticated; grant UPDATE on public.wa_settings to authenticated; grant DELETE on public.wa_settings to authenticated; grant TRUNCATE on public.wa_settings to authenticated; grant REFERENCES on public.wa_settings to authenticated; grant TRIGGER on public.wa_settings to authenticated; grant MAINTAIN on public.wa_settings to authenticated; grant INSERT on public.wa_settings to service_role; grant SELECT on public.wa_settings to service_role; grant UPDATE on public.wa_settings to service_role; grant DELETE on public.wa_settings to service_role; grant TRUNCATE on public.wa_settings to service_role; grant REFERENCES on public.wa_settings to service_role; grant TRIGGER on public.wa_settings to service_role; grant MAINTAIN on public.wa_settings to service_role;
revoke all on public.work_requests from public, anon, authenticated; grant INSERT on public.work_requests to authenticated; grant SELECT on public.work_requests to authenticated; grant UPDATE on public.work_requests to authenticated; grant DELETE on public.work_requests to authenticated; grant TRUNCATE on public.work_requests to authenticated; grant REFERENCES on public.work_requests to authenticated; grant TRIGGER on public.work_requests to authenticated; grant MAINTAIN on public.work_requests to authenticated; grant INSERT on public.work_requests to service_role; grant SELECT on public.work_requests to service_role; grant UPDATE on public.work_requests to service_role; grant DELETE on public.work_requests to service_role; grant TRUNCATE on public.work_requests to service_role; grant REFERENCES on public.work_requests to service_role; grant TRIGGER on public.work_requests to service_role; grant MAINTAIN on public.work_requests to service_role;
revoke all on public.zoho_items from public, anon, authenticated; grant INSERT on public.zoho_items to service_role; grant SELECT on public.zoho_items to service_role; grant UPDATE on public.zoho_items to service_role; grant DELETE on public.zoho_items to service_role; grant TRUNCATE on public.zoho_items to service_role; grant REFERENCES on public.zoho_items to service_role; grant TRIGGER on public.zoho_items to service_role; grant MAINTAIN on public.zoho_items to service_role;
revoke all on public.zoho_settings from public, anon, authenticated; grant INSERT on public.zoho_settings to authenticated; grant SELECT on public.zoho_settings to authenticated; grant UPDATE on public.zoho_settings to authenticated; grant DELETE on public.zoho_settings to authenticated; grant TRUNCATE on public.zoho_settings to authenticated; grant REFERENCES on public.zoho_settings to authenticated; grant TRIGGER on public.zoho_settings to authenticated; grant MAINTAIN on public.zoho_settings to authenticated; grant INSERT on public.zoho_settings to service_role; grant SELECT on public.zoho_settings to service_role; grant UPDATE on public.zoho_settings to service_role; grant DELETE on public.zoho_settings to service_role; grant TRUNCATE on public.zoho_settings to service_role; grant REFERENCES on public.zoho_settings to service_role; grant TRIGGER on public.zoho_settings to service_role; grant MAINTAIN on public.zoho_settings to service_role;
revoke all on public.zoho_state from public, anon, authenticated; grant INSERT on public.zoho_state to service_role; grant SELECT on public.zoho_state to service_role; grant UPDATE on public.zoho_state to service_role; grant DELETE on public.zoho_state to service_role; grant TRUNCATE on public.zoho_state to service_role; grant REFERENCES on public.zoho_state to service_role; grant TRIGGER on public.zoho_state to service_role; grant MAINTAIN on public.zoho_state to service_role;

-- ==== facl ====
revoke all on function public.ai_admin_save(p_enabled boolean, p_model text, p_max integer, p_price_in numeric, p_price_out numeric, p_usd_inr numeric) from public, anon, authenticated; grant execute on function public.ai_admin_save(p_enabled boolean, p_model text, p_max integer, p_price_in numeric, p_price_out numeric, p_usd_inr numeric) to authenticated; grant execute on function public.ai_admin_save(p_enabled boolean, p_model text, p_max integer, p_price_in numeric, p_price_out numeric, p_usd_inr numeric) to service_role;
revoke all on function public.ai_admin_set_key(p_key text) from public, anon, authenticated; grant execute on function public.ai_admin_set_key(p_key text) to authenticated; grant execute on function public.ai_admin_set_key(p_key text) to service_role;
revoke all on function public.ai_admin_status() from public, anon, authenticated; grant execute on function public.ai_admin_status() to authenticated; grant execute on function public.ai_admin_status() to service_role;
revoke all on function public.ai_can_read(p_client uuid) from public, anon, authenticated; grant execute on function public.ai_can_read(p_client uuid) to authenticated; grant execute on function public.ai_can_read(p_client uuid) to service_role;
revoke all on function public.ai_key() from public, anon, authenticated; grant execute on function public.ai_key() to service_role;
revoke all on function public.audit_event(p_action text, p_note text) from public, anon, authenticated; grant execute on function public.audit_event(p_action text, p_note text) to authenticated; grant execute on function public.audit_event(p_action text, p_note text) to service_role;
revoke all on function public.audit_row() from public, anon, authenticated; grant execute on function public.audit_row() to public; grant execute on function public.audit_row() to anon; grant execute on function public.audit_row() to authenticated; grant execute on function public.audit_row() to service_role;
revoke all on function public.audit_val(k text, v jsonb) from public, anon, authenticated; grant execute on function public.audit_val(k text, v jsonb) to public; grant execute on function public.audit_val(k text, v jsonb) to anon; grant execute on function public.audit_val(k text, v jsonb) to authenticated; grant execute on function public.audit_val(k text, v jsonb) to service_role;
revoke all on function public.audit_who() from public, anon, authenticated; grant execute on function public.audit_who() to public; grant execute on function public.audit_who() to anon; grant execute on function public.audit_who() to authenticated; grant execute on function public.audit_who() to service_role;
revoke all on function public.auto_gst_work(p_day date, p_force boolean) from public, anon, authenticated; grant execute on function public.auto_gst_work(p_day date, p_force boolean) to service_role;
revoke all on function public.auto_work_run() from public, anon, authenticated; grant execute on function public.auto_work_run() to public; grant execute on function public.auto_work_run() to anon; grant execute on function public.auto_work_run() to authenticated; grant execute on function public.auto_work_run() to service_role;
revoke all on function public.auto_work_save(p_gst boolean) from public, anon, authenticated; grant execute on function public.auto_work_save(p_gst boolean) to public; grant execute on function public.auto_work_save(p_gst boolean) to anon; grant execute on function public.auto_work_save(p_gst boolean) to authenticated; grant execute on function public.auto_work_save(p_gst boolean) to service_role;
revoke all on function public.auto_work_status() from public, anon, authenticated; grant execute on function public.auto_work_status() to public; grant execute on function public.auto_work_status() to anon; grant execute on function public.auto_work_status() to authenticated; grant execute on function public.auto_work_status() to service_role;
revoke all on function public.aw_period(p_rule text, y integer, m integer) from public, anon, authenticated; grant execute on function public.aw_period(p_rule text, y integer, m integer) to public; grant execute on function public.aw_period(p_rule text, y integer, m integer) to anon; grant execute on function public.aw_period(p_rule text, y integer, m integer) to authenticated; grant execute on function public.aw_period(p_rule text, y integer, m integer) to service_role;
revoke all on function public.can_client_login(p_client uuid) from public, anon, authenticated; grant execute on function public.can_client_login(p_client uuid) to public; grant execute on function public.can_client_login(p_client uuid) to anon; grant execute on function public.can_client_login(p_client uuid) to authenticated; grant execute on function public.can_client_login(p_client uuid) to service_role;
revoke all on function public.can_task(tid uuid) from public, anon, authenticated; grant execute on function public.can_task(tid uuid) to public; grant execute on function public.can_task(tid uuid) to anon; grant execute on function public.can_task(tid uuid) to authenticated; grant execute on function public.can_task(tid uuid) to service_role;
revoke all on function public.chase_candidates() from public, anon, authenticated; grant execute on function public.chase_candidates() to service_role;
revoke all on function public.chase_outbox(p_key text) from public, anon, authenticated; grant execute on function public.chase_outbox(p_key text) to public; grant execute on function public.chase_outbox(p_key text) to anon; grant execute on function public.chase_outbox(p_key text) to authenticated; grant execute on function public.chase_outbox(p_key text) to service_role;
revoke all on function public.chase_run(p_force boolean) from public, anon, authenticated; grant execute on function public.chase_run(p_force boolean) to service_role;
revoke all on function public.chase_run_now() from public, anon, authenticated; grant execute on function public.chase_run_now() to public; grant execute on function public.chase_run_now() to anon; grant execute on function public.chase_run_now() to authenticated; grant execute on function public.chase_run_now() to service_role;
revoke all on function public.chase_save(p jsonb) from public, anon, authenticated; grant execute on function public.chase_save(p jsonb) to public; grant execute on function public.chase_save(p jsonb) to anon; grant execute on function public.chase_save(p jsonb) to authenticated; grant execute on function public.chase_save(p jsonb) to service_role;
revoke all on function public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text) from public, anon, authenticated; grant execute on function public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text) to public; grant execute on function public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text) to anon; grant execute on function public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text) to authenticated; grant execute on function public.chase_sent(p_key text, p_id uuid, p_ok boolean, p_error text) to service_role;
revoke all on function public.chase_site() from public, anon, authenticated; grant execute on function public.chase_site() to public; grant execute on function public.chase_site() to anon; grant execute on function public.chase_site() to authenticated; grant execute on function public.chase_site() to service_role;
revoke all on function public.chase_status() from public, anon, authenticated; grant execute on function public.chase_status() to public; grant execute on function public.chase_status() to anon; grant execute on function public.chase_status() to authenticated; grant execute on function public.chase_status() to service_role;
revoke all on function public.client_logins_after_del() from public, anon, authenticated; grant execute on function public.client_logins_after_del() to public; grant execute on function public.client_logins_after_del() to anon; grant execute on function public.client_logins_after_del() to authenticated; grant execute on function public.client_logins_after_del() to service_role;
revoke all on function public.clients_code_tidy() from public, anon, authenticated; grant execute on function public.clients_code_tidy() to public; grant execute on function public.clients_code_tidy() to anon; grant execute on function public.clients_code_tidy() to authenticated; grant execute on function public.clients_code_tidy() to service_role;
revoke all on function public.cr_guard() from public, anon, authenticated; grant execute on function public.cr_guard() to public; grant execute on function public.cr_guard() to anon; grant execute on function public.cr_guard() to authenticated; grant execute on function public.cr_guard() to service_role;
revoke all on function public.create_invoice(p_client uuid, p_tasks uuid[], p_extra jsonb, p_date date, p_notes text, p_gst_rate numeric) from public, anon, authenticated; grant execute on function public.create_invoice(p_client uuid, p_tasks uuid[], p_extra jsonb, p_date date, p_notes text, p_gst_rate numeric) to authenticated; grant execute on function public.create_invoice(p_client uuid, p_tasks uuid[], p_extra jsonb, p_date date, p_notes text, p_gst_rate numeric) to service_role;
revoke all on function public.demo_clear() from public, anon, authenticated; grant execute on function public.demo_clear() to authenticated; grant execute on function public.demo_clear() to service_role;
revoke all on function public.demo_load() from public, anon, authenticated; grant execute on function public.demo_load() to authenticated; grant execute on function public.demo_load() to service_role;
revoke all on function public.demo_status() from public, anon, authenticated; grant execute on function public.demo_status() to public; grant execute on function public.demo_status() to anon; grant execute on function public.demo_status() to authenticated; grant execute on function public.demo_status() to service_role;
revoke all on function public.dr_plan(p_day date) from public, anon, authenticated; grant execute on function public.dr_plan(p_day date) to service_role;
revoke all on function public.dr_preview(p_client uuid, p_kind text, p_day date) from public, anon, authenticated; grant execute on function public.dr_preview(p_client uuid, p_kind text, p_day date) to public; grant execute on function public.dr_preview(p_client uuid, p_kind text, p_day date) to anon; grant execute on function public.dr_preview(p_client uuid, p_kind text, p_day date) to authenticated; grant execute on function public.dr_preview(p_client uuid, p_kind text, p_day date) to service_role;
revoke all on function public.dr_run(p_force boolean, p_day date) from public, anon, authenticated; grant execute on function public.dr_run(p_force boolean, p_day date) to service_role;
revoke all on function public.dr_run_now() from public, anon, authenticated; grant execute on function public.dr_run_now() to public; grant execute on function public.dr_run_now() to anon; grant execute on function public.dr_run_now() to authenticated; grant execute on function public.dr_run_now() to service_role;
revoke all on function public.dr_save(p jsonb) from public, anon, authenticated; grant execute on function public.dr_save(p jsonb) to public; grant execute on function public.dr_save(p jsonb) to anon; grant execute on function public.dr_save(p jsonb) to authenticated; grant execute on function public.dr_save(p jsonb) to service_role;
revoke all on function public.dr_save_template(p_kind text, p_subject text, p_body text) from public, anon, authenticated; grant execute on function public.dr_save_template(p_kind text, p_subject text, p_body text) to public; grant execute on function public.dr_save_template(p_kind text, p_subject text, p_body text) to anon; grant execute on function public.dr_save_template(p_kind text, p_subject text, p_body text) to authenticated; grant execute on function public.dr_save_template(p_kind text, p_subject text, p_body text) to service_role;
revoke all on function public.dr_status(p_day date) from public, anon, authenticated; grant execute on function public.dr_status(p_day date) to public; grant execute on function public.dr_status(p_day date) to anon; grant execute on function public.dr_status(p_day date) to authenticated; grant execute on function public.dr_status(p_day date) to service_role;
revoke all on function public.followups_after() from public, anon, authenticated; grant execute on function public.followups_after() to public; grant execute on function public.followups_after() to anon; grant execute on function public.followups_after() to authenticated; grant execute on function public.followups_after() to service_role;
revoke all on function public.followups_before() from public, anon, authenticated; grant execute on function public.followups_before() to public; grant execute on function public.followups_before() to anon; grant execute on function public.followups_before() to authenticated; grant execute on function public.followups_before() to service_role;
revoke all on function public.get_board_status(p_token uuid) from public, anon, authenticated; grant execute on function public.get_board_status(p_token uuid) to anon; grant execute on function public.get_board_status(p_token uuid) to authenticated; grant execute on function public.get_board_status(p_token uuid) to service_role;
revoke all on function public.get_client_status(p_token uuid) from public, anon, authenticated; grant execute on function public.get_client_status(p_token uuid) to anon; grant execute on function public.get_client_status(p_token uuid) to authenticated; grant execute on function public.get_client_status(p_token uuid) to service_role;
revoke all on function public.gst_admin_log(p_limit integer) from public, anon, authenticated; grant execute on function public.gst_admin_log(p_limit integer) to public; grant execute on function public.gst_admin_log(p_limit integer) to anon; grant execute on function public.gst_admin_log(p_limit integer) to authenticated; grant execute on function public.gst_admin_log(p_limit integer) to service_role;
revoke all on function public.gst_admin_process() from public, anon, authenticated; grant execute on function public.gst_admin_process() to public; grant execute on function public.gst_admin_process() to anon; grant execute on function public.gst_admin_process() to authenticated; grant execute on function public.gst_admin_process() to service_role;
revoke all on function public.gst_admin_run(p_client uuid) from public, anon, authenticated; grant execute on function public.gst_admin_run(p_client uuid) to public; grant execute on function public.gst_admin_run(p_client uuid) to anon; grant execute on function public.gst_admin_run(p_client uuid) to authenticated; grant execute on function public.gst_admin_run(p_client uuid) to service_role;
revoke all on function public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer) from public, anon, authenticated; grant execute on function public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer) to public; grant execute on function public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer) to anon; grant execute on function public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer) to authenticated; grant execute on function public.gst_admin_save(p_enabled boolean, p_start integer, p_end integer) to service_role;
revoke all on function public.gst_admin_set_keys(p_key text, p_secret text) from public, anon, authenticated; grant execute on function public.gst_admin_set_keys(p_key text, p_secret text) to public; grant execute on function public.gst_admin_set_keys(p_key text, p_secret text) to anon; grant execute on function public.gst_admin_set_keys(p_key text, p_secret text) to authenticated; grant execute on function public.gst_admin_set_keys(p_key text, p_secret text) to service_role;
revoke all on function public.gst_admin_status() from public, anon, authenticated; grant execute on function public.gst_admin_status() to public; grant execute on function public.gst_admin_status() to anon; grant execute on function public.gst_admin_status() to authenticated; grant execute on function public.gst_admin_status() to service_role;
revoke all on function public.gst_api_keys() from public, anon, authenticated; grant execute on function public.gst_api_keys() to service_role;
revoke all on function public.gst_bill_ready(p_upto date) from public, anon, authenticated; grant execute on function public.gst_bill_ready(p_upto date) to authenticated; grant execute on function public.gst_bill_ready(p_upto date) to service_role;
revoke all on function public.gst_bill_reminder() from public, anon, authenticated; grant execute on function public.gst_bill_reminder() to service_role;
revoke all on function public.gst_fy_of(p_code text) from public, anon, authenticated; grant execute on function public.gst_fy_of(p_code text) to public; grant execute on function public.gst_fy_of(p_code text) to anon; grant execute on function public.gst_fy_of(p_code text) to authenticated; grant execute on function public.gst_fy_of(p_code text) to service_role;
revoke all on function public.gst_months_before() from public, anon, authenticated; grant execute on function public.gst_months_before() to public; grant execute on function public.gst_months_before() to anon; grant execute on function public.gst_months_before() to authenticated; grant execute on function public.gst_months_before() to service_role;
revoke all on function public.gst_period_code(p_period text) from public, anon, authenticated; grant execute on function public.gst_period_code(p_period text) to public; grant execute on function public.gst_period_code(p_period text) to anon; grant execute on function public.gst_period_code(p_period text) to authenticated; grant execute on function public.gst_period_code(p_period text) to service_role;
revoke all on function public.gst_process_check(p_id bigint) from public, anon, authenticated; grant execute on function public.gst_process_check(p_id bigint) to service_role;
revoke all on function public.gst_reviews_guard() from public, anon, authenticated; grant execute on function public.gst_reviews_guard() to public; grant execute on function public.gst_reviews_guard() to anon; grant execute on function public.gst_reviews_guard() to authenticated; grant execute on function public.gst_reviews_guard() to service_role;
revoke all on function public.gst_rtn_code(p_name text) from public, anon, authenticated; grant execute on function public.gst_rtn_code(p_name text) to public; grant execute on function public.gst_rtn_code(p_name text) to anon; grant execute on function public.gst_rtn_code(p_name text) to authenticated; grant execute on function public.gst_rtn_code(p_name text) to service_role;
revoke all on function public.gst_tick(p_force_client uuid, p_force_all boolean) from public, anon, authenticated; grant execute on function public.gst_tick(p_force_client uuid, p_force_all boolean) to service_role;
revoke all on function public.handle_new_user() from public, anon, authenticated; grant execute on function public.handle_new_user() to public; grant execute on function public.handle_new_user() to anon; grant execute on function public.handle_new_user() to authenticated; grant execute on function public.handle_new_user() to service_role;
revoke all on function public.is_admin() from public, anon, authenticated; grant execute on function public.is_admin() to public; grant execute on function public.is_admin() to anon; grant execute on function public.is_admin() to authenticated; grant execute on function public.is_admin() to service_role;
revoke all on function public.is_manager() from public, anon, authenticated; grant execute on function public.is_manager() to public; grant execute on function public.is_manager() to anon; grant execute on function public.is_manager() to authenticated; grant execute on function public.is_manager() to service_role;
revoke all on function public.is_member() from public, anon, authenticated; grant execute on function public.is_member() to public; grant execute on function public.is_member() to anon; grant execute on function public.is_member() to authenticated; grant execute on function public.is_member() to service_role;
revoke all on function public.is_partner() from public, anon, authenticated; grant execute on function public.is_partner() to public; grant execute on function public.is_partner() to anon; grant execute on function public.is_partner() to authenticated; grant execute on function public.is_partner() to service_role;
revoke all on function public.ist_today() from public, anon, authenticated; grant execute on function public.ist_today() to public; grant execute on function public.ist_today() to anon; grant execute on function public.ist_today() to authenticated; grant execute on function public.ist_today() to service_role;
revoke all on function public.law_updates_before() from public, anon, authenticated; grant execute on function public.law_updates_before() to public; grant execute on function public.law_updates_before() to anon; grant execute on function public.law_updates_before() to authenticated; grant execute on function public.law_updates_before() to service_role;
revoke all on function public.login_delete(p_id uuid) from public, anon, authenticated; grant execute on function public.login_delete(p_id uuid) to authenticated; grant execute on function public.login_delete(p_id uuid) to service_role;
revoke all on function public.login_reveal(p_id uuid, p_action text) from public, anon, authenticated; grant execute on function public.login_reveal(p_id uuid, p_action text) to authenticated; grant execute on function public.login_reveal(p_id uuid, p_action text) to service_role;
revoke all on function public.login_save(p_id uuid, p_client uuid, p_portal text, p_login text, p_password text, p_url text, p_otp text, p_notes text) from public, anon, authenticated; grant execute on function public.login_save(p_id uuid, p_client uuid, p_portal text, p_login text, p_password text, p_url text, p_otp text, p_notes text) to authenticated; grant execute on function public.login_save(p_id uuid, p_client uuid, p_portal text, p_login text, p_password text, p_url text, p_otp text, p_notes text) to service_role;
revoke all on function public.mail_admin_save(p_enabled boolean, p_filter text, p_mailbox text) from public, anon, authenticated; grant execute on function public.mail_admin_save(p_enabled boolean, p_filter text, p_mailbox text) to authenticated; grant execute on function public.mail_admin_save(p_enabled boolean, p_filter text, p_mailbox text) to service_role;
revoke all on function public.mail_admin_set_key(p_hash text) from public, anon, authenticated; grant execute on function public.mail_admin_set_key(p_hash text) to authenticated; grant execute on function public.mail_admin_set_key(p_hash text) to service_role;
revoke all on function public.mail_admin_status() from public, anon, authenticated; grant execute on function public.mail_admin_status() to authenticated; grant execute on function public.mail_admin_status() to service_role;
revoke all on function public.mail_job_done(p_key text, p_id bigint, p_ok boolean, p_error text) from public, anon, authenticated; grant execute on function public.mail_job_done(p_key text, p_id bigint, p_ok boolean, p_error text) to anon; grant execute on function public.mail_job_done(p_key text, p_id bigint, p_ok boolean, p_error text) to service_role;
revoke all on function public.mail_jobs_due(p_key text) from public, anon, authenticated; grant execute on function public.mail_jobs_due(p_key text) to anon; grant execute on function public.mail_jobs_due(p_key text) to service_role;
revoke all on function public.mailjob_key_ok(p_key text) from public, anon, authenticated; grant execute on function public.mailjob_key_ok(p_key text) to service_role;
revoke all on function public.my_client_id() from public, anon, authenticated; grant execute on function public.my_client_id() to public; grant execute on function public.my_client_id() to anon; grant execute on function public.my_client_id() to authenticated; grant execute on function public.my_client_id() to service_role;
revoke all on function public.notice_admin_save(p jsonb) from public, anon, authenticated; grant execute on function public.notice_admin_save(p jsonb) to public; grant execute on function public.notice_admin_save(p jsonb) to anon; grant execute on function public.notice_admin_save(p jsonb) to authenticated; grant execute on function public.notice_admin_save(p jsonb) to service_role;
revoke all on function public.notice_admin_set_key(p_hash text) from public, anon, authenticated; grant execute on function public.notice_admin_set_key(p_hash text) to public; grant execute on function public.notice_admin_set_key(p_hash text) to anon; grant execute on function public.notice_admin_set_key(p_hash text) to authenticated; grant execute on function public.notice_admin_set_key(p_hash text) to service_role;
revoke all on function public.notice_checked(p_key text, p_found integer, p_error text) from public, anon, authenticated; grant execute on function public.notice_checked(p_key text, p_found integer, p_error text) to public; grant execute on function public.notice_checked(p_key text, p_found integer, p_error text) to anon; grant execute on function public.notice_checked(p_key text, p_found integer, p_error text) to authenticated; grant execute on function public.notice_checked(p_key text, p_found integer, p_error text) to service_role;
revoke all on function public.notice_client(p jsonb, p_from text) from public, anon, authenticated; grant execute on function public.notice_client(p jsonb, p_from text) to public; grant execute on function public.notice_client(p jsonb, p_from text) to anon; grant execute on function public.notice_client(p jsonb, p_from text) to authenticated; grant execute on function public.notice_client(p jsonb, p_from text) to service_role;
revoke all on function public.notice_digest(p_key text) from public, anon, authenticated; grant execute on function public.notice_digest(p_key text) to public; grant execute on function public.notice_digest(p_key text) to anon; grant execute on function public.notice_digest(p_key text) to authenticated; grant execute on function public.notice_digest(p_key text) to service_role;
revoke all on function public.notice_intake(p_key text, p_mail jsonb) from public, anon, authenticated; grant execute on function public.notice_intake(p_key text, p_mail jsonb) to public; grant execute on function public.notice_intake(p_key text, p_mail jsonb) to anon; grant execute on function public.notice_intake(p_key text, p_mail jsonb) to authenticated; grant execute on function public.notice_intake(p_key text, p_mail jsonb) to service_role;
revoke all on function public.notice_parse(p_from text, p_subject text, p_body text, p_date date) from public, anon, authenticated; grant execute on function public.notice_parse(p_from text, p_subject text, p_body text, p_date date) to public; grant execute on function public.notice_parse(p_from text, p_subject text, p_body text, p_date date) to anon; grant execute on function public.notice_parse(p_from text, p_subject text, p_body text, p_date date) to authenticated; grant execute on function public.notice_parse(p_from text, p_subject text, p_body text, p_date date) to service_role;
revoke all on function public.notice_poll(p_key text) from public, anon, authenticated; grant execute on function public.notice_poll(p_key text) to public; grant execute on function public.notice_poll(p_key text) to anon; grant execute on function public.notice_poll(p_key text) to authenticated; grant execute on function public.notice_poll(p_key text) to service_role;
revoke all on function public.notice_request_check() from public, anon, authenticated; grant execute on function public.notice_request_check() to public; grant execute on function public.notice_request_check() to anon; grant execute on function public.notice_request_check() to authenticated; grant execute on function public.notice_request_check() to service_role;
revoke all on function public.notice_status() from public, anon, authenticated; grant execute on function public.notice_status() to public; grant execute on function public.notice_status() to anon; grant execute on function public.notice_status() to authenticated; grant execute on function public.notice_status() to service_role;
revoke all on function public.notice_wa_alert(p_dept text, p_client text, p_what text, p_due text) from public, anon, authenticated; grant execute on function public.notice_wa_alert(p_dept text, p_client text, p_what text, p_due text) to service_role;
revoke all on function public.notices_before() from public, anon, authenticated; grant execute on function public.notices_before() to public; grant execute on function public.notices_before() to anon; grant execute on function public.notices_before() to authenticated; grant execute on function public.notices_before() to service_role;
revoke all on function public.np_date(t text) from public, anon, authenticated; grant execute on function public.np_date(t text) to public; grant execute on function public.np_date(t text) to anon; grant execute on function public.np_date(t text) to authenticated; grant execute on function public.np_date(t text) to service_role;
revoke all on function public.nw_key_ok(p_key text) from public, anon, authenticated; grant execute on function public.nw_key_ok(p_key text) to service_role;
revoke all on function public.payments_sum() from public, anon, authenticated; grant execute on function public.payments_sum() to public; grant execute on function public.payments_sum() to anon; grant execute on function public.payments_sum() to authenticated; grant execute on function public.payments_sum() to service_role;
revoke all on function public.portal_claim_payment(p_invoice uuid, p_amount numeric, p_date date, p_mode text, p_ref text, p_note text) from public, anon, authenticated; grant execute on function public.portal_claim_payment(p_invoice uuid, p_amount numeric, p_date date, p_mode text, p_ref text, p_note text) to authenticated; grant execute on function public.portal_claim_payment(p_invoice uuid, p_amount numeric, p_date date, p_mode text, p_ref text, p_note text) to service_role;
revoke all on function public.portal_client_id() from public, anon, authenticated; grant execute on function public.portal_client_id() to authenticated; grant execute on function public.portal_client_id() to service_role;
revoke all on function public.portal_extra() from public, anon, authenticated; grant execute on function public.portal_extra() to authenticated; grant execute on function public.portal_extra() to service_role;
revoke all on function public.portal_itc_answer(p_period date, p_key text, p_answer text, p_note text) from public, anon, authenticated; grant execute on function public.portal_itc_answer(p_period date, p_key text, p_answer text, p_note text) to authenticated; grant execute on function public.portal_itc_answer(p_period date, p_key text, p_answer text, p_note text) to service_role;
revoke all on function public.portal_itc_list() from public, anon, authenticated; grant execute on function public.portal_itc_list() to authenticated; grant execute on function public.portal_itc_list() to service_role;
revoke all on function public.portal_me() from public, anon, authenticated; grant execute on function public.portal_me() to authenticated; grant execute on function public.portal_me() to service_role;
revoke all on function public.portal_record_upload(p_task uuid, p_doc uuid, p_path text, p_name text, p_size bigint) from public, anon, authenticated; grant execute on function public.portal_record_upload(p_task uuid, p_doc uuid, p_path text, p_name text, p_size bigint) to authenticated; grant execute on function public.portal_record_upload(p_task uuid, p_doc uuid, p_path text, p_name text, p_size bigint) to service_role;
revoke all on function public.portal_reports() from public, anon, authenticated; grant execute on function public.portal_reports() to authenticated; grant execute on function public.portal_reports() to service_role;
revoke all on function public.ret_label(p_kind text) from public, anon, authenticated; grant execute on function public.ret_label(p_kind text) to public; grant execute on function public.ret_label(p_kind text) to anon; grant execute on function public.ret_label(p_kind text) to authenticated; grant execute on function public.ret_label(p_kind text) to service_role;
revoke all on function public.review_apply(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text, p_via text, p_who text) from public, anon, authenticated; grant execute on function public.review_apply(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text, p_via text, p_who text) to service_role;
revoke all on function public.review_decide(p_token text, p_decision text, p_remarks text) from public, anon, authenticated; grant execute on function public.review_decide(p_token text, p_decision text, p_remarks text) to anon; grant execute on function public.review_decide(p_token text, p_decision text, p_remarks text) to authenticated; grant execute on function public.review_decide(p_token text, p_decision text, p_remarks text) to service_role;
revoke all on function public.review_decide_staff(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text) from public, anon, authenticated; grant execute on function public.review_decide_staff(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text) to authenticated; grant execute on function public.review_decide_staff(p_client uuid, p_period date, p_kind text, p_decision text, p_remarks text) to service_role;
revoke all on function public.review_peek(p_token text) from public, anon, authenticated; grant execute on function public.review_peek(p_token text) to anon; grant execute on function public.review_peek(p_token text) to authenticated; grant execute on function public.review_peek(p_token text) to service_role;
revoke all on function public.review_reminders() from public, anon, authenticated; grant execute on function public.review_reminders() to service_role;
revoke all on function public.review_reply(p_key text, p_tag text, p_from text, p_text text) from public, anon, authenticated; grant execute on function public.review_reply(p_key text, p_tag text, p_from text, p_text text) to anon; grant execute on function public.review_reply(p_key text, p_tag text, p_from text, p_text text) to service_role;
revoke all on function public.senior_email() from public, anon, authenticated; grant execute on function public.senior_email() to authenticated; grant execute on function public.senior_email() to service_role;
revoke all on function public.set_itc_method(p_client uuid, p_method text) from public, anon, authenticated; grant execute on function public.set_itc_method(p_client uuid, p_method text) to authenticated; grant execute on function public.set_itc_method(p_client uuid, p_method text) to service_role;
revoke all on function public.set_mailjob_key(p_hash text) from public, anon, authenticated; grant execute on function public.set_mailjob_key(p_hash text) to authenticated; grant execute on function public.set_mailjob_key(p_hash text) to service_role;
revoke all on function public.take_backup(p_kind text) from public, anon, authenticated; grant execute on function public.take_backup(p_kind text) to authenticated; grant execute on function public.take_backup(p_kind text) to service_role;
revoke all on function public.task_checks_count() from public, anon, authenticated; grant execute on function public.task_checks_count() to public; grant execute on function public.task_checks_count() to anon; grant execute on function public.task_checks_count() to authenticated; grant execute on function public.task_checks_count() to service_role;
revoke all on function public.task_checks_stamp() from public, anon, authenticated; grant execute on function public.task_checks_stamp() to public; grant execute on function public.task_checks_stamp() to anon; grant execute on function public.task_checks_stamp() to authenticated; grant execute on function public.task_checks_stamp() to service_role;
revoke all on function public.task_docs_after() from public, anon, authenticated; grant execute on function public.task_docs_after() to public; grant execute on function public.task_docs_after() to anon; grant execute on function public.task_docs_after() to authenticated; grant execute on function public.task_docs_after() to service_role;
revoke all on function public.task_docs_stamp() from public, anon, authenticated; grant execute on function public.task_docs_stamp() to public; grant execute on function public.task_docs_stamp() to anon; grant execute on function public.task_docs_stamp() to authenticated; grant execute on function public.task_docs_stamp() to service_role;
revoke all on function public.task_missing_docs(p_task uuid, p_return text) from public, anon, authenticated; grant execute on function public.task_missing_docs(p_task uuid, p_return text) to public; grant execute on function public.task_missing_docs(p_task uuid, p_return text) to anon; grant execute on function public.task_missing_docs(p_task uuid, p_return text) to authenticated; grant execute on function public.task_missing_docs(p_task uuid, p_return text) to service_role;
revoke all on function public.tasks_before_write() from public, anon, authenticated; grant execute on function public.tasks_before_write() to public; grant execute on function public.tasks_before_write() to anon; grant execute on function public.tasks_before_write() to authenticated; grant execute on function public.tasks_before_write() to service_role;
revoke all on function public.tasks_fee_default() from public, anon, authenticated; grant execute on function public.tasks_fee_default() to public; grant execute on function public.tasks_fee_default() to anon; grant execute on function public.tasks_fee_default() to authenticated; grant execute on function public.tasks_fee_default() to service_role;
revoke all on function public.tasks_money_guard() from public, anon, authenticated; grant execute on function public.tasks_money_guard() to public; grant execute on function public.tasks_money_guard() to anon; grant execute on function public.tasks_money_guard() to authenticated; grant execute on function public.tasks_money_guard() to service_role;
revoke all on function public.touch_updated_at() from public, anon, authenticated; grant execute on function public.touch_updated_at() to public; grant execute on function public.touch_updated_at() to anon; grant execute on function public.touch_updated_at() to authenticated; grant execute on function public.touch_updated_at() to service_role;
revoke all on function public.wa_admin_log(p_limit integer) from public, anon, authenticated; grant execute on function public.wa_admin_log(p_limit integer) to public; grant execute on function public.wa_admin_log(p_limit integer) to anon; grant execute on function public.wa_admin_log(p_limit integer) to authenticated; grant execute on function public.wa_admin_log(p_limit integer) to service_role;
revoke all on function public.wa_admin_run(p_kind text) from public, anon, authenticated; grant execute on function public.wa_admin_run(p_kind text) to public; grant execute on function public.wa_admin_run(p_kind text) to anon; grant execute on function public.wa_admin_run(p_kind text) to authenticated; grant execute on function public.wa_admin_run(p_kind text) to service_role;
revoke all on function public.wa_admin_set_token(p_token text) from public, anon, authenticated; grant execute on function public.wa_admin_set_token(p_token text) to public; grant execute on function public.wa_admin_set_token(p_token text) to anon; grant execute on function public.wa_admin_set_token(p_token text) to authenticated; grant execute on function public.wa_admin_set_token(p_token text) to service_role;
revoke all on function public.wa_admin_status() from public, anon, authenticated; grant execute on function public.wa_admin_status() to public; grant execute on function public.wa_admin_status() to anon; grant execute on function public.wa_admin_status() to authenticated; grant execute on function public.wa_admin_status() to service_role;
revoke all on function public.wa_admin_test(p_phone text) from public, anon, authenticated; grant execute on function public.wa_admin_test(p_phone text) to public; grant execute on function public.wa_admin_test(p_phone text) to anon; grant execute on function public.wa_admin_test(p_phone text) to authenticated; grant execute on function public.wa_admin_test(p_phone text) to service_role;
revoke all on function public.wa_clean(p text, maxlen integer) from public, anon, authenticated; grant execute on function public.wa_clean(p text, maxlen integer) to public; grant execute on function public.wa_clean(p text, maxlen integer) to anon; grant execute on function public.wa_clean(p text, maxlen integer) to authenticated; grant execute on function public.wa_clean(p text, maxlen integer) to service_role;
revoke all on function public.wa_client_reminders(p_force boolean) from public, anon, authenticated; grant execute on function public.wa_client_reminders(p_force boolean) to service_role;
revoke all on function public.wa_daily_reminders(p_force boolean) from public, anon, authenticated; grant execute on function public.wa_daily_reminders(p_force boolean) to service_role;
revoke all on function public.wa_month_list(p_month date) from public, anon, authenticated; grant execute on function public.wa_month_list(p_month date) to authenticated; grant execute on function public.wa_month_list(p_month date) to service_role;
revoke all on function public.wa_monthly_due_list(p_force boolean) from public, anon, authenticated; grant execute on function public.wa_monthly_due_list(p_force boolean) to service_role;
revoke all on function public.wa_phone(p text) from public, anon, authenticated; grant execute on function public.wa_phone(p text) to public; grant execute on function public.wa_phone(p text) to anon; grant execute on function public.wa_phone(p text) to authenticated; grant execute on function public.wa_phone(p text) to service_role;
revoke all on function public.wa_send(p_phone text, p_template text, p_params text[], p_kind text, p_profile uuid, p_summary text) from public, anon, authenticated; grant execute on function public.wa_send(p_phone text, p_template text, p_params text[], p_kind text, p_profile uuid, p_summary text) to service_role;
revoke all on function public.wr_guard() from public, anon, authenticated; grant execute on function public.wr_guard() to public; grant execute on function public.wr_guard() to anon; grant execute on function public.wr_guard() to authenticated; grant execute on function public.wr_guard() to service_role;
revoke all on function public.wr_notify() from public, anon, authenticated; grant execute on function public.wr_notify() to public; grant execute on function public.wr_notify() to anon; grant execute on function public.wr_notify() to authenticated; grant execute on function public.wr_notify() to service_role;
revoke all on function public.zoho_cron() from public, anon, authenticated; grant execute on function public.zoho_cron() to service_role;
revoke all on function public.zoho_get_secrets() from public, anon, authenticated; grant execute on function public.zoho_get_secrets() to service_role;
revoke all on function public.zoho_put_secret(p_name text, p_value text) from public, anon, authenticated; grant execute on function public.zoho_put_secret(p_name text, p_value text) to service_role;

-- ==== buckets ====
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('client-docs', 'client-docs', f, 26214400, null) on conflict (id) do nothing;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('filing-acks', 'filing-acks', f, null, null) on conflict (id) do nothing;

-- ==== seed ====
insert into public.due_dates select * from jsonb_populate_recordset(null::public.due_dates, $seed$[{"id": 1, "sort": 10, "months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 11, "work_type": "GST", "applies_to": "Monthly", "description": "Outward supplies - monthly filers", "period_rule": "prev_month", "return_name": "GSTR-1"}, {"id": 2, "sort": 11, "months": [1, 4, 7, 10], "due_day": 13, "work_type": "GST", "applies_to": "QRMP", "description": "Outward supplies - QRMP filers", "period_rule": "prev_quarter", "return_name": "GSTR-1 (Quarterly)"}, {"id": 3, "sort": 12, "months": [2, 3, 5, 6, 8, 9, 11, 12], "due_day": 13, "work_type": "GST", "applies_to": "QRMP", "description": "Invoice Furnishing Facility (optional) - QRMP", "period_rule": "prev_month", "return_name": "IFF"}, {"id": 4, "sort": 13, "months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 20, "work_type": "GST", "applies_to": "Monthly", "description": "Summary return & tax payment - monthly filers", "period_rule": "prev_month", "return_name": "GSTR-3B"}, {"id": 5, "sort": 14, "months": [1, 4, 7, 10], "due_day": 22, "work_type": "GST", "applies_to": "QRMP", "description": "QRMP - Category X states (incl. Tamil Nadu)", "period_rule": "prev_quarter", "return_name": "GSTR-3B (Quarterly)"}, {"id": 6, "sort": 15, "months": [1, 4, 7, 10], "due_day": 24, "work_type": "GST", "applies_to": "QRMP", "description": "QRMP - Category Y states", "period_rule": "prev_quarter", "return_name": "GSTR-3B (Quarterly, Cat Y)"}, {"id": 7, "sort": 16, "months": [2, 3, 5, 6, 8, 9, 11, 12], "due_day": 25, "work_type": "GST", "applies_to": "QRMP", "description": "Monthly tax payment - QRMP", "period_rule": "prev_month", "return_name": "PMT-06"}, {"id": 8, "sort": 17, "months": [1, 4, 7, 10], "due_day": 18, "work_type": "GST", "applies_to": "Composition", "description": "Quarterly payment - composition", "period_rule": "prev_quarter", "return_name": "CMP-08"}, {"id": 9, "sort": 18, "months": [4], "due_day": 30, "work_type": "GST", "applies_to": "Composition", "description": "Annual return - composition", "period_rule": "prev_fy", "return_name": "GSTR-4"}, {"id": 10, "sort": 19, "months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 10, "work_type": "GST", "applies_to": null, "description": "TDS under GST (deductors)", "period_rule": "prev_month", "return_name": "GSTR-7"}, {"id": 11, "sort": 20, "months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 10, "work_type": "GST", "applies_to": null, "description": "TCS under GST (e-commerce operators)", "period_rule": "prev_month", "return_name": "GSTR-8"}, {"id": 12, "sort": 21, "months": [12], "due_day": 31, "work_type": "GST", "applies_to": null, "description": "Annual return & reconciliation", "period_rule": "prev_fy", "return_name": "GSTR-9 / 9C"}, {"id": 13, "sort": 30, "months": [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 7, "work_type": "TDS", "applies_to": null, "description": "Monthly TDS payment", "period_rule": "prev_month", "return_name": "TDS deposit"}, {"id": 14, "sort": 31, "months": [4], "due_day": 30, "work_type": "TDS", "applies_to": null, "description": "TDS for March", "period_rule": "prev_month", "return_name": "TDS deposit (March)"}, {"id": 15, "sort": 32, "months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "due_day": 7, "work_type": "TDS", "applies_to": null, "description": "Monthly TCS payment", "period_rule": "prev_month", "return_name": "TCS deposit"}, {"id": 16, "sort": 33, "months": [1, 5, 7, 10], "due_day": 31, "work_type": "TDS", "applies_to": null, "description": "Quarterly TDS statement (salary)", "period_rule": "prev_quarter", "return_name": "TDS return - Salary"}, {"id": 17, "sort": 34, "months": [1, 5, 7, 10], "due_day": 31, "work_type": "TDS", "applies_to": null, "description": "Quarterly TDS statement (non-salary)", "period_rule": "prev_quarter", "return_name": "TDS return - Non-salary"}, {"id": 18, "sort": 35, "months": [1, 5, 7, 10], "due_day": 31, "work_type": "TDS", "applies_to": null, "description": "Quarterly TDS statement (non-resident)", "period_rule": "prev_quarter", "return_name": "TDS return - Non-resident"}, {"id": 19, "sort": 36, "months": [1, 5, 7, 10], "due_day": 15, "work_type": "TDS", "applies_to": null, "description": "Quarterly TCS statement", "period_rule": "prev_quarter", "return_name": "TCS return"}, {"id": 20, "sort": 37, "months": [2, 6, 8, 11], "due_day": 15, "work_type": "TDS", "applies_to": null, "description": "Issue quarterly certificates to deductees", "period_rule": "prev_quarter", "return_name": "TDS certificate (non-salary)"}, {"id": 21, "sort": 38, "months": [6], "due_day": 15, "work_type": "TDS", "applies_to": null, "description": "Issue annual salary TDS certificates", "period_rule": "prev_fy", "return_name": "TDS certificate (salary)"}, {"id": 22, "sort": 50, "months": [3, 6, 9, 12], "due_day": 15, "work_type": "Income Tax", "applies_to": null, "description": "Advance tax instalment", "period_rule": "current_fy", "return_name": "Advance tax"}, {"id": 23, "sort": 51, "months": [7], "due_day": 31, "work_type": "Income Tax", "applies_to": null, "description": "Income tax return - non-audit cases", "period_rule": "prev_fy", "return_name": "ITR (non-audit)"}, {"id": 24, "sort": 52, "months": [9], "due_day": 30, "work_type": "Income Tax", "applies_to": null, "description": "Tax audit report filing", "period_rule": "prev_fy", "return_name": "Tax audit report"}, {"id": 25, "sort": 53, "months": [10], "due_day": 31, "work_type": "Income Tax", "applies_to": null, "description": "Income tax return - audit cases", "period_rule": "prev_fy", "return_name": "ITR (audit)"}, {"id": 26, "sort": 54, "months": [11], "due_day": 30, "work_type": "Income Tax", "applies_to": null, "description": "Income tax return - transfer pricing cases", "period_rule": "prev_fy", "return_name": "ITR (transfer pricing)"}, {"id": 27, "sort": 70, "months": [4], "due_day": 30, "work_type": "ROC/MCA", "applies_to": null, "description": "Half-yearly return - outstanding MSME dues", "period_rule": "prev_half", "return_name": "MSME-1"}, {"id": 28, "sort": 71, "months": [10], "due_day": 31, "work_type": "ROC/MCA", "applies_to": null, "description": "Half-yearly return - outstanding MSME dues", "period_rule": "prev_half", "return_name": "MSME-1"}, {"id": 29, "sort": 72, "months": [5], "due_day": 30, "work_type": "ROC/MCA", "applies_to": null, "description": "LLP annual return", "period_rule": "prev_fy", "return_name": "LLP Form 11"}, {"id": 30, "sort": 73, "months": [6], "due_day": 30, "work_type": "ROC/MCA", "applies_to": null, "description": "Return of deposits", "period_rule": "prev_fy", "return_name": "DPT-3"}, {"id": 31, "sort": 74, "months": [9], "due_day": 30, "work_type": "ROC/MCA", "applies_to": null, "description": "Director KYC", "period_rule": "prev_fy", "return_name": "DIR-3 KYC"}, {"id": 32, "sort": 75, "months": [10], "due_day": 14, "work_type": "ROC/MCA", "applies_to": "If AGM on 30 Sep", "description": "Auditor appointment (within 15 days of AGM)", "period_rule": "prev_fy", "return_name": "ADT-1"}, {"id": 33, "sort": 76, "months": [10], "due_day": 30, "work_type": "ROC/MCA", "applies_to": "If AGM on 30 Sep", "description": "Financial statements (within 30 days of AGM)", "period_rule": "prev_fy", "return_name": "AOC-4"}, {"id": 34, "sort": 77, "months": [10], "due_day": 30, "work_type": "ROC/MCA", "applies_to": null, "description": "LLP statement of account & solvency", "period_rule": "prev_fy", "return_name": "LLP Form 8"}, {"id": 35, "sort": 78, "months": [11], "due_day": 29, "work_type": "ROC/MCA", "applies_to": "If AGM on 30 Sep", "description": "Annual return (within 60 days of AGM)", "period_rule": "prev_fy", "return_name": "MGT-7 / 7A"}]$seed$::jsonb) on conflict do nothing;
insert into public.checklist_templates select * from jsonb_populate_recordset(null::public.checklist_templates, $seed$[{"id": 1, "docs": ["Sales register / sales invoices", "Credit & debit notes", "E-invoice / e-way bill list", "Export / SEZ invoices (if any)"], "name": "GSTR-1 (monthly / QRMP)", "steps": [{"who": "Staff", "name": "Send data request reminder email to client"}, {"who": "Staff", "name": "Sales register / invoices received from client"}, {"who": "Staff", "name": "Validation of information received (missing invoice nos., duplicates)"}, {"who": "Staff", "name": "Check customer GSTINs are active (not cancelled / suspended)"}, {"who": "Staff", "name": "Match e-invoice & e-way bill data with sales register"}, {"who": "Staff", "name": "Classify B2B, B2C, exports, SEZ, nil-rated, credit/debit notes, amendments"}, {"who": "Staff", "name": "Prepare HSN summary and document summary"}, {"who": "Staff", "name": "Reconcile sales with books / P&L for the period"}, {"who": "Staff", "name": "Upload data on GST portal / JSON from offline tool"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "Send summary to client and get approval"}, {"who": "Staff", "name": "File GSTR-1 with EVC / DSC"}, {"who": "Staff", "name": "Download acknowledgement (ARN) and send to client"}, {"who": "Staff", "name": "Update tracker - ARN & filed date"}], "matches": ["GSTR-1", "GSTR-1 (Quarterly)", "IFF"], "work_type": "GST", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 9, "docs": ["Payment details to non-residents / TCS collections", "TRC & Form 10F", "Form 15CA / 15CB copies", "Challans paid"], "name": "27Q / 27EQ (non-resident / TCS)", "steps": [{"who": "Staff", "name": "Collect payments to non-residents / TCS collections"}, {"who": "Staff", "name": "Check DTAA rate, TRC, Form 10F (27Q)"}, {"who": "Staff", "name": "Check Form 15CA/15CB filed for foreign remittance"}, {"who": "Staff", "name": "Prepare & validate return (RPU / FVU)"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "Upload return; update tracker"}], "matches": ["27Q (non-resident)", "27EQ (TCS)", "27Q", "27EQ"], "work_type": "TDS", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 2, "docs": ["Purchase register / purchase bills", "Expense bills", "Sales summary for the month", "Bank statement", "Reverse charge (RCM) expense details"], "name": "GSTR-3B (monthly / quarterly)", "steps": [{"who": "Staff", "name": "Send data request reminder email to client"}, {"who": "Staff", "name": "Purchase register / expense details received"}, {"who": "Staff", "name": "Download GSTR-2B for the period"}, {"who": "Staff", "name": "Reconcile ITC: books vs GSTR-2B (missing / excess invoices)"}, {"who": "Staff", "name": "Remove blocked credits u/s 17(5); Rule 42/43 reversals if any"}, {"who": "Staff", "name": "Compute reverse charge (RCM) liability"}, {"who": "Staff", "name": "Check outward liability matches filed GSTR-1"}, {"who": "Staff", "name": "Compute interest / late fee if delayed"}, {"who": "Staff", "name": "Prepare tax payable working and send challan (PMT-06) to client"}, {"who": "Staff", "name": "Payment confirmed in electronic cash ledger"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "File GSTR-3B with EVC / DSC"}, {"who": "Staff", "name": "Send acknowledgement and tax working to client"}, {"who": "Staff", "name": "Update tracker - ARN & filed date"}], "matches": ["GSTR-3B", "GSTR-3B (Quarterly)"], "work_type": "GST", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 3, "docs": ["Turnover for the quarter", "Purchase details"], "name": "CMP-08 / GSTR-4 (composition)", "steps": [{"who": "Staff", "name": "Collect quarterly turnover details"}, {"who": "Staff", "name": "Compute tax at composition rate"}, {"who": "Staff", "name": "Client pays tax via challan"}, {"who": "Staff", "name": "File CMP-08 by 18th of month after quarter"}, {"who": "Staff", "name": "Annual: prepare and file GSTR-4 by 30 April"}, {"who": "Staff", "name": "Send acknowledgement; update tracker"}], "matches": ["CMP-08", "GSTR-4"], "work_type": "GST", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 4, "docs": ["Audited financial statements", "Final sales & purchase registers", "ITC ledger / GSTR-2B reconciliation", "HSN-wise summary"], "name": "GSTR-9 / GSTR-9C (annual)", "steps": [{"who": "Staff", "name": "Check applicability: GSTR-9 if turnover > Rs 2 Cr; 9C if > Rs 5 Cr"}, {"who": "Staff", "name": "Download all GSTR-1, 3B and 2B summaries for the year"}, {"who": "Staff", "name": "Get final audited books from client"}, {"who": "Staff", "name": "Reconcile turnover: books vs GSTR-1 vs 3B"}, {"who": "Staff", "name": "Reconcile ITC: books vs 3B vs GSTR-2B"}, {"who": "Staff", "name": "Prepare HSN-wise outward & inward summary"}, {"who": "Staff", "name": "Identify differences to be paid via DRC-03"}, {"who": "Staff", "name": "Prepare GSTR-9C reconciliation statement (if applicable)"}, {"who": "Reviewer", "name": "Review by senior / partner"}, {"who": "Staff", "name": "Client approval"}, {"who": "Staff", "name": "File GSTR-9 / 9C by 31 December"}, {"who": "Staff", "name": "Send acknowledgement; update tracker"}], "matches": ["GSTR-9", "GSTR-9C", "GSTR-9 / 9C"], "work_type": "GST", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 5, "docs": ["PAN", "Aadhaar of proprietor / partners / directors", "Photograph", "Business address proof", "Rent agreement / NOC", "Bank statement or cancelled cheque", "Partnership deed / COI (if any)"], "name": "New GST registration", "steps": [{"who": "Staff", "name": "Collect PAN, Aadhaar, photo, address proof, rent agreement / NOC, bank proof"}, {"who": "Staff", "name": "Collect constitution docs (partnership deed / COI / board resolution)"}, {"who": "Staff", "name": "File REG-01 (Part A & Part B)"}, {"who": "Staff", "name": "Complete Aadhaar authentication / biometric if required"}, {"who": "Staff", "name": "Note ARN; follow up for clarification (REG-03)"}, {"who": "Staff", "name": "Reply to clarification in REG-04 within 7 working days"}, {"who": "Staff", "name": "Download registration certificate (REG-06) and send to client"}, {"who": "Staff", "name": "Update client master: GSTIN, scheme, return frequency"}, {"who": "Staff", "name": "Opt QRMP / composition if needed; LUT for exporters"}], "matches": ["GST registration (REG-01)"], "work_type": "GST", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 6, "docs": ["Payment / expense ledger for the month", "Salary sheet", "Vendor PAN list"], "name": "TDS monthly payment (Challan 281)", "steps": [{"who": "Staff", "name": "Get payment / expense ledger for the month"}, {"who": "Staff", "name": "Identify TDS-applicable payments and sections"}, {"who": "Staff", "name": "Check PAN of deductees; apply higher rate where PAN missing"}, {"who": "Staff", "name": "Check lower / nil deduction certificates"}, {"who": "Staff", "name": "Compute TDS (salary & non-salary)"}, {"who": "Staff", "name": "Prepare challan and send to client"}, {"who": "Staff", "name": "Payment by 7th of next month (March: 30 April)"}, {"who": "Staff", "name": "Record CIN / BSR code / challan serial no."}, {"who": "Staff", "name": "Update tracker"}], "matches": ["TDS deposit", "TDS deposit (March)", "TCS deposit"], "work_type": "TDS", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 7, "docs": ["Salary register for the quarter", "Employee PAN list", "Investment proofs (old regime)", "TDS challans paid"], "name": "24Q - TDS on salary (quarterly)", "steps": [{"who": "Staff", "name": "Get salary register for the quarter"}, {"who": "Staff", "name": "Collect investment declarations / proofs (old regime)"}, {"who": "Staff", "name": "Compute TDS on salary per employee"}, {"who": "Staff", "name": "Match challans with deductions"}, {"who": "Staff", "name": "Q4: prepare Annexure II (full-year salary details)"}, {"who": "Staff", "name": "Prepare return in RPU; validate with FVU"}, {"who": "Staff", "name": "Check interest / late fee"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "Upload return; note token / acknowledgement no."}, {"who": "Staff", "name": "Check TRACES processing / defaults"}, {"who": "Staff", "name": "After Q4: issue Form 16 by 15 June"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["24Q (salary)", "24Q"], "work_type": "TDS", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 8, "docs": ["Vendor ledger with payments", "Vendor PAN list", "TDS challans paid", "Lower deduction certificates (if any)"], "name": "26Q - TDS other than salary (quarterly)", "steps": [{"who": "Staff", "name": "Get expense / vendor ledger for the quarter"}, {"who": "Staff", "name": "Get list of challans paid"}, {"who": "Staff", "name": "Verify deductee PANs"}, {"who": "Staff", "name": "Map payments to correct sections (194C, 194J, 194I, 194H, 194Q…)"}, {"who": "Staff", "name": "Apply lower deduction certificates if any"}, {"who": "Staff", "name": "Prepare return in RPU; validate with FVU"}, {"who": "Staff", "name": "Check interest / late fee"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "Upload return; note token / acknowledgement no."}, {"who": "Staff", "name": "Check TRACES processing / defaults"}, {"who": "Staff", "name": "Download Form 16A and send to client (within 15 days of return due date)"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["26Q (other than salary)", "26Q"], "work_type": "TDS", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 10, "docs": ["Sale deed / rent agreement", "PAN of seller / landlord", "Payment details"], "name": "26QB / 26QC (property / rent)", "steps": [{"who": "Staff", "name": "Collect sale deed / rent details, PAN of seller / landlord"}, {"who": "Staff", "name": "Compute TDS (1% on property > Rs 50 lakh; rent u/s 194-IB)"}, {"who": "Staff", "name": "File 26QB/26QC with payment within 30 days of month end"}, {"who": "Staff", "name": "Download Form 16B/16C from TRACES and give to seller / landlord"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["26QB (property)", "26QC (rent)", "26QD (contractor / professional)"], "work_type": "TDS", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 11, "docs": ["PAN & Aadhaar of directors / subscribers", "Photographs", "Director address proof (bank statement / utility bill)", "Registered office proof + NOC", "Proposed names & business objects", "Capital & shareholding details"], "name": "Company incorporation (SPICe+)", "steps": [{"who": "Staff", "name": "Collect KYC of directors & subscribers (PAN, Aadhaar, photo, address proof)"}, {"who": "Staff", "name": "Obtain DSC for all directors / subscribers"}, {"who": "Staff", "name": "Name reservation - SPICe+ Part A"}, {"who": "Staff", "name": "Registered office proof + NOC + utility bill"}, {"who": "Staff", "name": "Draft MOA & AOA"}, {"who": "Staff", "name": "File SPICe+ Part B, e-MOA (INC-33), e-AOA (INC-34), AGILE-PRO-S, INC-9"}, {"who": "Staff", "name": "Certificate of incorporation, PAN, TAN received"}, {"who": "Staff", "name": "Send COI to client"}, {"who": "Reviewer", "name": "Create follow-up filings (button below): first board meeting, ADT-1, INC-20A, share certificates…"}, {"who": "Staff", "name": "Update tracker & client master (CIN)"}], "matches": ["Company incorporation (SPICe+)"], "work_type": "ROC/MCA", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 12, "docs": ["Audited financial statements", "Board report", "List of shareholders", "Director details & KYC", "AGM date & minutes"], "name": "Company annual filing", "steps": [{"who": "Staff", "name": "Books & statutory audit completed"}, {"who": "Staff", "name": "Board meeting: approve financial statements & board report"}, {"who": "Staff", "name": "Send AGM notice (21 clear days)"}, {"who": "Staff", "name": "AGM held within 6 months of FY end (by 30 Sep)"}, {"who": "Staff", "name": "ADT-1 within 15 days if auditor appointed / reappointed at AGM"}, {"who": "Staff", "name": "AOC-4 within 30 days of AGM"}, {"who": "Staff", "name": "MGT-7 / MGT-7A within 60 days of AGM"}, {"who": "Staff", "name": "MGT-14 for resolutions that need filing (if any)"}, {"who": "Staff", "name": "Director KYC (DIR-3 KYC) - check due"}, {"who": "Reviewer", "name": "Review by senior"}, {"who": "Staff", "name": "Send SRNs / challans to client; update tracker"}], "matches": ["AOC-4", "AOC-4 CFS", "AOC-4 XBRL", "MGT-7", "MGT-7A", "AGM"], "work_type": "ROC/MCA", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 13, "docs": ["Consent (DIR-2) of new director", "DIN / KYC of new director", "Resignation letter (if any)", "Board resolution"], "name": "Director change", "steps": [{"who": "Staff", "name": "Collect consent (DIR-2), DIN, KYC / resignation letter"}, {"who": "Staff", "name": "Board / members' resolution"}, {"who": "Staff", "name": "File DIR-12 within 30 days"}, {"who": "Staff", "name": "Update register of directors"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["DIR-12"], "work_type": "ROC/MCA", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 14, "docs": ["Allottee details & PAN", "Bank proof of share money received", "Board resolution", "Valuation report (if required)"], "name": "Share allotment / capital increase", "steps": [{"who": "Staff", "name": "Check authorised capital; if increase needed pass resolution & file SH-7 within 30 days"}, {"who": "Staff", "name": "Receive share money in company bank account"}, {"who": "Staff", "name": "Board resolution for allotment"}, {"who": "Staff", "name": "File PAS-3 within 15 days of allotment"}, {"who": "Staff", "name": "MGT-14 if special resolution passed"}, {"who": "Staff", "name": "Issue share certificates within 2 months"}, {"who": "Staff", "name": "Update register of members; update tracker"}], "matches": ["PAS-3", "SH-7"], "work_type": "ROC/MCA", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 15, "docs": ["Statement of accounts", "Partner contribution details", "Partner KYC"], "name": "LLP annual filing", "steps": [{"who": "Staff", "name": "Statement of accounts finalised"}, {"who": "Staff", "name": "LLP Form 11 by 30 May"}, {"who": "Staff", "name": "LLP Form 8 by 30 October"}, {"who": "Staff", "name": "Designated partner KYC check"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["LLP Form 11", "LLP Form 8"], "work_type": "ROC/MCA", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 16, "docs": ["Attendance & salary sheet", "New joinee details", "Exit details"], "name": "PF / ESI monthly", "steps": [{"who": "Staff", "name": "Get attendance & salary data"}, {"who": "Staff", "name": "Prepare ECR / contribution file"}, {"who": "Staff", "name": "Client pays by 15th of next month"}, {"who": "Staff", "name": "Download challan & receipt"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["PF return (ECR)", "ESI return"], "work_type": "Other", "updated_at": "2026-11-03T12:18:26.640406+00:00"}, {"id": 17, "docs": ["Bank statements", "Sales invoices", "Purchase bills", "Expense bills", "Cash book"], "name": "Monthly accounting / bookkeeping", "steps": [{"who": "Staff", "name": "Collect bank statements, sales, purchase, expense bills"}, {"who": "Staff", "name": "Post entries"}, {"who": "Staff", "name": "Bank reconciliation"}, {"who": "Staff", "name": "Ledger scrutiny (suspense, debtors, creditors)"}, {"who": "Staff", "name": "Share MIS / P&L with client"}, {"who": "Staff", "name": "Update tracker"}], "matches": ["Accounting / bookkeeping"], "work_type": "Other", "updated_at": "2026-11-03T12:18:26.640406+00:00"}]$seed$::jsonb) on conflict do nothing;
insert into public.linked_rules select * from jsonb_populate_recordset(null::public.linked_rules, $seed$[{"id": 1, "law": "Sec 173(1)", "form": "Minutes", "action": "Hold first board meeting", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "Within 30 days of incorporation", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "First board meeting", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 2, "law": "Sec 139(6); Rule 4(2)", "form": "ADT-1", "action": "Appoint first auditor by Board & file ADT-1", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "Board within 30 days of incorporation; ADT-1 within 15 days of appointment (if Board fails, members at EGM within 90 days)", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "ADT-1 (first auditor)", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 3, "law": "Sec 184(1), 164(2)", "form": "MBP-1, DIR-8", "action": "Directors' disclosure of interest", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "At first board meeting (and every first meeting of FY)", "work_type": "ROC/MCA", "applies_to": "All directors", "task_return": "MBP-1 / DIR-8", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 4, "law": "Sec 10A", "form": "INC-20A", "action": "Declaration for commencement of business", "matches": ["Company incorporation (SPICe+)"], "due_days": 180, "due_rule": "Within 180 days of incorporation", "work_type": "ROC/MCA", "applies_to": "Companies with share capital", "task_return": "INC-20A", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 5, "law": "Sec 56(4)(a)", "form": "Share certificate (SH-1)", "action": "Issue share certificates to subscribers", "matches": ["Company incorporation (SPICe+)"], "due_days": 60, "due_rule": "Within 60 days of incorporation", "work_type": "ROC/MCA", "applies_to": "Companies with share capital", "task_return": "Share certificates", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 6, "law": "Sec 12(1)", "form": "INC-22", "action": "Verify registered office", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "Within 30 days of incorporation (if not given at incorporation)", "work_type": "ROC/MCA", "applies_to": "Where RO not filed in SPICe+", "task_return": "INC-22", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 7, "law": "Sec 10A", "form": "Bank proof", "action": "Open bank account; deposit subscription money", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "Before filing INC-20A", "work_type": "ROC/MCA", "applies_to": "Companies with share capital", "task_return": "Bank account & share money", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 8, "law": "Sec 88, 170", "form": "MGT-1, etc.", "action": "Set up statutory registers (members, directors, charges)", "matches": ["Company incorporation (SPICe+)"], "due_days": 30, "due_rule": "From incorporation", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "Statutory registers", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 9, "law": "Sec 90", "form": "BEN-2", "action": "Receive BEN-1 from significant beneficial owner & file BEN-2", "matches": ["Company incorporation (SPICe+)"], "due_days": null, "due_rule": "Within 30 days of receiving BEN-1", "work_type": "ROC/MCA", "applies_to": "Where SBO exists", "task_return": "BEN-2", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 10, "law": "GST Act / labour laws", "form": "REG-01 etc.", "action": "GST / PF / ESI / Professional tax registrations", "matches": ["Company incorporation (SPICe+)"], "due_days": null, "due_rule": "When threshold / business starts", "work_type": "Other", "applies_to": "As applicable", "task_return": "Registrations (GST / PF / ESI / PT)", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 11, "law": "Rule 9B, PAS Rules", "form": "ISIN / demat", "action": "Dematerialise shares (private companies other than small)", "matches": ["Company incorporation (SPICe+)"], "due_days": null, "due_rule": "Check current MCA deadline", "work_type": "ROC/MCA", "applies_to": "Private companies (not small)", "task_return": "Demat of shares", "trigger_event": "Company incorporated (SPICe+)"}, {"id": 12, "law": "Sec 137", "form": "AOC-4", "action": "File financial statements", "matches": ["AGM"], "due_days": 30, "due_rule": "Within 30 days of AGM", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "AOC-4", "trigger_event": "AGM held"}, {"id": 13, "law": "Sec 92", "form": "MGT-7 / MGT-7A", "action": "File annual return", "matches": ["AGM"], "due_days": 60, "due_rule": "Within 60 days of AGM", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "MGT-7", "trigger_event": "AGM held"}, {"id": 14, "law": "Sec 139; Rule 4(2)", "form": "ADT-1", "action": "Auditor appointed / reappointed", "matches": ["AGM"], "due_days": 15, "due_rule": "Within 15 days of AGM", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "ADT-1", "trigger_event": "AGM held"}, {"id": 15, "law": "Sec 140(2)", "form": "ADT-3", "action": "Auditor files resignation", "matches": [], "due_days": 30, "due_rule": "Within 30 days of resignation", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "ADT-3", "trigger_event": "Auditor resigns"}, {"id": 16, "law": "Sec 139(8)", "form": "ADT-1", "action": "Fill casual vacancy & file ADT-1", "matches": [], "due_days": 30, "due_rule": "Board within 30 days; ADT-1 within 15 days", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "ADT-1", "trigger_event": "Auditor resigns"}, {"id": 17, "law": "Sec 168, 170", "form": "DIR-12", "action": "Intimate ROC", "matches": [], "due_days": 30, "due_rule": "Within 30 days of change", "work_type": "ROC/MCA", "applies_to": "All companies", "task_return": "DIR-12", "trigger_event": "Director appointed / resigned"}, {"id": 18, "law": "Sec 39(4), 42", "form": "PAS-3", "action": "Return of allotment", "matches": ["PAS-3"], "due_days": 15, "due_rule": "Within 15 days of allotment", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "PAS-3", "trigger_event": "Shares allotted"}, {"id": 19, "law": "Sec 56(4)(c)", "form": "SH-1", "action": "Issue share certificates", "matches": ["PAS-3"], "due_days": 60, "due_rule": "Within 2 months of allotment", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "Share certificates", "trigger_event": "Shares allotted"}, {"id": 20, "law": "Sec 64", "form": "SH-7", "action": "Notice of alteration", "matches": [], "due_days": 30, "due_rule": "Within 30 days of resolution", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "SH-7", "trigger_event": "Authorised capital increased"}, {"id": 21, "law": "Sec 117", "form": "MGT-14", "action": "File resolution", "matches": [], "due_days": 30, "due_rule": "Within 30 days of passing", "work_type": "ROC/MCA", "applies_to": "As per Sec 117", "task_return": "MGT-14", "trigger_event": "Special resolution passed"}, {"id": 22, "law": "Sec 77", "form": "CHG-1", "action": "Register charge", "matches": [], "due_days": 30, "due_rule": "Within 30 days of creation", "work_type": "ROC/MCA", "applies_to": "Companies with loans secured", "task_return": "CHG-1", "trigger_event": "Charge created / modified"}, {"id": 23, "law": "Sec 82", "form": "CHG-4", "action": "Satisfaction of charge", "matches": [], "due_days": 30, "due_rule": "Within 30 days of satisfaction", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "CHG-4", "trigger_event": "Charge satisfied (loan closed)"}, {"id": 24, "law": "Sec 12(4)", "form": "INC-22", "action": "Intimate ROC", "matches": [], "due_days": 15, "due_rule": "Within 15 days of change", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "INC-22", "trigger_event": "Registered office changed"}, {"id": 25, "law": "Sec 13", "form": "INC-24", "action": "Name change approval", "matches": [], "due_days": 30, "due_rule": "Within 60 days of RoC name approval or 30 days of SR (earlier)", "work_type": "ROC/MCA", "applies_to": "Companies", "task_return": "INC-24", "trigger_event": "Company name changed"}, {"id": 26, "law": "Rule 16, Deposit Rules", "form": "DPT-3", "action": "Return of deposits", "matches": [], "due_days": null, "due_rule": "By 30 June every year", "work_type": "ROC/MCA", "applies_to": "Companies (not Govt)", "task_return": "DPT-3", "trigger_event": "Loans / deposits outstanding on 31 Mar"}, {"id": 27, "law": "MSMED Act s.9 notification", "form": "MSME-1", "action": "Half-yearly return", "matches": [], "due_days": null, "due_rule": "By 30 Apr and 31 Oct", "work_type": "ROC/MCA", "applies_to": "Companies with such dues", "task_return": "MSME-1", "trigger_event": "MSME vendor dues > 45 days"}, {"id": 28, "law": "Sec 23, LLP Act", "form": "LLP Form 3", "action": "File LLP agreement", "matches": ["LLP incorporation (FiLLiP)"], "due_days": 30, "due_rule": "Within 30 days of incorporation", "work_type": "ROC/MCA", "applies_to": "All LLPs", "task_return": "LLP Form 3", "trigger_event": "LLP incorporated"}, {"id": 29, "law": "Sec 23, LLP Act", "form": "LLP Form 3", "action": "File change", "matches": [], "due_days": 30, "due_rule": "Within 30 days of change", "work_type": "ROC/MCA", "applies_to": "LLPs", "task_return": "LLP Form 3", "trigger_event": "LLP agreement changed"}, {"id": 30, "law": "Sec 25, LLP Act", "form": "LLP Form 4", "action": "Intimate ROC", "matches": [], "due_days": 30, "due_rule": "Within 30 days of change", "work_type": "ROC/MCA", "applies_to": "LLPs", "task_return": "LLP Form 4", "trigger_event": "LLP partner change"}, {"id": 31, "law": "Sec 34, 35", "form": "LLP Form 11 / Form 8", "action": "Annual return / statement of accounts", "matches": [], "due_days": null, "due_rule": "Form 11 by 30 May; Form 8 by 30 Oct", "work_type": "ROC/MCA", "applies_to": "All LLPs", "task_return": "LLP Form 11", "trigger_event": "LLP financial year end"}, {"id": 32, "law": "CGST Act", "form": "GSTR-1, 3B", "action": "Start returns from effective date; choose QRMP if eligible", "matches": ["GST registration (REG-01)"], "due_days": null, "due_rule": "From effective date of registration", "work_type": "GST", "applies_to": "New GSTINs", "task_return": "GSTR-1", "trigger_event": "GST registration obtained"}, {"id": 33, "law": "Rule 96A", "form": "RFD-11", "action": "File LUT for zero-rated supplies", "matches": ["GST registration (REG-01)"], "due_days": null, "due_rule": "Before first export / start of every FY", "work_type": "GST", "applies_to": "Exporters / SEZ suppliers", "task_return": "LUT (RFD-11)", "trigger_event": "GST registration obtained (exporter)"}, {"id": 34, "law": "Rule 48(4)", "form": "IRN / e-invoice", "action": "Start e-invoicing", "matches": [], "due_days": null, "due_rule": "From applicability date", "work_type": "GST", "applies_to": "AATO > Rs 5 Cr", "task_return": "E-invoice / IRN", "trigger_event": "Turnover crosses e-invoice limit"}, {"id": 35, "law": "Sec 45", "form": "GSTR-10", "action": "Final return", "matches": ["GST cancellation (REG-16)"], "due_days": 90, "due_rule": "Within 3 months of cancellation order", "work_type": "GST", "applies_to": "Cancelled GSTINs", "task_return": "GSTR-10", "trigger_event": "GST registration cancelled"}, {"id": 36, "law": "Rule 62", "form": "CMP-08, GSTR-4", "action": "Quarterly statement & annual return", "matches": [], "due_days": null, "due_rule": "CMP-08 by 18th after quarter; GSTR-4 by 30 Apr", "work_type": "GST", "applies_to": "Composition dealers", "task_return": "CMP-08", "trigger_event": "Opted composition"}, {"id": 37, "law": "Sec 44", "form": "GSTR-9 / 9C", "action": "Annual return (+ 9C if > Rs 5 Cr)", "matches": [], "due_days": null, "due_rule": "By 31 December", "work_type": "GST", "applies_to": "Regular taxpayers", "task_return": "GSTR-9 / 9C", "trigger_event": "Year end - GST turnover > Rs 2 Cr"}, {"id": 38, "law": "Rule 30", "form": "Challan 281", "action": "Deposit TDS", "matches": [], "due_days": null, "due_rule": "By 7th of next month (March: 30 April)", "work_type": "TDS", "applies_to": "Deductors", "task_return": "TDS deposit", "trigger_event": "TDS deducted"}, {"id": 39, "law": "Rule 31A", "form": "24Q / 26Q / 27Q", "action": "File quarterly return", "matches": [], "due_days": null, "due_rule": "31st of month after quarter (Q4: 31 May)", "work_type": "TDS", "applies_to": "Deductors", "task_return": "26Q (other than salary)", "trigger_event": "TDS quarter ends"}, {"id": 40, "law": "Rule 31", "form": "Form 16A", "action": "Issue TDS certificate", "matches": ["26Q (other than salary)", "26Q"], "due_days": 15, "due_rule": "Within 15 days of return due date", "work_type": "TDS", "applies_to": "Deductors", "task_return": "Form 16A (TDS certificate)", "trigger_event": "26Q filed & processed"}, {"id": 41, "law": "Rule 31", "form": "Form 16", "action": "Issue salary certificate", "matches": ["24Q (salary)", "24Q"], "due_days": null, "due_rule": "By 15 June", "work_type": "TDS", "applies_to": "Employers", "task_return": "Form 16 (salary certificate)", "trigger_event": "Q4 24Q filed"}, {"id": 42, "law": "Sec 194-IA", "form": "26QB, Form 16B", "action": "TDS statement-cum-challan & certificate", "matches": ["26QB (property)"], "due_days": 30, "due_rule": "26QB within 30 days of month end; 16B within 15 days after", "work_type": "TDS", "applies_to": "Buyers", "task_return": "26QB (property)", "trigger_event": "Property bought > Rs 50 lakh"}, {"id": 43, "law": "Respective Act", "form": "Reply", "action": "Reply / attend", "matches": [], "due_days": null, "due_rule": "As per notice date", "work_type": "Other", "applies_to": "All", "task_return": "Notice reply", "trigger_event": "Notice received (GST / IT / MCA)"}]$seed$::jsonb) on conflict do nothing;
insert into public.data_request_templates select * from jsonb_populate_recordset(null::public.data_request_templates, $seed$[{"body": "Dear {contact},\r\n\r\nGreetings!\r\n\r\nAs the due dates for {due_line} for {period} are approaching, we request you to kindly share the following data/documents at the earliest to ensure timely and accurate filing.\r\n\r\nA. Sales data (for GSTR-1)\r\n1. Sales register / sales invoices (B2B & B2C) for the period\r\n2. Credit notes / debit notes issued, if any\r\n3. Export invoices (with shipping bill details, if applicable)\r\n4. Advance receipts against future supplies, if any\r\n5. HSN/SAC-wise summary of outward supplies\r\n6. Details of any amendments to previous invoices\r\n7. E-way bill details, if applicable\r\n\r\nB. Purchase data (for GSTR-3B & ITC reconciliation)\r\n1. Purchase register / purchase invoices for the period\r\n2. Import purchase details (Bill of Entry), if any\r\n3. Credit notes / debit notes received, if any\r\n4. Expense invoices where ITC is to be claimed\r\n\r\nC. RCM checklist (please confirm which apply)\r\n1. Legal services from an individual advocate / firm of advocates\r\n2. Goods Transport Agency (GTA) services (other than GTA under forward charge)\r\n3. Security services from a person other than a body corporate\r\n4. Sponsorship services\r\n5. Director's remuneration / services (other than salary)\r\n6. Director sitting fees\r\n7. Rent-a-cab / motor vehicle hire services\r\n8. Import of services from outside India\r\n9. Renting of residential dwelling to a registered person\r\n10. Renting of commercial / non-residential property by an unregistered person to a registered person\r\n11. Any other notified goods/services under RCM\r\n\r\nD. Other requirements\r\n1. Details of any GST notices / communication received, if any\r\n2. Any changes in business details (address, bank account, authorised signatory) to be updated on the GST portal\r\n\r\nKindly share the above data in the usual format (Tally export / Excel) by {reply_by} to allow time for review, reconciliation and filing before the due date. You can reply to this email with the files, or upload them on your client portal: {portal}\r\n\r\nPlease let us know if you have any questions or need more time to compile the data.\r\n\r\nThank you for your cooperation.\r\n\r\nBest regards,\r\n{firm}\r\n{firm_phone}", "kind": "gst", "subject": "Request for Sales & Purchase Data – {returns} for {period} – {client}", "updated_at": null, "updated_by": null}, {"body": "Dear {contact},\r\n\r\nGreetings!\r\n\r\nThe TDS deducted in {period} has to be paid by {due}. To prepare the TDS workings and challans on time, we request you to share the following details for {period}.\r\n\r\nA. Payments and expenses for the month (party name, PAN, date, amount and nature of payment for each)\r\n1. Contractor / sub-contractor payments, including manpower supply – 393(1) Sl. 6(i) [old 194C]\r\n2. Professional fees – 393(1) Sl. 6(iii)(b) [old 194J(b)]; technical services – 393(1) Sl. 6(iii)(a) [old 194J(a)]\r\n3. Rent of land, building or furniture – 393(1) Sl. 2(ii)(b) [old 194-I(b)]; rent of plant or machinery – 393(1) Sl. 2(ii)(a) [old 194-I(a)]\r\n4. Commission / brokerage – 393(1) Sl. 1(ii) [old 194H]\r\n5. Interest paid other than to banks (loans, deposits) – 393(1) Sl. 5(iii) [old 194A]\r\n6. Director sitting fees / commission (other than salary) – 393(1) Sl. 6(iii) [old 194J]\r\n7. Salary, remuneration, commission or interest to partners – 393(3) Sl. 7 [old 194T]\r\n8. Purchase of goods where purchases from a seller cross Rs. 50 lakh in the year (if your turnover is above Rs. 10 crore) – 393(1) Sl. 8(ii) [old 194Q]\r\n9. Payments to non-residents – 393(2) [old 195]\r\n10. Any other payment where TDS may apply (business benefits / perquisites, etc.)\r\n\r\nB. Salary (if we compute salary TDS) – 392 [old 192]\r\n1. Salary register for the month\r\n2. New joiners and employees who left, with PAN\r\n3. Any change in investment declarations or tax regime chosen by employees\r\n\r\nC. Party details\r\n1. PAN of new vendors / parties paid this month\r\n2. Lower / nil deduction certificates received – Form 128 [old Form 13]\r\n3. Declarations received for no deduction – Form 121 [old Form 15G / 15H]\r\n\r\nD. TDS already paid by you\r\n1. Copy of any TDS challan you have paid yourselves this month (date, amount, BSR code, challan number)\r\n\r\nKindly share the above in the usual format (Tally export / Excel) by {reply_by}, so that we can send you the TDS payment intimation before the due date. You can reply to this email with the files, or upload them on your client portal: {portal}\r\n\r\nIf there were no payments liable to TDS this month, please reply \"No TDS for {period}\" so we can close the month.\r\n\r\nThank you for your cooperation.\r\n\r\nBest regards,\r\n{firm}\r\n{firm_phone}", "kind": "tds_pay", "subject": "Request for Data – TDS Payment Workings for {period} – {client}", "updated_at": null, "updated_by": null}, {"body": "Dear {contact},\r\n\r\nGreetings!\r\n\r\nThe quarterly TDS return for {quarter} of {fy} ({quarter_months}) is due on {due}. To file it on time and avoid late fee (Rs. 200 per day under section 427 [old 234E]), we request you to share or confirm the following.\r\n\r\nA. Deduction details for the quarter\r\n1. Party-wise details of all payments on which TDS was deducted: name, PAN, section, date of payment / credit, amount and TDS\r\n2. Details of payments where TDS was not deducted or deducted at a lower rate, with the reason (threshold not crossed, lower deduction certificate, declaration received)\r\n3. Lower / nil deduction certificates – Form 128 [old Form 13] – and declarations – Form 121 [old Form 15G / 15H] – received during the quarter\r\n\r\nB. TDS paid\r\n1. Copies of all TDS challans paid for the quarter (date, amount, BSR code, challan number), including any paid by you directly\r\n2. Interest or late fee paid, if any\r\n\r\nC. Salary – Form 138 [old 24Q] (if applicable)\r\n1. Salary register for the quarter, with employee PAN\r\n2. New joiners and employees who left during the quarter\r\n3. For Q4 only: full-year salary details, final investment proofs and tax regime chosen by each employee\r\n\r\nD. Other details\r\n1. Any change in the deductor's details (address, responsible person, contact number, email)\r\n2. Any notice or default intimation received from TRACES\r\n\r\nIf our monthly TDS workings for the quarter already cover all your payments, please just confirm \"No changes for {quarter}\" and share any challans paid directly by you.\r\n\r\nKindly share the above by {reply_by}. You can reply to this email with the files, or upload them on your client portal: {portal}\r\nForm 131 [old Form 16A] certificates will be issued after the return is processed.\r\n\r\nThank you for your cooperation.\r\n\r\nBest regards,\r\n{firm}\r\n{firm_phone}", "kind": "tds_return", "subject": "Request for Data – TDS Return for {quarter} {fy} (Form {forms}) – {client}", "updated_at": null, "updated_by": null}]$seed$::jsonb) on conflict do nothing;

insert into public.settings (id, firm_name) values (1, 'JLR Compliance') on conflict do nothing;
insert into public.ai_settings (id) values (1) on conflict do nothing;
insert into public.auto_work_settings (id) values (1) on conflict do nothing;
insert into public.chase_settings (id) values (1) on conflict do nothing;
insert into public.data_request_settings (id) values (1) on conflict do nothing;
insert into public.gst_settings (id) values (1) on conflict do nothing;
insert into public.mail_settings (id) values (1) on conflict do nothing;
insert into public.notice_watch (id) values (1) on conflict do nothing;
insert into public.wa_settings (id) values (1) on conflict do nothing;
insert into public.zoho_settings (id) values (1) on conflict do nothing;
insert into public.zoho_state (id) values (1) on conflict do nothing;


-- ==== cron ====
select cron.schedule('audit-trim', '20 21 * * 0', 'delete from public.audit_log where at < now() - interval ''2 years''');
select cron.schedule('auto-gst-work', '35 0 * * *', 'select public.auto_gst_work()');
select cron.schedule('daily-backup', '0 18 * * *', 'select public.take_backup(''auto'')');
select cron.schedule('data-chase', '35 4 * * 1-6', 'select public.chase_run()');
select cron.schedule('data-requests', '30 3 1 * *', 'select public.dr_run()');
select cron.schedule('gst-bill-day', '35 3 * * *', 'select public.gst_bill_reminder()');
select cron.schedule('gst-tick', '*/5 * * * *', 'select public.gst_tick()');
select cron.schedule('review-reminders', '5 4 * * 1-6', 'select public.review_reminders()');
select cron.schedule('wa-client', '30 4 * * 1-6', 'select public.wa_client_reminders()');
select cron.schedule('wa-daily', '2 4 * * 1-6', 'select public.wa_daily_reminders()');
select cron.schedule('wa-monthly', '0 4 1 * *', 'select public.wa_monthly_due_list()');
select cron.schedule('zoho-sync', '*/30 2-15 * * *', 'select public.zoho_cron()');