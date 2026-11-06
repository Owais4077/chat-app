# Supabase database

## Migration Order & Application

Apply migrations in chronological order using the Supabase CLI (`supabase db push`) or by pasting each SQL script into the Dashboard **SQL Editor**:

1. `migrations/202610200001_initial_messaging_schema.sql`: Core tables (`profiles`, `conversations`, `conversation_members`, `messages`, `groups`) and initial Row Level Security (RLS) policies.
2. `migrations/202610210001_create_profile_on_signup.sql`: Automated profile provisioning trigger upon auth user sign-up.
3. `migrations/202610220001_phone_contacts.sql`: E.164 phone identity verification and owner-only contacts storage.
4. `migrations/202610220002_private_and_group_chat.sql`: Security-definer RPC functions for direct and group conversations, member management, read receipts, and member-only conversation summaries.

When executing each migration in the Supabase Dashboard SQL Editor, verify that the operation completes with:
`Success. No rows returned`.

## Realtime Configuration

In the Supabase Dashboard under **Database → Replication**:
- Enable Realtime replication for `public.conversation_members`.
- Enable Realtime replication for `public.messages`.

This ensures chat lists, unread counters, and conversation screens update reactively as events occur.

## Security Boundaries & RPC Functions

All privileged conversation actions must be executed through database RPCs:
- `get_or_create_direct_conversation(target_user_id uuid)`: Prevents self-chats, verifies user availability and block status, and returns a unique 1-to-1 conversation ID.
- `create_group_conversation(group_name text, member_ids uuid[])`: Validates group name, sets caller as owner, inserts valid members, and returns the group conversation ID.
- `add_group_member(target_conversation_id uuid, target_user_id uuid)`: Restricted to owners and administrators.
- `remove_group_member(target_conversation_id uuid, target_user_id uuid)`: Enforces last-owner preservation and prevents administrators from removing other admins or owners.
- `set_group_member_role(target_conversation_id uuid, target_user_id uuid, target_role member_role)`: Restricted to group owners only.
- `mark_conversation_read(target_conversation_id uuid)`: Updates caller's `last_read_at` timestamp.
- `get_conversation_summaries()`: Invoker RPC generating safe titles, unread counts, and last message previews for the authenticated user only.

Never use the service role key or database password in the mobile client. Only distribute the public publishable anon key.
