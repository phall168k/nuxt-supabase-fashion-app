begin;

-- A new installation has no way to manage profiles until one existing user
-- owns the administrator role. Bootstrap only when no administrator exists.
do $$
declare
    first_user_id uuid;
begin
    if not exists (
        select 1 from public.user_profiles where role = 'admin'
    ) then
        select id into first_user_id
        from auth.users
        order by created_at asc, id asc
        limit 1;

        if first_user_id is not null then
            update public.user_profiles
            set role = 'admin', updated_at = now()
            where user_id = first_user_id;

            update auth.users
            set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
                    || jsonb_build_object('role', 'admin'),
                updated_at = now()
            where id = first_user_id;
        end if;
    end if;
end;
$$;

create or replace function public.is_profile_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select
        lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')) = 'admin'
        or exists (
            select 1 from public.user_profiles
            where user_id = auth.uid() and role = 'admin'
        );
$$;

revoke all on function public.is_profile_admin() from public;
grant execute on function public.is_profile_admin() to authenticated;

commit;
