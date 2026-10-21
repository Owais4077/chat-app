# CHAT APP Realtime Product Design

## Goal

Evolve CHAT APP from a mock conversation demo into a privacy-conscious messenger for personal chats and workspaces.

## Decisions already made

- Users can use email/password and optionally add a phone number. Phone OTP is test-mode only until an SMS provider is configured.
- Contacts support manual save first and Android address-book import only after the user explicitly grants permission and chooses what to import.
- Personal groups and work groups share a conversation foundation. Work groups can later gain roles, announcements, polls, files, and meetings.
- Direct messaging must be real Supabase data, not mock data.
- Agora is the real voice/video transport. Supabase owns call invitations, history, authorization, and short-lived Agora token issuance.
- Keep CHAT APP branding distinct from WhatsApp and do not collect/upload an entire address book without explicit user action.

## Delivery order

1. Live one-to-one text messaging backed by the existing Supabase schema.
2. Phone profile fields, manual contacts, contact lookup, and a safe Android import flow.
3. Real-time message updates, delivered/read state, blocking, and call history/incoming-call state.
4. Agora token Edge Function and voice/video SDK integration after the App Certificate is stored as a Supabase secret.
5. Media uploads, group/workspace controls, push notifications, status, and advanced privacy tools.

## Security boundaries

- No database password, Supabase secret key, Agora certificate, or SMS credential may be committed to source or placed in a Flutter build.
- The client may contain only the Supabase publishable key and Agora App ID.
- The server verifies the signed-in caller and call participants before issuing each short-lived Agora token.
- Phone numbers are normalized, stored only when the owner chooses to add them, and never exposed to unrelated users.
- Address-book import must explain what is shared, request platform permission, and allow selected contacts only.

