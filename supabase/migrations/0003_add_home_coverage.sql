-- Adds structured home-insurance coverage fields to an existing policies table.
-- Run this once in the Supabase SQL editor, then run:
--   NOTIFY pgrst, 'reload schema';
-- to force the API layer to pick up the new column immediately.

alter table policies add column if not exists home_coverage jsonb not null default '{}'::jsonb;
