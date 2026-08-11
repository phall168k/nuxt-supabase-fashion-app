begin;

alter table public.user_profiles
    add column phone_number varchar(50) default null,
    add column address text default null;

comment on column public.user_profiles.phone_number is
    'Optional customer contact phone number.';
comment on column public.user_profiles.address is
    'Optional customer delivery or contact address.';

-- Backfill contact details already stored in Auth metadata.
update public.user_profiles as profile
set phone_number = coalesce(
        profile.phone_number,
        nullif(btrim(coalesce(
            auth_user.raw_user_meta_data ->> 'phone_number',
            auth_user.raw_user_meta_data ->> 'phone'
        )), '')
    ),
    address = coalesce(
        profile.address,
        nullif(btrim(auth_user.raw_user_meta_data ->> 'address'), '')
    )
from auth.users as auth_user
where auth_user.id = profile.user_id
  and (profile.phone_number is null or profile.address is null);

-- Keep profile records synchronized when customer contact details are
-- supplied through Supabase Auth user metadata during sign-up or updates.
create or replace function public.sync_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.user_profiles (
        user_id,
        full_name,
        role,
        profile,
        phone_number,
        address
    )
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', ''),
        case when lower(coalesce(new.raw_app_meta_data ->> 'role', '')) = 'admin'
            then 'admin' else 'customer' end,
        nullif(new.raw_user_meta_data ->> 'profile', ''),
        nullif(btrim(coalesce(
            new.raw_user_meta_data ->> 'phone_number',
            new.raw_user_meta_data ->> 'phone'
        )), ''),
        nullif(btrim(new.raw_user_meta_data ->> 'address'), '')
    )
    on conflict (user_id) do update
    set full_name = coalesce(
            new.raw_user_meta_data ->> 'full_name',
            public.user_profiles.full_name
        ),
        profile = coalesce(
            nullif(new.raw_user_meta_data ->> 'profile', ''),
            public.user_profiles.profile
        ),
        phone_number = case
            when new.raw_user_meta_data ? 'phone_number' then
                nullif(btrim(new.raw_user_meta_data ->> 'phone_number'), '')
            when new.raw_user_meta_data ? 'phone' then
                nullif(btrim(new.raw_user_meta_data ->> 'phone'), '')
            else public.user_profiles.phone_number
        end,
        address = case
            when new.raw_user_meta_data ? 'address' then
                nullif(btrim(new.raw_user_meta_data ->> 'address'), '')
            else public.user_profiles.address
        end,
        updated_at = now();
    return new;
end;
$$;

-- The existing RLS policy still restricts updates to the profile owner.
-- Extend the existing column-level privilege to the new contact fields.
grant update (phone_number, address) on public.user_profiles to authenticated;

commit;
