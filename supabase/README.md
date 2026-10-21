# Supabase database

## Phone contacts

Apply `migrations/202610220001_phone_contacts.sql` after the messaging and profile migrations. It adds private phone identities and owner-only contacts. Phone verification is test-mode only until an SMS provider is configured.

Apply migrations with the Supabase CLI (`supabase link` then `supabase db push`) or paste the migration into the Dashboard SQL Editor. Use the project’s publishable key in mobile clients; never use a secret/service key there. The database password is required only for direct PostgreSQL administration and must be stored in a secret manager, not this repository.
