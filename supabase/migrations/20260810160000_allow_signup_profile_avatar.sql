begin;

create policy "Signups can upload profile images"
    on storage.objects
    for insert
    to anon
    with check (
        bucket_id = 'fashion-images'
        and (storage.foldername(name))[1] = 'user-profiles'
        and name ~ '^user-profiles/[0-9a-f-]{36}-[0-9a-f-]{36}\.(jpg|png|webp)$'
    );

create function public.complete_signup_profile_avatar(
    p_user_id uuid,
    p_token uuid,
    p_profile text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    expected_prefix text := 'user-profiles/' || p_user_id::text || '-' || p_token::text || '.';
begin
    if p_profile not like (expected_prefix || '%') then
        raise exception 'Invalid profile image path';
    end if;

    if not exists (
        select 1
        from auth.users
        where id = p_user_id
          and raw_user_meta_data ->> 'signup_profile_token' = p_token::text
    ) then
        raise exception 'Invalid or expired signup profile token';
    end if;

    update public.user_profiles
    set profile = p_profile,
        updated_at = now()
    where user_id = p_user_id;

    if not found then
        raise exception 'User profile was not found';
    end if;

    update auth.users
    set raw_user_meta_data = (coalesce(raw_user_meta_data, '{}'::jsonb) - 'signup_profile_token')
        || jsonb_build_object('profile', p_profile),
        updated_at = now()
    where id = p_user_id;
end;
$$;

revoke all on function public.complete_signup_profile_avatar(uuid, uuid, text) from public;
grant execute on function public.complete_signup_profile_avatar(uuid, uuid, text) to anon, authenticated;

commit;
