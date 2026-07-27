-- Adds the quotes/savings-tracking feature to an existing database.
-- Run this once in the Supabase SQL editor, then run:
--   NOTIFY pgrst, 'reload schema';
-- to force the API layer to pick up the new tables immediately.

create table if not exists quotes (
  id text primary key,
  user_id uuid not null default auth.uid(),
  customer_id text not null references customers(id) on delete cascade,
  policy_id text not null references policies(id) on delete cascade,
  carrier text,
  policy_number text,
  premium text,
  premium_frequency text,
  renewal_date date,
  auto_coverage jsonb not null default '{}'::jsonb,
  home_coverage jsonb not null default '{}'::jsonb,
  notes text,
  screenshot_path text,
  screenshot_name text,
  status text not null default 'pending',
  savings_amount numeric,
  finalized_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists policy_history (
  id text primary key,
  user_id uuid not null default auth.uid(),
  customer_id text not null references customers(id) on delete cascade,
  policy_id text not null references policies(id) on delete cascade,
  quote_id text references quotes(id) on delete set null,
  carrier text,
  policy_number text,
  premium text,
  premium_frequency text,
  renewal_date date,
  coverage_limits text,
  deductible text,
  auto_coverage jsonb not null default '{}'::jsonb,
  home_coverage jsonb not null default '{}'::jsonb,
  savings_amount numeric,
  replaced_at timestamptz not null default now()
);

alter table quotes enable row level security;
alter table policy_history enable row level security;

drop policy if exists "own rows" on quotes;
create policy "own rows" on quotes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on policy_history;
create policy "own rows" on policy_history for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('quote-screenshots', 'quote-screenshots', false)
on conflict (id) do nothing;

drop policy if exists "own quote screenshots select" on storage.objects;
create policy "own quote screenshots select" on storage.objects for select
  using (bucket_id = 'quote-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own quote screenshots insert" on storage.objects;
create policy "own quote screenshots insert" on storage.objects for insert
  with check (bucket_id = 'quote-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own quote screenshots update" on storage.objects;
create policy "own quote screenshots update" on storage.objects for update
  using (bucket_id = 'quote-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own quote screenshots delete" on storage.objects;
create policy "own quote screenshots delete" on storage.objects for delete
  using (bucket_id = 'quote-screenshots' and (storage.foldername(name))[1] = auth.uid()::text);

NOTIFY pgrst, 'reload schema';
