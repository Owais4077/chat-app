# Private and Group Chat Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable authenticated CHAT APP users to start private chats from registered contacts, create and manage groups, and exchange real-time text messages securely.

**Architecture:** One additive Supabase migration exposes security-definer RPC functions for every privileged conversation and membership action. Flutter repositories call those RPCs, map conversation summaries to domain objects, and Riverpod screens render contacts, setup, summaries, and member controls. Supabase Realtime drives updates.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, Supabase Flutter/Postgres/RLS/Realtime, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-22-private-and-group-chat-phase-1-design.md`

## Global Constraints

- Preserve existing conversations, memberships, messages, groups, and contacts in one additive migration.
- Never commit a Supabase secret/service-role key, database password, Agora certificate, or phone/email credential.
- Membership creation and role changes must use authenticated RPC functions; the Flutter client must not write membership rows directly.
- Do not expose a contact's phone number or email in chat titles or summaries.
- Unknown backend errors must use safe user-facing copy and never show raw SQL or Supabase response text.
- Final verification is `dart format lib test`, `flutter analyze`, and `flutter test`.

## Review Focus

- Self-chat attempts must be rejected (Task 1).
- Duplicate/empty group selections must yield one row per valid selected user (Task 1).
- Admins cannot grant owner role or remove the final owner (Task 1).
- Unregistered contacts cannot start a direct conversation (Task 3).
- Members cannot see management actions unless their server-backed role permits it (Task 5).

---

### Task 1: Secure conversation and group RPC migration

**Files:**
- Create: `supabase/migrations/202610220002_private_and_group_chat.sql`
- Create: `test/supabase/private_and_group_chat_contract_test.dart`
- Modify: `supabase/README.md`

**Interfaces:**
- Produces `get_or_create_direct_conversation(uuid) returns uuid`, `create_group_conversation(text, uuid[]) returns uuid`, `add_group_member(uuid, uuid)`, `remove_group_member(uuid, uuid)`, `set_group_member_role(uuid, uuid, public.member_role)`, `mark_conversation_read(uuid)`, and `get_conversation_summaries()`.
- Consumed by Tasks 2-5.

- [x] **Step 1: Write failing SQL contract tests**

Assert the migration contains auth validation, controlled `security definer` search paths, direct-chat self/block checks, role/last-owner checks, authenticated grants/public revokes, and uses `conversation_members` as membership authority.

- [x] **Step 2: Verify red**

Run: `flutter test test/supabase/private_and_group_chat_contract_test.dart`

Expected: FAIL because the migration does not exist.

- [x] **Step 3: Implement the migration**

Create those RPCs and a member-only summary result with `conversation_id`, `is_group`, `title`, `last_message_preview`, `last_message_at`, `unread_count`, and `my_role`. The RPCs validate the caller, roles, target users, duplicates, blocks, and last-owner invariant. Use `conversation_members` consistently; do not expose phone/email fields.

- [x] **Step 4: Document migration application**

Add the SQL Editor application procedure and expected `Success. No rows returned` result to `supabase/README.md`.

- [x] **Step 5: Verify green**

Run: `flutter test test/supabase/private_and_group_chat_contract_test.dart`

Expected: PASS.

- [x] **Step 6: Commit**

```powershell
git add supabase/migrations/202610220002_private_and_group_chat.sql supabase/README.md test/supabase/private_and_group_chat_contract_test.dart
git commit -m "feat: add secure private and group chat RPCs"
```

### Task 2: Conversation summary domain and repository

**Files:**
- Create: `lib/features/chat/domain/conversation_summary.dart`
- Modify: `lib/features/chat/domain/conversation.dart`
- Modify: `lib/features/chat/domain/chat_repository.dart`
- Modify: `lib/features/chat/data/supabase_chat_repository.dart`
- Modify: `lib/features/chat/data/mock_chat_repository.dart`
- Modify: `test/features/chat/data/supabase_chat_repository_test.dart`
- Modify: `test/features/chat/data/mock_chat_repository_test.dart`

**Interfaces:**
- Produces `ConversationSummary`, `GroupMember`, `Future<String> startDirectConversation(String targetUserId)`, `Future<String> createGroup({required String name, required List<String> memberIds})`, `Future<void> markConversationRead(String conversationId)`, and `Stream<List<ConversationSummary>> watchConversationSummaries()`.
- Consumes Task 1 RPCs; consumed by Tasks 3-5.

- [x] **Step 1: Write failing repository tests**

Cover summary mapping, blank preview normalization, direct RPC parameters, group ID deduplication, and blank group-name rejection before network work.

- [x] **Step 2: Verify red**

Run: `flutter test test/features/chat/data/supabase_chat_repository_test.dart test/features/chat/data/mock_chat_repository_test.dart`

Expected: FAIL because models and operations are absent.

- [x] **Step 3: Implement summary and operations**

Extend `ChatDataSource` and both repositories. Fetch summaries through RPC and use membership Realtime as an invalidation signal that refetches summaries. Preserve behaviorally equivalent mock support.

- [x] **Step 4: Verify green**

Run: `flutter test test/features/chat/data/supabase_chat_repository_test.dart test/features/chat/data/mock_chat_repository_test.dart`

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add lib/features/chat test/features/chat/data
git commit -m "feat: add conversation summaries and group operations"
```

### Task 3: Registered contacts and direct-chat action

**Files:**
- Create: `lib/features/contacts/domain/contact.dart`
- Modify: `lib/features/contacts/domain/contact_repository.dart`
- Modify: `lib/features/contacts/data/supabase_contact_repository.dart`
- Modify: `lib/features/contacts/presentation/contacts_providers.dart`
- Modify: `lib/features/contacts/presentation/contacts_screen.dart`
- Modify: `test/features/contacts/presentation/contacts_screen_test.dart`

**Interfaces:**
- Produces `Contact { id, displayName, phoneE164, registeredUserId? }` and `Stream<List<Contact>> watchContacts()`.
- Consumes Task 2 `startDirectConversation`; consumed by Task 4.

- [x] **Step 1: Write failing contact screen tests**

Require a registered contact to show **Message**, an unregistered contact to show **Not on CHAT APP**, and a Message tap to start a chat and navigate using its returned ID.

- [x] **Step 2: Verify red**

Run: `flutter test test/features/contacts/presentation/contacts_screen_test.dart`

Expected: FAIL because streaming contacts and actions are absent.

- [x] **Step 3: Implement contact list and action**

Keep the manual Save form, render saved contacts below it, and use `registered_user_id` only for availability. Never render another user's phone identity.

- [x] **Step 4: Verify green**

Run: `flutter test test/features/contacts/presentation/contacts_screen_test.dart`

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add lib/features/contacts test/features/contacts/presentation/contacts_screen_test.dart
git commit -m "feat: message registered contacts"
```

### Task 4: Conversation list, routes, and group creation

**Files:**
- Create: `lib/features/chat/presentation/create_group_screen.dart`
- Modify: `lib/features/chat/presentation/chat_list_screen.dart`
- Modify: `lib/features/chat/presentation/chat_providers.dart`
- Modify: `lib/core/router/route_paths.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `test/features/chat/presentation/chat_list_screen_test.dart`
- Create: `test/features/chat/presentation/create_group_screen_test.dart`

**Interfaces:**
- Consumes Task 2 summaries/create-group and Task 3 contacts.
- Produces parameterized routes `/conversation/:conversationId` and `/groups/new`; consumed by Task 5.

- [x] **Step 1: Write failing list and create-group tests**

Assert title, preview, group icon, and positive-only unread badge. Assert a name plus selected registered contacts invokes `createGroup`; blank name/no members show validation without invoking it.

- [x] **Step 2: Verify red**

Run: `flutter test test/features/chat/presentation/chat_list_screen_test.dart test/features/chat/presentation/create_group_screen_test.dart`

Expected: FAIL because summaries and group screen are absent.

- [x] **Step 3: Implement list, routes, and setup UI**

Replace raw conversations with summaries. Add Chats menu actions **New message** (Contacts) and **New group**. Pass a conversation ID through route parameters, never in-memory objects.

- [x] **Step 4: Verify green**

Run: `flutter test test/features/chat/presentation/chat_list_screen_test.dart test/features/chat/presentation/create_group_screen_test.dart`

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add lib/features/chat lib/core/router test/features/chat/presentation
git commit -m "feat: create private and group conversations"
```

### Task 5: Read state and group management

**Files:**
- Create: `lib/features/chat/presentation/group_info_screen.dart`
- Modify: `lib/features/chat/presentation/conversation_screen.dart`
- Modify: `lib/features/chat/presentation/chat_controller.dart`
- Modify: `lib/features/chat/domain/chat_repository.dart`
- Modify: `lib/features/chat/data/supabase_chat_repository.dart`
- Modify: `lib/core/router/route_paths.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `test/features/chat/presentation/conversation_screen_test.dart`
- Create: `test/features/chat/presentation/group_info_screen_test.dart`

**Interfaces:**
- Consumes Task 1 membership RPCs and Task 2 summary role/title data.
- Produces route `/conversation/:conversationId/group-info`.

- [x] **Step 1: Write failing screen tests**

Assert opening marks read; a group exposes **Group info** while direct chat does not; ordinary members cannot see management actions; owners can; failures show safe copy.

- [x] **Step 2: Verify red**

Run: `flutter test test/features/chat/presentation/conversation_screen_test.dart test/features/chat/presentation/group_info_screen_test.dart`

Expected: FAIL because group controls and read state are absent.

- [x] **Step 3: Implement group/read behavior**

Pass title/group/role data through navigation. Mark read after the conversation listener begins. Add group member list and actions through repository RPCs, gating UI by role while keeping the server authoritative.

- [x] **Step 4: Verify green**

Run: `flutter test test/features/chat/presentation/conversation_screen_test.dart test/features/chat/presentation/group_info_screen_test.dart`

Expected: PASS.

- [x] **Step 5: Commit**

```powershell
git add lib/features/chat lib/core/router test/features/chat/presentation
git commit -m "feat: manage group members and read state"
```

### Task 6: Rollout guide and final verification

**Files:**
- Modify: `README.md`
- Modify: `supabase/README.md`
- Modify: `test/core/router/app_router_test.dart`

**Interfaces:** Consumes Tasks 1-5 and produces two-account rollout instructions.

- [x] **Step 1: Write failing router test**

Require `/groups/new`, the parameterized conversation route, and its group-info child route to be reachable only after authentication.

- [x] **Step 2: Verify red**

Run: `flutter test test/core/router/app_router_test.dart`

Expected: FAIL when required route/redirect is absent.

- [x] **Step 3: Add rollout documentation**

Document migration application, enabling Realtime tables, public Dart defines, and two-account tests for private messages, group messages, permissions, unread state, and RLS isolation.

- [x] **Step 4: Run full verification**

Run: `dart format lib test; flutter analyze; flutter test`

Expected: every command exits 0 with no analyzer issue or test failure.

- [x] **Step 5: Commit**

```powershell
git add README.md supabase/README.md test/core/router/app_router_test.dart
git commit -m "docs: verify private and group chat rollout"
```
