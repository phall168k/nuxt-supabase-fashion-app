begin;

drop policy if exists "Authenticated users can create their picked products"
    on public.picked_products;

create policy "Authenticated users can create picked products"
    on public.picked_products
    for insert
    to authenticated
    with check (true);

commit;
