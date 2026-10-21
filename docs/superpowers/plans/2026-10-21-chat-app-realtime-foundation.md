# CHAT APP Realtime Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver authenticated users real direct text messaging, safe contact management, and call-state UI that can later attach to Agora audio/video.

**Architecture:** Replace the mock chat provider with a Supabase repository behind the existing `ChatRepository` contract. Add phone/contact tables and RPCs that preserve RLS boundaries, then expose Contacts and Calls as Riverpod-backed pages. Keep Agora credentials off-device; a later server function issues participant-bound tokens.

**Tech Stack:** Flutter, Riverpod, go_router, supabase_flutter, Supabase PostgreSQL/RLS/Realtime, Flutter test, Agora RTC (phase 4).

**Spec:** `docs/superpowers/specs/2026-10-21-chat-app-realtime-design.md`

## Global Constraints

- Use only public build configuration in Flutter; never commit a certificate, secret key, password, or test user credential.
- Preserve existing RLS and add migration-based schema changes only.
- Every behavior change is test-first and must leave `flutter analyze` and `flutter test` green.
- Contacts require explicit user consent; automatic address-book upload is prohibited.
- Calls use the existing secure Agora project but cannot issue a production token before a server secret is configured.

## Review Focus

- A user cannot send a direct message into a conversation they do not belong to.
- A phone number is normalized and cannot be claimed by two profiles.
- Contact discovery reveals only a registered-contact match, not unrelated profiles or phone numbers.
- Blocking prevents new messages and calls in both directions.
- An Agora token is issued only for the authenticated call participant and expires quickly.

---

### Task 1: Live direct-message repository

**Files:**
- Create: `lib/features/chat/data/supabase_chat_repository.dart`
- Modify: `lib/features/chat/domain/chat_repository.dart`
- Modify: `lib/features/chat/presentation/chat_controller.dart`
- Modify: `lib/features/chat/presentation/chat_list_screen.dart`
- Test: `test/features/chat/data/supabase_chat_repository_test.dart`
- Test: `test/features/chat/presentation/chat_controller_test.dart`

**Interfaces:**
- Produces `SupabaseChatRepository.watchConversations()`, `watchMessages(String)`, and `sendTextMessage(...)` using the authenticated Supabase client.
- Produces `ChatController.load()` and live stream subscription disposal.

- [ ] Write failing tests for mapping a database row to a conversation/message and rejecting blank or unauthorized sends.
- [ ] Run focused tests and confirm expected failure because the repository/provider does not exist.
- [ ] Implement the minimal Supabase repository and inject it through a provider; retain `MockChatRepository` for widget tests.
- [ ] Make the chat list and conversation screen display stream-backed loading, empty, error, and message states.
- [ ] Run focused tests, then `flutter analyze && flutter test`.
- [ ] Commit with `feat: add live direct messaging`.

### Task 2: Phone identity and contacts migration

**Files:**
- Create: `supabase/migrations/202610220001_phone_contacts.sql`
- Create: `test/supabase/phone_contacts_contract_test.dart`
- Modify: `supabase/README.md`

**Interfaces:**
- Produces `profiles.phone_e164`, `contacts`, and security-definer RPCs for safe direct-conversation creation/contact matching.

- [ ] Write a failing SQL contract test requiring normalized unique phone storage, owner-only contact writes, and no broad contact-list read policy.
- [ ] Run the contract test and confirm it fails because the migration is absent.
- [ ] Add the idempotent migration, indexes, RLS policies, and narrowly scoped RPCs.
- [ ] Document SQL Editor application and a rollback-safe testing checklist.
- [ ] Run focused tests and full verification.
- [ ] Commit with `feat: add secure phone contacts schema`.

### Task 3: Profile phone and manual contact UI

**Files:**
- Create: `lib/features/contacts/domain/contact.dart`
- Create: `lib/features/contacts/domain/contact_repository.dart`
- Create: `lib/features/contacts/data/supabase_contact_repository.dart`
- Create: `lib/features/contacts/presentation/contacts_screen.dart`
- Create: `lib/features/contacts/presentation/add_contact_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/contacts/presentation/add_contact_screen_test.dart`
- Test: `test/features/contacts/data/supabase_contact_repository_test.dart`

**Interfaces:**
- Produces `ContactRepository.saveContact`, `watchContacts`, `startDirectConversation`, and `ContactsScreen` routed at `/contacts`.

- [ ] Write failing tests for E.164-style validation, duplicate rejection, and a saved contact launching a direct conversation.
- [ ] Run focused tests and confirm expected failure.
- [ ] Implement manual contact creation/search/listing with user-friendly failures and no raw backend errors.
- [ ] Replace the Contacts placeholder route and link a saved contact to the conversation screen.
- [ ] Run focused tests, analyzer, and the full suite.
- [ ] Commit with `feat: add saved contacts and direct chat start`.

### Task 4: Call records and real-time call state

**Files:**
- Create: `lib/features/calls/domain/call.dart`
- Create: `lib/features/calls/domain/call_repository.dart`
- Create: `lib/features/calls/data/supabase_call_repository.dart`
- Create: `lib/features/calls/presentation/calls_screen.dart`
- Create: `lib/features/calls/presentation/incoming_call_screen.dart`
- Modify: `lib/features/chat/presentation/conversation_screen.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/calls/presentation/call_controller_test.dart`

**Interfaces:**
- Produces `CallRepository.start`, `accept`, `reject`, `end`, and `watchIncoming`; adds voice/video call actions to a direct conversation.

- [ ] Write failing tests for creating a ringing call, accepting/rejecting it, and not calling a blocked user.
- [ ] Run focused tests and confirm expected failure.
- [ ] Implement call records and Supabase Realtime subscription; show an accessible incoming-call page and call history.
- [ ] Add voice/video buttons to direct chats; keep the media join action behind a token provider interface.
- [ ] Run focused tests, analyzer, and the full suite.
- [ ] Commit with `feat: add realtime call state and history`.

### Task 5: Secure Agora token service and media joining

**Files:**
- Create: `supabase/functions/agora-token/index.ts`
- Create: `supabase/functions/agora-token/deno.json`
- Create: `lib/features/calls/data/agora_call_media_gateway.dart`
- Modify: `pubspec.yaml`
- Test: `test/features/calls/data/agora_call_media_gateway_test.dart`
- Modify: `supabase/README.md`

**Interfaces:**
- Produces an authenticated Edge Function that validates call participation and returns a short-lived token for one channel/user.
- Produces `AgoraCallMediaGateway.join({required Call call, required String token})`.

- [ ] Write failing tests for refusing a nonparticipant token request and forwarding a valid token/channel to the media gateway.
- [ ] Run focused tests and confirm expected failure.
- [ ] Implement the Edge Function with `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` Supabase secrets; do not log either value.
- [ ] Add the maintained Agora Flutter RTC dependency and the minimal join/leave media gateway.
- [ ] Document setting server secrets and deploying the function, using placeholders only.
- [ ] Run focused tests, analyzer, and full tests; perform two-device manual call verification.
- [ ] Commit with `feat: add secure Agora voice and video calls`.

### Task 6: Consent-based Android contact import

**Files:**
- Create: `lib/features/contacts/data/device_contact_importer.dart`
- Modify: `lib/features/contacts/presentation/contacts_screen.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/features/contacts/data/device_contact_importer_test.dart`

**Interfaces:**
- Produces `DeviceContactImporter.pickContacts()` returning only user-selected normalized contact candidates.

- [ ] Write failing tests for denied permission, cancelled selection, and duplicate number de-duplication.
- [ ] Run focused tests and confirm expected failure.
- [ ] Add the minimal maintained contact-picker dependency and Android permission declaration; show a consent explanation before requesting access.
- [ ] Present a review/selection screen before saving selected contacts to Supabase.
- [ ] Run focused tests, analyzer, and full tests on a physical Android device.
- [ ] Commit with `feat: add consent based contact import`.

### Task 7: Follow-on product releases

**Files:** separate implementation plans per release.

- [ ] Create a media/status plan: Storage uploads, voice notes, files, camera, 24-hour status, and content visibility.
- [ ] Create a groups/workspaces plan: roles, channels, announcements, polls, events, and moderation.
- [ ] Create a notifications/privacy plan: FCM, device tokens, notification preferences, block/report, disappearing messages, and account controls.
- [ ] Create a search/quality plan: full-text search, archive/mute/pin, accessibility, offline states, and observability.

