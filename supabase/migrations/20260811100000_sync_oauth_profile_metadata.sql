begin;

-- Populate profile photos for existing OAuth customers without replacing
-- images they have already uploaded themselves.
update public.user_profiles as profile
set profile = nullif(auth_user.raw_user_meta_data ->> 'avatar_url', ''),
    updated_at = now()
from auth.users as auth_user
where auth_user.id = profile.user_id
  and profile.profile is null
  and nullif(auth_user.raw_user_meta_data ->> 'avatar_url', '') is not null;

-- Google supplies avatar_url rather than profile. Accept either metadata key
-- while preserving the customer-controlled profile fields already in place.
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
        coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
        case when lower(coalesce(new.raw_app_meta_data ->> 'role', '')) = 'admin'
            then 'admin' else 'customer' end,
        coalesce(
            nullif(new.raw_user_meta_data ->> 'profile', ''),
            nullif(new.raw_user_meta_data ->> 'avatar_url', '')
        ),
        coalesce(
            nullif(new.raw_user_meta_data ->> 'phone_number', ''),
            nullif(new.raw_user_meta_data ->> 'phone', '')
        ),
        nullif(new.raw_user_meta_data ->> 'address', '')
    )
    on conflict (user_id) do update
    set full_name = coalesce(
            nullif(new.raw_user_meta_data ->> 'full_name', ''),
            nullif(new.raw_user_meta_data ->> 'name', ''),
            public.user_profiles.full_name
        ),
        profile = coalesce(
            nullif(new.raw_user_meta_data ->> 'profile', ''),
            public.user_profiles.profile,
            nullif(new.raw_user_meta_data ->> 'avatar_url', '')
        ),
        phone_number = case
            when new.raw_user_meta_data ? 'phone_number' or new.raw_user_meta_data ? 'phone'
            then coalesce(
                nullif(new.raw_user_meta_data ->> 'phone_number', ''),
                nullif(new.raw_user_meta_data ->> 'phone', '')
            )
            else public.user_profiles.phone_number
        end,
        address = case
            when new.raw_user_meta_data ? 'address'
            then nullif(new.raw_user_meta_data ->> 'address', '')
            else public.user_profiles.address
        end,
        updated_at = now();
    return new;
end;
$$;

commit;
