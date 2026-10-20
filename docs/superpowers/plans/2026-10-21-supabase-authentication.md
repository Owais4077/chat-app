# Supabase Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Relay's email/password authentication, session persistence, and initial user profile provisioning operate against the configured Supabase project.

**Architecture:** A `SupabaseAuthRepository` implements the existing domain contract and is provided through Riverpod. Startup initializes the Supabase SDK only with valid build-time public configuration, and router access derives from the real auth stream. Authentication screens call a controller that owns loading/error state. A versioned SQL migration provisions a public profile when `auth.users` receives a new user.

**Tech Stack:** Flutter, Riverpod, go_router, supabase_flutter, Supabase PostgreSQL, Flutter test.

**Spec:** `docs/superpowers/specs/2026-10-21-supabase-auth-design.md`

## Global Constraints

- Use only `SUPABASE_URL` and `SUPABASE_ANON_KEY` supplied through `--dart-define`; never add database passwords, secret keys, or real keys to tracked files.
- Keep `.env` ignored and `.env.example` value-free except for the public project URL already present.
- All new behavior follows test-first development and preserves mockability through interfaces/providers.
- Authentication errors must be human-readable and must not expose backend error bodies.
- This phase must not implement live chat, calls, uploads, notifications, or Firebase functionality.

## Review Focus

- Missing or malformed public configuration must show a configuration state without SDK initialization or network calls (Task 1 test).
- A user who has no session must never reach `/chats` by manually entering its route (Task 3 test).
- An existing Supabase session must map to `AppUser` and send the user into the authenticated shell after restart (Task 2/3 tests).
- Whitespace-only email/password entries must not make a login or registration request (Task 4 widget test).
- New database users must receive exactly their own `profiles.id`, with no client-held elevated secret needed (Task 5 SQL contract test).

---

### Task 1: Supabase bootstrap and configuration gate

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/config/app_config.dart`
- Create: `lib/core/supabase/supabase_bootstrap.dart`
- Modify: `lib/main.dart`
- Test: `test/core/supabase/supabase_bootstrap_test.dart`

**Interfaces:**
- Consumes: `AppConfig.isSupabaseConfigured`
- Produces: `SupabaseBootstrap.initialize(AppConfig config) -> Future<bool>` where `true` means the SDK is usable.

- [ ] **Step 1: Write failing bootstrap tests**

Assert that an invalid URL or empty anon key returns `false` without invoking the initializer, while a valid HTTPS URL and non-empty key invokes initialization with those values.

- [ ] **Step 2: Run the bootstrap test to verify it fails**

Run: `flutter test test/core/supabase/supabase_bootstrap_test.dart`

Expected: FAIL because `SupabaseBootstrap` does not exist.

- [ ] **Step 3: Add `supabase_flutter` and implement the configuration-gated initializer**

Keep the SDK dependency isolated behind an injectable initialization callback so unit tests do not initialize global SDK state. Update `main` to await bootstrap before mounting the provider tree and make the bootstrap result available to providers.

- [ ] **Step 4: Run focused and full tests**

Run: `flutter test test/core/supabase/supabase_bootstrap_test.dart && flutter test`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/core/config lib/core/supabase test/core/supabase
git commit -m "feat: initialize Supabase from public build config"
```

### Task 2: Real authentication repository and providers

**Files:**
- Modify: `lib/features/auth/domain/auth_repository.dart`
- Modify: `lib/features/auth/data/mock_auth_repository.dart`
- Create: `lib/features/auth/data/supabase_auth_repository.dart`
- Create: `lib/features/auth/presentation/auth_providers.dart`
- Modify: `lib/core/errors/app_failure.dart`
- Modify: `lib/core/errors/failure_message.dart`
- Test: `test/features/auth/data/supabase_auth_repository_test.dart`
- Test: `test/features/auth/presentation/auth_providers_test.dart`

**Interfaces:**
- Consumes: `SupabaseBootstrap.initialize`, Supabase `AuthResponse` and auth events.
- Produces: `AuthRepository.signUp({required String email, required String password}) -> Future<SignUpResult>` and `currentUser() -> AppUser?`; an `authStateProvider` exposing the current `AsyncValue<AppUser?>`.

- [ ] **Step 1: Write failing repository and provider tests**

Test mapping of a Supabase user to `AppUser`, forwarding normalized email/password to sign-in/sign-up, expected invalid-credential mapping, and auth stream delivery through the provider.

- [ ] **Step 2: Run focused tests to verify they fail**

Run: `flutter test test/features/auth/data/supabase_auth_repository_test.dart test/features/auth/presentation/auth_providers_test.dart`

Expected: FAIL because the concrete repository and new contract members do not exist.

- [ ] **Step 3: Extend the contract and implement `SupabaseAuthRepository`**

Inject the Supabase auth client rather than reading a global client in repository methods. Map only known safe errors to validation/unauthorized/network failures; map all other server errors to unknown. Keep the mock repository compatible with the expanded contract.

- [ ] **Step 4: Add Riverpod overrides for configured and unconfigured clients**

When bootstrap is unavailable, provide an explicit unavailable repository/state instead of attempting auth. Publish real auth state changes when it is initialized.

- [ ] **Step 5: Run focused and full tests**

Run: `flutter test test/features/auth/data/supabase_auth_repository_test.dart test/features/auth/presentation/auth_providers_test.dart && flutter test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth lib/core/errors test/features/auth
git commit -m "feat: add Supabase authentication repository"
```

### Task 3: Session-aware routing and bootstrap state

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/main.dart`
- Test: `test/core/router/app_router_test.dart`
- Test: `test/app_bootstrap_test.dart`

**Interfaces:**
- Consumes: `authStateProvider`.
- Produces: router redirects based on loading, unauthenticated, and authenticated session states.

- [ ] **Step 1: Write failing routing tests**

Assert an unauthenticated `/chats` request redirects to Login, an authenticated request to Login redirects to Chats, and initial unresolved state routes to Splash rather than a protected page.

- [ ] **Step 2: Run router tests to verify they fail**

Run: `flutter test test/core/router/app_router_test.dart test/app_bootstrap_test.dart`

Expected: FAIL because the router currently has a fixed unauthenticated access level.

- [ ] **Step 3: Make router access depend on authentication state**

Use a provider-driven router refresh strategy. Preserve public routes needed for registration and email verification. Use Splash while auth state is loading and show a clear configuration state when the client is not configured.

- [ ] **Step 4: Run focused and full tests**

Run: `flutter test test/core/router/app_router_test.dart test/app_bootstrap_test.dart && flutter test`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/core/router test/core/router test/app_bootstrap_test.dart
git commit -m "feat: route Relay from Supabase session state"
```

### Task 4: Login and registration screens

**Files:**
- Create: `lib/features/auth/presentation/login_screen.dart`
- Create: `lib/features/auth/presentation/register_screen.dart`
- Create: `lib/features/auth/presentation/auth_form_controller.dart`
- Modify: `lib/core/router/app_router.dart`
- Test: `test/features/auth/presentation/login_screen_test.dart`
- Test: `test/features/auth/presentation/register_screen_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.signIn`, `AuthRepository.signUp`, `failureMessage`.
- Produces: concrete pages for `RoutePaths.login` and `RoutePaths.register`.

- [ ] **Step 1: Write failing widget tests**

Verify empty/whitespace fields render validation messages and make no request; valid sign-in disables duplicate submission during loading; successful registration displays the email-verification instruction when required.

- [ ] **Step 2: Run widget tests to verify they fail**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart test/features/auth/presentation/register_screen_test.dart`

Expected: FAIL because concrete auth screens/controllers do not exist.

- [ ] **Step 3: Implement focused forms and controller**

Use `Form` validation, accessible text labels, password obscuring, progress state, and plain-language error output. Do not log input values, passwords, raw exceptions, or tokens.

- [ ] **Step 4: Wire the concrete pages into routes**

Replace the generic feature screens only for Login and Register. Keep unrelated placeholder routes unchanged.

- [ ] **Step 5: Run focused and full tests**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart test/features/auth/presentation/register_screen_test.dart && flutter test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/presentation lib/core/router test/features/auth/presentation
git commit -m "feat: add Supabase login and registration screens"
```

### Task 5: Automatic profile provisioning migration

**Files:**
- Create: `supabase/migrations/202610210001_create_profile_on_signup.sql`
- Modify: `supabase/README.md`
- Test: `test/supabase/profile_provisioning_contract_test.dart`

**Interfaces:**
- Consumes: `auth.users` creation events and `public.profiles` schema.
- Produces: `public.handle_new_user() -> trigger` and trigger `on_auth_user_created`.

- [ ] **Step 1: Write a failing migration contract test**

Assert the migration defines a `security definer` trigger function with a fixed `search_path`, inserts `new.id` into `public.profiles`, and creates an `after insert on auth.users` trigger.

- [ ] **Step 2: Run the schema contract test to verify it fails**

Run: `flutter test test/supabase/profile_provisioning_contract_test.dart`

Expected: FAIL because the migration does not exist.

- [ ] **Step 3: Create an idempotent, secure profile trigger migration**

Use `insert ... on conflict (id) do nothing`; derive only a bounded display name from safe metadata/email data; do not grant service-role privileges or weaken RLS policies.

- [ ] **Step 4: Document applying the migration**

Update the Supabase README with SQL Editor/CLI directions and state that this migration must be applied to the remote project before real sign-ups are tested.

- [ ] **Step 5: Run focused and full tests**

Run: `flutter test test/supabase/profile_provisioning_contract_test.dart && flutter test`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/202610210001_create_profile_on_signup.sql supabase/README.md test/supabase/profile_provisioning_contract_test.dart
git commit -m "feat: provision profiles for new Supabase users"
```

### Task 6: End-to-end verification and operator handoff

**Files:**
- Modify: `.env.example`
- Modify: `README.md`

**Interfaces:**
- Consumes: the completed bootstrap, repository, UI, and migration.
- Produces: clear build/run instructions and a safe manual verification checklist.

- [ ] **Step 1: Document local run command**

Document the `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` format using placeholders only; do not copy a real key into the README.

- [ ] **Step 2: Run static analysis and complete test suite**

Run: `flutter analyze && flutter test`

Expected: analyzer reports no issues and all tests pass.

- [ ] **Step 3: Perform manual device verification**

Run the app with local public configuration, register a test email, verify it if required, sign in, verify the profile row in Navicat, restart to confirm session persistence, and sign out. Never record the password in the repository or test output.

- [ ] **Step 4: Commit**

```bash
git add .env.example README.md
git commit -m "docs: add Supabase authentication runbook"
```
