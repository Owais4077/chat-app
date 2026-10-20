# Supabase database

Apply migrations with the Supabase CLI (`supabase link` then `supabase db push`) or paste the migration into the Dashboard SQL Editor. Use the project’s publishable key in mobile clients; never use a secret/service key there. The database password is required only for direct PostgreSQL administration and must be stored in a secret manager, not this repository.
