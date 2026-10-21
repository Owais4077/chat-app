# Supabase database

## Private and group chat

After the profile, messaging, and phone-contact migrations, apply
`migrations/202610220002_private_and_group_chat.sql`. In the Dashboard,
open **SQL Editor**, create a new query, paste the complete migration, then
choose **Run**. The expected response is **Success. No rows returned**.

This migration creates secure RPC functions for private conversations, groups,
member roles, read state, and conversation summaries. Do not create or modify
conversation membership rows directly from the mobile app. In **Database →
Replication**, enable Realtime for `conversation_members` and `messages`.

## Phone contacts

Apply `migrations/202610220001_phone_contacts.sql` after the messaging and profile migrations. It adds private phone identities and owner-only contacts. Phone verification is test-mode only until an SMS provider is configured.

Apply migrations with the Supabase CLI (`supabase link` then `supabase db push`) or paste the migration into the Dashboard SQL Editor. Use the project’s publishable key in mobile clients; never use a secret/service key there. The database password is required only for direct PostgreSQL administration and must be stored in a secret manager, not this repository.
