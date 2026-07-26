-- Adds structured auto-insurance coverage fields to an existing policies table.
-- Run this once in the Supabase SQL editor if your database was created
-- before this column was added to supabase/schema.sql.

alter table policies add column if not exists auto_coverage jsonb not null default '{}'::jsonb;
