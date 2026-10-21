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
