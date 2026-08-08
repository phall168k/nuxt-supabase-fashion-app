begin;

drop policy if exists "Authenticated users can create banners"
    on public.banners;

create policy "Authenticated users can create banners"
    on public.banners
    for insert
    to authenticated
    with check (true);

commit;
