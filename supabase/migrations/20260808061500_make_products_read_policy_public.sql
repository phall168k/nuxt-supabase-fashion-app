begin;

drop policy if exists "Authenticated users can read products"
    on public.products;

drop policy if exists "Public can read products"
    on public.products;

create policy "Public can read products"
    on public.products
    for select
    to public
    using (true);

commit;
