-- Renewal Desk schema
-- Run this once in the Supabase SQL editor for your project.

create table if not exists customers (
  id text primary key,
  user_id uuid not null default auth.uid(),
  name text not null,
  email text,
  phone text,
  street text,
  city text,
  state text,
  zip text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists policies (
  id text primary key,
  user_id uuid not null default auth.uid(),
  customer_id text not null references customers(id) on delete cascade,
  policy_type text,
  carrier text,
  named_insured text,
  policy_number text,
  premium text,
  premium_frequency text,
  deductible text,
  renewal_date date,
  coverage_limits text,
  auto_coverage jsonb not null default '{}'::jsonb,
  notes text,
  insured_items jsonb not null default '[]'::jsonb,
  file_path text,
  file_name text,
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id text primary key,
  user_id uuid not null default auth.uid(),
  customer_id text not null references customers(id) on delete cascade,
  policy_id text references policies(id) on delete set null,
  title text not null,
  due_date date,
  priority text default 'low',
  status text default 'todo',
  auto boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

alter table customers enable row level security;
alter table policies enable row level security;
alter table tasks enable row level security;

drop policy if exists "own rows" on customers;
create policy "own rows" on customers for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on policies;
create policy "own rows" on policies for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own rows" on tasks;
create policy "own rows" on tasks for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Private bucket for uploaded declarations-page PDFs.
-- If this insert fails due to permissions, create it manually instead:
-- Dashboard -> Storage -> New bucket -> name "policy-files" -> Private.
insert into storage.buckets (id, name, public)
values ('policy-files', 'policy-files', false)
on conflict (id) do nothing;

-- Files are stored under "<user_id>/<customer_id>/<policy_id>.pdf", so the
-- first path segment doubles as the ownership check.
drop policy if exists "own files select" on storage.objects;
create policy "own files select" on storage.objects for select
  using (bucket_id = 'policy-files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own files insert" on storage.objects;
create policy "own files insert" on storage.objects for insert
  with check (bucket_id = 'policy-files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own files update" on storage.objects;
create policy "own files update" on storage.objects for update
  using (bucket_id = 'policy-files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own files delete" on storage.objects;
create policy "own files delete" on storage.objects for delete
  using (bucket_id = 'policy-files' and (storage.foldername(name))[1] = auth.uid()::text);
