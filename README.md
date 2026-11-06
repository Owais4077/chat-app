# Relay Messenger (CHAT APP)

A secure, real-time messaging application built with Flutter, Riverpod, GoRouter, and Supabase (PostgreSQL, Row Level Security, and Realtime).

## Features

- **Authentication**: Email registration and sign-in with user profile provisioning.
- **Phone Contacts**: International phone number normalization (E.164) and saved contact management.
- **Private Chats**: Start direct conversations with registered contacts with block prevention and duplicate check.
- **Group Chats**: Create group conversations, manage group membership (Owner, Admin, Member roles), and assign permissions safely via backend security-definer RPCs.
- **Real-Time Messaging**: Real-time message synchronization with read receipts and unread count badges.
- **Secure Architecture**: All privileged membership mutations go through PostgreSQL RPCs. Zero direct client writes to membership tables.

---

## Configuration & Environment

The app can run in mock mode (default if Supabase config is missing) or connect to a live Supabase project.

Pass public environment configuration via Dart defines:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or configure `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## Supabase Database Setup

1. Apply migrations in `supabase/migrations/` in order:
   - `202610200001_initial_messaging_schema.sql`
   - `202610210001_create_profile_on_signup.sql`
   - `202610220001_phone_contacts.sql`
   - `202610220002_private_and_group_chat.sql`
2. Under **Database → Replication**, enable Realtime replication for:
   - `conversation_members`
   - `messages`

See [`supabase/README.md`](supabase/README.md) for full instructions.

---

## Two-Account Manual Rollout Verification

Perform manual verification across two separate devices or emulator instances (Account A and Account B):

1. **Private Chat & Realtime Synchronization**:
   - Account A saves Account B's registered international phone number in Contacts.
   - Account A taps **Message** to create/open a direct conversation.
   - Account A sends a text message.
   - Verify Account B receives the message live without refreshing or restarting the app.
2. **Unread Count & Read Receipt**:
   - Verify Account B sees an unread counter badge on the Chats list.
   - When Account B opens the conversation, verify the badge resets to 0.
3. **Group Creation & Messaging**:
   - From Chats, Account A selects the **+** action → **New group**.
   - Account A enters a group name, selects Account B from the registered contacts list, and taps **Create group**.
   - Account A sends a message in the group; Account B receives it in real time.
4. **Group Membership & Role Permissions**:
   - Account A opens the conversation and taps **Group info**.
   - Verify Account A (Owner) can see **Add member**, **Remove**, and **Make admin**.
   - Account B (Member) opens **Group info** and cannot see **Add member**, **Remove**, or role change controls.
   - Account A promotes Account B to Admin. Verify Account B can now add members and remove ordinary members, but cannot remove owners or modify administrator roles.
5. **Row Level Security (RLS) Isolation**:
   - Account C (third user not in the group or conversation) cannot read or write messages in conversations where they are not a member.

---

## Verification & Testing

Run all quality checks:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
