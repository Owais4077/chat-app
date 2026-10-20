-- Relay initial schema. Run with the Supabase CLI or the SQL Editor.
create extension if not exists pgcrypto;

create type public.message_type as enum ('text', 'image', 'video', 'audio', 'document', 'system');
create type public.member_role as enum ('member', 'admin', 'owner');
create type public.receipt_status as enum ('delivered', 'read');
create type public.call_type as enum ('voice', 'video');
create type public.call_status as enum ('ringing', 'accepted', 'rejected', 'missed', 'ended', 'failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique check (username ~ '^[a-z0-9_]{3,32}$'),
  display_name text not null default '' check (char_length(display_name) <= 80),
  avatar_path text,
  bio text not null default '' check (char_length(bio) <= 280),
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null default 'member',
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete restrict,
  type public.message_type not null default 'text',
  content text not null default '',
  reply_to_id uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check ((type <> 'text') or char_length(trim(content)) > 0)
);

create table public.message_receipts (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.receipt_status not null,
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, status)
);

create table public.message_reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 16),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, emoji)
);

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  storage_path text not null unique,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  duration_ms integer check (duration_ms > 0),
  created_at timestamptz not null default now()
);

create table public.groups (
  conversation_id uuid primary key references public.conversations(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  avatar_path text,
  created_at timestamptz not null default now()
);

create table public.group_members (
  conversation_id uuid not null references public.groups(conversation_id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null default 'member',
  primary key (conversation_id, user_id)
);

create table public.calls (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references public.profiles(id) on delete restrict,
  receiver_id uuid not null references public.profiles(id) on delete restrict,
  type public.call_type not null,
  status public.call_status not null default 'ringing',
  started_at timestamptz not null default now(),
  answered_at timestamptz,
  ended_at timestamptz,
  check (caller_id <> receiver_id)
);

create table public.blocked_users (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index messages_conversation_created_at_idx on public.messages (conversation_id, created_at desc) where deleted_at is null;
create index conversation_members_user_id_idx on public.conversation_members (user_id, conversation_id);
create index message_receipts_user_id_idx on public.message_receipts (user_id, message_id);
create index notifications_user_created_at_idx on public.notifications (user_id, created_at desc);
create index calls_participants_started_at_idx on public.calls (caller_id, receiver_id, started_at desc);

create function public.conversation_member(target_conversation_id uuid, target_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.conversation_members where conversation_id = target_conversation_id and user_id = target_user_id);
$$;

create function public.conversation_admin(target_conversation_id uuid, target_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.conversation_members where conversation_id = target_conversation_id and user_id = target_user_id and role in ('admin', 'owner'));
$$;

create function public.user_blocked(target_user_id uuid, other_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.blocked_users where blocker_id = target_user_id and blocked_id = other_user_id);
$$;

create function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger conversations_updated_at before update on public.conversations for each row execute function public.set_updated_at();
create trigger messages_updated_at before update on public.messages for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_receipts enable row level security;
alter table public.message_reactions enable row level security;
alter table public.attachments enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.calls enable row level security;
alter table public.blocked_users enable row level security;
alter table public.user_devices enable row level security;
alter table public.notifications enable row level security;

create policy "profiles readable by authenticated users" on public.profiles for select to authenticated using (true);
create policy "profiles self update" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles self insert" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "members read conversations" on public.conversations for select to authenticated using (public.conversation_member(id));
create policy "members read membership" on public.conversation_members for select to authenticated using (public.conversation_member(conversation_id));
create policy "members read messages" on public.messages for select to authenticated using (public.conversation_member(conversation_id));
create policy "members send messages" on public.messages for insert to authenticated with check (
  sender_id = auth.uid()
  and public.conversation_member(conversation_id)
  and not exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = messages.conversation_id
      and cm.user_id <> auth.uid()
      and public.user_blocked(cm.user_id, auth.uid())
  )
);
create policy "senders edit own messages" on public.messages for update to authenticated using (sender_id = auth.uid() and public.conversation_member(conversation_id)) with check (sender_id = auth.uid() and public.conversation_member(conversation_id));
create policy "members read receipts" on public.message_receipts for select to authenticated using (exists (select 1 from public.messages m where m.id = message_id and public.conversation_member(m.conversation_id)));
create policy "users write own receipts" on public.message_receipts for insert to authenticated with check (user_id = auth.uid());
create policy "members read reactions" on public.message_reactions for select to authenticated using (exists (select 1 from public.messages m where m.id = message_id and public.conversation_member(m.conversation_id)));
create policy "users manage own reactions" on public.message_reactions for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "members read attachments" on public.attachments for select to authenticated using (exists (select 1 from public.messages m where m.id = message_id and public.conversation_member(m.conversation_id)));
create policy "members read groups" on public.groups for select to authenticated using (public.conversation_member(conversation_id));
create policy "admins update groups" on public.groups for update to authenticated using (public.conversation_admin(conversation_id)) with check (public.conversation_admin(conversation_id));
create policy "members read group members" on public.group_members for select to authenticated using (public.conversation_member(conversation_id));
create policy "admins manage group members" on public.group_members for all to authenticated using (public.conversation_admin(conversation_id)) with check (public.conversation_admin(conversation_id));
create policy "call participants read calls" on public.calls for select to authenticated using (caller_id = auth.uid() or receiver_id = auth.uid());
create policy "caller starts calls" on public.calls for insert to authenticated with check (caller_id = auth.uid() and not public.user_blocked(receiver_id, caller_id));
create policy "participants update calls" on public.calls for update to authenticated using (caller_id = auth.uid() or receiver_id = auth.uid()) with check (caller_id = auth.uid() or receiver_id = auth.uid());
create policy "users manage own blocks" on public.blocked_users for all to authenticated using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
create policy "users manage own devices" on public.user_devices for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users read own notifications" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "users update own notifications" on public.notifications for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
