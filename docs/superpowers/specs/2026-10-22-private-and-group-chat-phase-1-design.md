# CHAT APP Phase 1: Private and Group Chat Design

## Goal

Ship a usable, real-time Android chat experience for two signed-in users. A user can save a contact, start one private conversation with that contact, create a group, manage its members when permitted, and exchange text messages in real time.

## Scope

- One-to-one conversations created from a registered saved contact.
- Groups with a name, owner, administrators, and members.
- Group owner can add and remove members and can promote or demote administrators.
- Members can see their own conversations, group membership, and messages, and can send text messages.
- Conversation list displays a safe title, latest text preview, latest message time, and unread count.
- Conversation screen receives new messages without refreshing and allows the current user to mark a conversation read.

## Out of scope

- Image, audio, file, reply, reaction, delete, search, push notification, live location, voice/video call, and address-book import.
- These are later phases; call support additionally requires a Supabase Edge Function with an Agora certificate stored only as a server secret.

## Architecture

The Flutter client continues to use Riverpod and `SupabaseChatRepository`. The repository gains explicit operations for starting direct conversations, creating groups, and changing group membership. UI pages call those methods through providers and never write membership rows directly.

The database remains the source of truth. PostgreSQL RPC functions validate the signed-in user, create related rows atomically, and return the resulting conversation ID. Supabase Realtime streams update conversation lists and message lists.

## Database and security design

Create one additive migration. It will:

1. Remove the duplicate `group_members` access path. `conversation_members` is the only membership table.
2. Add `get_or_create_direct_conversation(target_user_id uuid)`:
   - requires an authenticated caller;
   - refuses self-conversations;
   - verifies the target is a registered user and neither user has blocked the other;
   - finds an existing non-group conversation containing exactly both users, or creates it;
   - inserts both member rows and assigns the initiator owner role;
   - returns the conversation ID.
3. Add `create_group_conversation(group_name text, member_ids uuid[])`:
   - requires an authenticated caller;
   - normalizes and validates a 1-100 character group name;
   - creates a group conversation, its `groups` row, caller as owner, and unique valid target users as members;
   - returns the conversation ID.
4. Add `add_group_member`, `remove_group_member`, and `set_group_member_role` RPC functions:
   - require a current group owner or administrator;
   - only the owner may alter administrator/owner roles;
   - prevent removing the last owner;
   - reject direct conversations and invalid target users.
5. Add RLS policies for conversation creation and membership writes that reject direct client writes. The RPC functions run as definer with a controlled `public` search path; only `authenticated` can execute them.
6. Add a `conversation_summaries` security-invoker view or RPC returning only the caller's conversations: conversation ID, title data, last non-deleted text message/time, and unread count. The database builds private-chat names from member profile display name/username; group titles use `groups.name`.
7. Add `mark_conversation_read(conversation_id uuid)` for the current member. It updates only that member's `last_read_at`.

The migration must use `conversation_members` consistently. It must not make phone numbers, email addresses, or hidden profile fields visible to other users.

## Flutter user flows

### Contacts to private chat

The Contacts page lists the signed-in user’s saved contacts. A contact with `registered_user_id` has a **Message** action. Selecting it invokes `get_or_create_direct_conversation` and navigates to the conversation screen. A saved contact without a registered user displays **Not on CHAT APP** and cannot create a conversation.

### Create group

The Chats page has a new action with two choices: **New message** and **New group**. New group shows a name field and registered saved contacts with multi-select. Creating submits through the repository, opens the resulting group, and lists the creator as owner.

### Chats list

The list uses summaries rather than raw membership rows. It displays a group icon for groups, a person icon for private chats, title, latest preview, time, and a readable unread badge. Tapping opens the conversation.

### Group info

The conversation app bar has **Group info** for a group. It lists members and roles. Owners/admins see Add member and Remove member; only owners see change-admin actions. Any failure stays on screen with a plain, safe message.

## Error handling

- No signed-in session: show `Sign in is required.`
- Contact is not registered: show `This contact is not using CHAT APP yet.`
- Blocked user: show `A conversation cannot be started with this user.`
- Invalid group name/member selection or insufficient permissions: show the specific safe validation message from the repository.
- Connection or unknown Supabase failure: show `Could not complete that action. Check your connection and try again.` without exposing database internals.

## Tests and acceptance criteria

Automated tests cover:

- direct-conversation and group RPC request validation in the data source/repository;
- mapping a safe conversation summary to domain data;
- starting an existing/new direct conversation from a registered contact;
- group creation with selected contacts;
- visible latest message and unread badge;
- group-admin controls visible only for permitted roles;
- SQL contract tests that confirm every RPC validates `auth.uid()`, membership, roles, and no direct public write policy bypass exists.

Manual two-account verification uses two accounts on separate devices:

1. Account A saves Account B's registered phone identity and starts a private chat.
2. A sends a text message; B receives it without reopening the app.
3. A creates a group with B, sends a message, and B receives it.
4. A adds/removes a group member; an ordinary member cannot perform those operations.
5. B cannot read or send messages in any conversation where B is not a member.

## Later-phase dependency notes

Media needs Supabase Storage buckets and file-type/size policies. Push notifications need FCM credentials and a trusted server function. Live location needs clear consent, expiration, and an owner-controlled stop action. Voice/video calls need a token endpoint before Agora SDK integration.
