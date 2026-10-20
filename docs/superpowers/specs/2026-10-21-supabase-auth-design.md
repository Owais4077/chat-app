# Supabase Authentication Integration Design

## Goal

Replace Relay's mock authentication with Supabase email/password authentication so a real user can register, sign in, keep a session after an app restart, and sign out safely.

## Scope

This phase implements authentication and the authenticated application's entry point. It does not yet make messages, calls, uploads, push notifications, or Firebase services live.

## Configuration and security

- Add `supabase_flutter` as the supported client SDK.
- Initialize `Supabase` before `runApp` only when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are supplied using `--dart-define`.
- The Supabase URL and publishable/anon key can be included in a mobile client. Database passwords and Supabase secret keys must never appear in code, Git, tests, screenshots, or Flutter build arguments.
- Keep `.env` ignored. `.env.example` remains a key-free template.
- A missing configuration displays an actionable configuration state rather than attempting network calls.

## Domain contracts

`AuthRepository` gains registration and session-reading capabilities while retaining `authStateChanges`, `signIn`, and `signOut`. The concrete Supabase repository maps Supabase `User` data to the existing `AppUser` model and converts expected service errors into existing app failure messages.

The authentication provider exposes a stream/async state to presentation and routing. Mock implementations remain usable by unit tests through dependency injection.

## User experience and navigation

- The splash entry point waits for the initial auth state.
- Users without a session are redirected to Login.
- Login provides email and password fields, sign-in progress, and a link to account creation.
- Registration provides email and password fields. If Supabase requires email confirmation, it sends the user to the verification screen with clear instructions; otherwise it enters the app.
- A valid session enters Chats. Sign-out returns the user to Login.
- Existing profile setup routing remains reserved for a later profile-completion phase; it must not block users solely because the profile UI is not implemented yet.

## Profile provisioning

The current schema allows users to create their own profile, but a client-only insert could fail partway through sign-up. This phase therefore uses a database trigger on `auth.users` to create a minimal public `profiles` row when Supabase creates a user. The trigger uses `security definer`, a fixed `search_path`, and only user metadata fields that are safe to copy. A migration makes the behavior repeatable.

## Error handling

The app presents plain-language messages for invalid credentials, duplicate email, invalid input, unconfirmed email, network failure, and unexpected errors. It must not expose raw server responses, credentials, or keys.

## Testing and verification

- Unit tests prove config gating, user mapping, repository request delegation/error mapping, and access decisions for signed-out and signed-in states.
- Widget tests prove login validation and submission-state behavior using a fake repository.
- SQL contract tests assert the new profile-provisioning migration contains a trigger, safe `security definer` function, and row ownership checks.
- Run `flutter analyze`, the full `flutter test` suite, and the migration contract test before completion.

## Success criteria

With only the project URL and publishable key supplied through build-time configuration, a person can register an email/password account, complete required email verification, sign in, restart the app without being logged out, sign out, and see a matching row in `public.profiles` without any secret or database password stored in the repository.
