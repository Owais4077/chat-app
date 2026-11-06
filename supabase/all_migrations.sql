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
-- Create a public profile automatically for every Supabase Auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, ''), '@', 1), ''), 80)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
-- Private phone identities and owner-only contacts for CHAT APP.
-- Phone numbers are not stored on public.profiles because profiles are readable.

create table public.phone_identities (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  phone_e164 text not null unique check (phone_e164 ~ '^\\+[1-9][0-9]{7,14}$'),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 80),
  phone_e164 text not null check (phone_e164 ~ '^\\+[1-9][0-9]{7,14}$'),
  registered_user_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, phone_e164)
);

create trigger phone_identities_updated_at before update on public.phone_identities
for each row execute function public.set_updated_at();
create trigger contacts_updated_at before update on public.contacts
for each row execute function public.set_updated_at();

alter table public.phone_identities enable row level security;
alter table public.contacts enable row level security;

create policy "users manage own phone identity" on public.phone_identities for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "owners manage own contacts" on public.contacts for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create function public.set_my_phone_identity(target_phone_e164 text)
returns public.phone_identities language plpgsql security definer set search_path = public as $$
declare saved_identity public.phone_identities;
begin
  if auth.uid() is null then raise exception 'A signed-in user is required.'; end if;
  if target_phone_e164 !~ '^\\+[1-9][0-9]{7,14}$' then raise exception 'Enter an international phone number.'; end if;
  insert into public.phone_identities (user_id, phone_e164) values (auth.uid(), target_phone_e164)
  on conflict (user_id) do update set phone_e164 = excluded.phone_e164, verified_at = null
  returning * into saved_identity;
  return saved_identity;
exception when unique_violation then raise exception 'That phone number is already in use.';
end;
$$;

create function public.save_contact(target_display_name text, target_phone_e164 text)
returns public.contacts language plpgsql security definer set search_path = public as $$
declare saved_contact public.contacts; matched_user_id uuid;
begin
  if auth.uid() is null then raise exception 'A signed-in user is required.'; end if;
  if char_length(trim(target_display_name)) not between 1 and 80 then raise exception 'Enter a contact name.'; end if;
  if target_phone_e164 !~ '^\\+[1-9][0-9]{7,14}$' then raise exception 'Enter an international phone number.'; end if;
  select user_id into matched_user_id from public.phone_identities where phone_e164 = target_phone_e164;
  insert into public.contacts (owner_id, display_name, phone_e164, registered_user_id)
  values (auth.uid(), trim(target_display_name), target_phone_e164, matched_user_id)
  on conflict (owner_id, phone_e164) do update set display_name = excluded.display_name, registered_user_id = excluded.registered_user_id
  returning * into saved_contact;
  return saved_contact;
end;
$$;

revoke all on function public.set_my_phone_identity(text) from public;
revoke all on function public.save_contact(text, text) from public;
grant execute on function public.set_my_phone_identity(text) to authenticated;
grant execute on function public.save_contact(text, text) to authenticated;
-- CHAT APP Phase 1: private conversations, groups, and member-only summaries.
-- All privileged changes go through the RPC functions below. The Flutter app
-- must never insert/update conversation_members directly.

drop policy if exists "members read group members" on public.group_members;
drop policy if exists "admins manage group members" on public.group_members;

create function public.get_or_create_direct_conversation(target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
  found_conversation_id uuid;
begin
  if caller_id is null then raise exception 'Sign in is required.'; end if;
  if target_user_id is null or target_user_id = auth.uid() then
    raise exception 'You cannot start a conversation with yourself.';
  end if;
  if not exists (select 1 from public.profiles where id = target_user_id) then
    raise exception 'This user is unavailable.';
  end if;
  if public.user_blocked(caller_id, target_user_id)
      or public.user_blocked(target_user_id, caller_id) then
    raise exception 'A conversation cannot be started with this user.';
  end if;

  select c.id into found_conversation_id
  from public.conversations c
  join public.conversation_members cm on cm.conversation_id = c.id
  where not c.is_group
  group by c.id
  having count(*) = 2
     and bool_or(cm.user_id = caller_id)
     and bool_or(cm.user_id = target_user_id);

  if found_conversation_id is null then
    insert into public.conversations (is_group, created_by)
    values (false, caller_id)
    returning id into found_conversation_id;

    insert into public.conversation_members (conversation_id, user_id, role)
    values
      (found_conversation_id, caller_id, 'owner'),
      (found_conversation_id, target_user_id, 'member');
  end if;

  return found_conversation_id;
end;
$$;

create function public.create_group_conversation(
  group_name text,
  member_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
  found_conversation_id uuid;
  normalized_name text := trim(coalesce(group_name, ''));
  requested_member_id uuid;
begin
  if caller_id is null then raise exception 'Sign in is required.'; end if;
  if char_length(normalized_name) not between 1 and 100 then
    raise exception 'Enter a group name between 1 and 100 characters.';
  end if;
  if coalesce(cardinality(member_ids), 0) = 0 then
    raise exception 'Choose at least one group member.';
  end if;

  for requested_member_id in
    select distinct member_id
    from unnest(member_ids) as member_id
    where member_id is not null and member_id <> caller_id
  loop
    if not exists (select 1 from public.profiles where id = requested_member_id) then
      raise exception 'A selected user is unavailable.';
    end if;
    if public.user_blocked(caller_id, requested_member_id)
        or public.user_blocked(requested_member_id, caller_id) then
      raise exception 'A selected user cannot join this group.';
    end if;
  end loop;

  if not exists (
    select 1
    from unnest(member_ids) as member_id
    where member_id is not null and member_id <> caller_id
  ) then
    raise exception 'Choose at least one group member.';
  end if;

  insert into public.conversations (is_group, created_by)
  values (true, caller_id)
  returning id into found_conversation_id;

  insert into public.groups (conversation_id, name)
  values (found_conversation_id, normalized_name);

  insert into public.conversation_members (conversation_id, user_id, role)
  values (found_conversation_id, caller_id, 'owner');

  insert into public.conversation_members (conversation_id, user_id, role)
  select found_conversation_id, member_id, 'member'
  from (
    select distinct member_id
    from unnest(member_ids) as member_id
    where member_id is not null and member_id <> caller_id
  ) selected_members;

  return found_conversation_id;
end;
$$;

create function public.add_group_member(
  target_conversation_id uuid,
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then raise exception 'Sign in is required.'; end if;
  if not exists (
    select 1 from public.conversations
    where id = target_conversation_id and is_group
  ) then raise exception 'This is not a group.'; end if;
  if not public.conversation_admin(target_conversation_id, caller_id) then
    raise exception 'Only a group administrator can add members.';
  end if;
  if target_user_id is null or not exists (
    select 1 from public.profiles where id = target_user_id
  ) then raise exception 'This user is unavailable.'; end if;
  if public.user_blocked(caller_id, target_user_id)
      or public.user_blocked(target_user_id, caller_id) then
    raise exception 'This user cannot be added to the group.';
  end if;

  insert into public.conversation_members (conversation_id, user_id, role)
  values (target_conversation_id, target_user_id, 'member')
  on conflict (conversation_id, user_id) do nothing;
end;
$$;

create function public.remove_group_member(
  target_conversation_id uuid,
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
  target_role public.member_role;
begin
  if caller_id is null then raise exception 'Sign in is required.'; end if;
  if not exists (
    select 1 from public.conversations
    where id = target_conversation_id and is_group
  ) then raise exception 'This is not a group.'; end if;
  if not public.conversation_admin(target_conversation_id, caller_id) then
    raise exception 'Only a group administrator can remove members.';
  end if;

  select role into target_role
  from public.conversation_members
  where conversation_id = target_conversation_id and user_id = target_user_id;
  if target_role is null then raise exception 'This user is not in the group.'; end if;
  if target_role in ('admin', 'owner')
      and not exists (
        select 1 from public.conversation_members
        where conversation_id = target_conversation_id
          and user_id = caller_id
          and role = 'owner'
      ) then
    raise exception 'Only the group owner can remove an administrator.';
  end if;
  if target_role = 'owner' and not exists (
    select 1 from public.conversation_members
    where conversation_id = target_conversation_id
      and user_id <> target_user_id
      and role = 'owner'
  ) then
    raise exception 'A group must keep at least one owner.'; -- last owner
  end if;

  delete from public.conversation_members
  where conversation_id = target_conversation_id and user_id = target_user_id;
end;
$$;

create function public.set_group_member_role(
  target_conversation_id uuid,
  target_user_id uuid,
  target_role public.member_role
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then raise exception 'Sign in is required.'; end if;
  if not exists (
    select 1 from public.conversations
    where id = target_conversation_id and is_group
  ) then raise exception 'This is not a group.'; end if;
  if not exists (
    select 1 from public.conversation_members
    where conversation_id = target_conversation_id
      and user_id = caller_id
      and role = 'owner'
  ) then raise exception 'Only the group owner can change administrator roles.'; end if;
  if target_role not in ('member', 'admin') then
    raise exception 'Owner role cannot be changed here.';
  end if;
  if not exists (
    select 1 from public.conversation_members
    where conversation_id = target_conversation_id and user_id = target_user_id
  ) then raise exception 'This user is not in the group.'; end if;

  update public.conversation_members
  set role = target_role
  where conversation_id = target_conversation_id and user_id = target_user_id;
end;
$$;

create function public.mark_conversation_read(target_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Sign in is required.'; end if;
  update public.conversation_members
  set last_read_at = now()
  where conversation_id = target_conversation_id and user_id = auth.uid();
  if not found then raise exception 'Conversation not found.'; end if;
end;
$$;

create function public.get_conversation_summaries()
returns table (
  conversation_id uuid,
  is_group boolean,
  title text,
  last_message_preview text,
  last_message_at timestamptz,
  unread_count bigint,
  my_role public.member_role
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id,
    c.is_group,
    case
      when c.is_group then g.name
      else coalesce(nullif(other_profile.display_name, ''), nullif(other_profile.username, ''), 'Private chat')
    end,
    coalesce(last_message.content, ''),
    last_message.created_at,
    (
      select count(*)
      from public.messages unread_message
      where unread_message.conversation_id = c.id
        and unread_message.sender_id <> auth.uid()
        and unread_message.deleted_at is null
        and (my_membership.last_read_at is null or unread_message.created_at > my_membership.last_read_at)
    ),
    my_membership.role
  from public.conversation_members my_membership
  join public.conversations c on c.id = my_membership.conversation_id
  left join public.groups g on g.conversation_id = c.id
  left join lateral (
    select p.display_name, p.username
    from public.conversation_members other_member
    join public.profiles p on p.id = other_member.user_id
    where other_member.conversation_id = c.id
      and other_member.user_id <> auth.uid()
    order by other_member.joined_at
    limit 1
  ) other_profile on not c.is_group
  left join lateral (
    select m.content, m.created_at
    from public.messages m
    where m.conversation_id = c.id and m.deleted_at is null
    order by m.created_at desc
    limit 1
  ) last_message on true
  where my_membership.user_id = auth.uid()
  order by last_message.created_at desc nulls last, c.updated_at desc;
$$;

revoke all on function public.get_or_create_direct_conversation(uuid) from public;
revoke all on function public.create_group_conversation(text, uuid[]) from public;
revoke all on function public.add_group_member(uuid, uuid) from public;
revoke all on function public.remove_group_member(uuid, uuid) from public;
revoke all on function public.set_group_member_role(uuid, uuid, public.member_role) from public;
revoke all on function public.mark_conversation_read(uuid) from public;
revoke all on function public.get_conversation_summaries() from public;

grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;
grant execute on function public.create_group_conversation(text, uuid[]) to authenticated;
grant execute on function public.add_group_member(uuid, uuid) to authenticated;
grant execute on function public.remove_group_member(uuid, uuid) to authenticated;
grant execute on function public.set_group_member_role(uuid, uuid, public.member_role) to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
grant execute on function public.get_conversation_summaries() to authenticated;
