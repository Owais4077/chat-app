# Messaging Foundation Design

## Purpose

Build a cross-platform Flutter messaging application foundation that can run without external credentials today and connect to Supabase, Firebase Cloud Messaging, Supabase Storage, and WebRTC/TURN later without a structural rewrite. The first milestone is a secure, testable core flow: authentication, profile setup, contacts, conversations, realtime text-message interfaces, calls history, and settings UI.

## Audience and Success Criteria

The initial audience is intentionally deployment-neutral; the product must support a future private or public launch. Success for this milestone means a developer can clone the repository, configure public environment values when available, run the application in mock mode without secrets, navigate the core mobile flow, run static analysis and tests, and apply a reviewed Supabase schema when a project is created.

## Scope and Sequencing

This design decomposes the supplied product brief into independently testable milestones.

1. Foundation: Flutter project, architecture, theme, navigation, configuration, mock services, Supabase SQL/RLS, documentation, and core-flow UI.
2. Supabase integration: email auth, session lifecycle, profiles, user discovery, direct-conversation creation, paged realtime text messages, receipts, presence, and typing.
3. Rich messaging: Storage-backed image/video/document attachments, voice recording and playback, group administration, reactions, replies, edits, deletes, and search.
4. Delivery and calls: FCM device registration and secure server-side notification dispatch; WebRTC signaling, voice/video calls, TURN configuration, and call history.
5. Hardening: privacy controls, blocking/reporting, offline queue/retry, performance tuning, integration tests, security review, and release setup.

Only milestone 1 is implemented by the next plan. Later milestones receive their own approved design and plan.

## Technical Architecture

The client is Flutter/Dart, targeting Android and iOS with web-compatible boundaries. It uses Riverpod for dependency injection and state, GoRouter for declarative routing, and feature-first layers:

```text
lib/
  core/          configuration, errors, services, theme, utilities
  features/      auth, profile, contacts, chat, calls, settings
    <feature>/data, domain, presentation
  shared/        immutable models and reusable widgets
```

Presentation depends on domain contracts, never directly on Supabase or device APIs. Data implementations are selected through Riverpod providers: mock implementations are the default when no Supabase URL is configured, and real implementations are activated only after valid public configuration is supplied. This permits meaningful UI and unit/widget testing before credentials exist, while avoiding fabricated production behaviour.

## Navigation and UI

The initial app provides splash, onboarding, login, registration, password-reset, verification, profile setup, chat list, contact/user list, user search, private conversation, new-conversation, call history, settings, notification/privacy/account settings, blocked users, and logout-confirmation routes. Group and active-call routes are deliberately deferred until their underlying authorization and signaling exist.

The signed-in shell uses four areas: Chats, Calls, Contacts, and Settings. Reusable controls provide loading, empty, offline, and error states. Theme tokens provide accessible light/dark mode, consistent spacing, and no copied branding or proprietary assets.

## Backend Contract and Security Boundary

Supabase SQL is source-controlled in `supabase/migrations`. It creates UUID-keyed, normalized tables for profiles, conversations, conversation_members, messages, message_receipts, message_reactions, attachments, groups, group_members, calls, blocked_users, user_devices, and notifications. Each table has timestamps, foreign keys, constraints, and indexes for expected lookup paths.

Row Level Security remains enabled everywhere. Policies enforce self-only profile updates, membership-only conversation/message access, participant-only receipts and reactions, administrator-only group mutations, and self-only device-token access. Client-side UI checks improve usability but never authorize data. Storage buckets and policies will be introduced in the rich-messaging milestone, alongside server-side file validation and notification dispatch.

Authentication uses Supabase Auth email/password and refreshable persisted sessions once configured. Passwords, service-role keys, database passwords, private Firebase credentials, and production TURN credentials never enter the client or repository. `.env.example` exposes only variable names and safe public-client descriptions.

## Realtime and Call Boundaries

Supabase Realtime will provide conversation subscriptions; presence and typing use ephemeral channels rather than persistent typing rows. Receipts are persisted. Messages will use cursor pagination and a local pending/retry state.

Calls are separated into signaling, media, and call-state contracts. A future `CallSignalingRepository` will store authorized offers/answers/ICE candidates via Supabase Realtime, while a `WebRtcMediaService` owns permission handling and resource cleanup. STUN/TURN endpoints are environment-driven; no production relay credentials are embedded.

## Error Handling and Testing

User-facing failures are mapped from typed failures (authentication, connectivity, authorization, validation, upload, notification, and WebRTC) to plain messages. Raw backend errors are never rendered. Foundation tests cover route guards, configuration selection, theme/rendering, and mock authentication/chat contracts. Each later milestone adds unit tests, widget tests, and integration coverage for its critical path.

## External Configuration

Milestone 1 needs no secret. Before real integrations, the project owner supplies a Supabase project URL and anon/publishable key through local environment configuration. Firebase platform files, APNs configuration, Android signing credentials, production TURN credentials, and server-side notification credentials are explicitly blocked by external configuration and will be requested only at their relevant milestone.

## Non-Goals of the Foundation

The initial scaffold does not claim to send real messages, register real devices, transfer real files, record audio, or establish media calls. Those operations are absent until their services, security policies, and tests are implemented; the application uses clearly identified mock data only in development mode.
