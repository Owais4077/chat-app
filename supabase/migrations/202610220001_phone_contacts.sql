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
