-- Adds address fields to an existing customers table.
-- Run this once in the Supabase SQL editor if your database was created
-- before these columns were added to supabase/schema.sql.

alter table customers add column if not exists street text;
alter table customers add column if not exists city text;
alter table customers add column if not exists state text;
alter table customers add column if not exists zip text;

NOTIFY pgrst, 'reload schema';
