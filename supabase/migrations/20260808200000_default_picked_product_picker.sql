begin;

-- Keep picker attribution valid even when a client omits the column. The value
-- comes from the authenticated JWT evaluated by Postgres for this request.
alter table public.picked_products
    alter column picked_by_id set default auth.uid();

drop policy if exists "Authenticated users can create picked products"
    on public.picked_products;

create policy "Authenticated users can create their picked products"
    on public.picked_products
    for insert
    to authenticated
    with check (picked_by_id = auth.uid());

commit;
