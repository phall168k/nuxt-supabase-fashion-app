begin;

do $$
begin
    -- Fresh databases already create products.id as UUID in the original
    -- migration. Only convert databases that still use the legacy bigint ID.
    if (select data_type = 'uuid'
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'products'
          and column_name = 'id') then
        return;
    end if;

    alter table public.products add column new_id uuid not null default gen_random_uuid();

    alter table public.stocks add column product_uuid uuid;
    alter table public.stock_in_items add column product_uuid uuid;
    alter table public.stock_adjustment_items add column product_uuid uuid;
    alter table public.product_images add column product_uuid uuid;
    alter table public.banners add column product_uuid uuid;
    alter table public.sale_items add column product_uuid uuid;
    alter table public.picked_products add column product_uuid uuid;

    update public.stocks child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.stock_in_items child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.stock_adjustment_items child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.product_images child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.banners child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.sale_items child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;
    update public.picked_products child set product_uuid = product.new_id
    from public.products product where product.id = child.product_id;

    if exists (select 1 from public.stocks where product_uuid is null)
       or exists (select 1 from public.stock_in_items where product_uuid is null)
       or exists (select 1 from public.stock_adjustment_items where product_uuid is null)
       or exists (select 1 from public.product_images where product_uuid is null)
       or exists (select 1 from public.banners where product_uuid is null)
       or exists (select 1 from public.sale_items where product_uuid is null)
       or exists (select 1 from public.picked_products where product_uuid is null) then
        raise exception 'A related row references a product that could not be converted';
    end if;

    alter table public.stocks drop constraint if exists stocks_product_id_fkey;
    alter table public.stock_in_items drop constraint if exists stock_in_items_product_id_fkey;
    alter table public.stock_adjustment_items drop constraint if exists stock_adjustment_items_product_id_fkey;
    alter table public.product_images drop constraint if exists product_images_product_id_fkey;
    alter table public.banners drop constraint if exists banners_product_id_fkey;
    alter table public.sale_items drop constraint if exists sale_items_product_id_fkey;
    alter table public.picked_products drop constraint if exists picked_products_product_id_fkey;

    alter table public.stocks drop constraint if exists stocks_product_id_key;
    alter table public.stock_in_items drop constraint if exists stock_in_items_product_unique;
    alter table public.stock_adjustment_items drop constraint if exists stock_adjustment_items_product_unique;
    alter table public.product_images drop constraint if exists product_images_path_unique;
    alter table public.sale_items drop constraint if exists sale_items_product_unique;
    alter table public.picked_products drop constraint if exists picked_products_picker_product_unique;

    drop index if exists public.stocks_product_id_idx;
    drop index if exists public.stock_in_items_product_id_idx;
    drop index if exists public.stock_adjustment_items_product_id_idx;
    drop index if exists public.product_images_product_id_idx;
    drop index if exists public.product_images_one_active_per_product_idx;
    drop index if exists public.banners_product_id_idx;
    drop index if exists public.sale_items_product_id_idx;
    drop index if exists public.picked_products_product_id_idx;

    alter table public.products drop constraint products_pkey;
    alter table public.products rename column id to legacy_id;
    alter table public.products rename column new_id to id;
    alter table public.products add constraint products_pkey primary key (id);

    alter table public.stocks rename column product_id to legacy_product_id;
    alter table public.stocks rename column product_uuid to product_id;
    alter table public.stock_in_items rename column product_id to legacy_product_id;
    alter table public.stock_in_items rename column product_uuid to product_id;
    alter table public.stock_adjustment_items rename column product_id to legacy_product_id;
    alter table public.stock_adjustment_items rename column product_uuid to product_id;
    alter table public.product_images rename column product_id to legacy_product_id;
    alter table public.product_images rename column product_uuid to product_id;
    alter table public.banners rename column product_id to legacy_product_id;
    alter table public.banners rename column product_uuid to product_id;
    alter table public.sale_items rename column product_id to legacy_product_id;
    alter table public.sale_items rename column product_uuid to product_id;
    alter table public.picked_products rename column product_id to legacy_product_id;
    alter table public.picked_products rename column product_uuid to product_id;

    alter table public.stocks alter column product_id set not null;
    alter table public.stock_in_items alter column product_id set not null;
    alter table public.stock_adjustment_items alter column product_id set not null;
    alter table public.product_images alter column product_id set not null;
    alter table public.banners alter column product_id set not null;
    alter table public.sale_items alter column product_id set not null;
    alter table public.picked_products alter column product_id set not null;

    alter table public.stocks add constraint stocks_product_id_fkey
        foreign key (product_id) references public.products(id) on delete cascade;
    alter table public.stock_in_items add constraint stock_in_items_product_id_fkey
        foreign key (product_id) references public.products(id) on delete restrict;
    alter table public.stock_adjustment_items add constraint stock_adjustment_items_product_id_fkey
        foreign key (product_id) references public.products(id) on delete restrict;
    alter table public.product_images add constraint product_images_product_id_fkey
        foreign key (product_id) references public.products(id) on delete cascade;
    alter table public.banners add constraint banners_product_id_fkey
        foreign key (product_id) references public.products(id) on delete restrict;
    alter table public.sale_items add constraint sale_items_product_id_fkey
        foreign key (product_id) references public.products(id) on delete restrict;
    alter table public.picked_products add constraint picked_products_product_id_fkey
        foreign key (product_id) references public.products(id) on delete cascade;

    alter table public.stocks add constraint stocks_product_id_key unique (product_id);
    alter table public.stock_in_items add constraint stock_in_items_product_unique
        unique (stock_in_id, product_id);
    alter table public.stock_adjustment_items add constraint stock_adjustment_items_product_unique
        unique (stock_adjustment_id, product_id);
    alter table public.product_images add constraint product_images_path_unique
        unique (product_id, image_path);
    alter table public.sale_items add constraint sale_items_product_unique
        unique (sale_id, product_id);
    alter table public.picked_products add constraint picked_products_picker_product_unique
        unique (picked_by_id, product_id);

    create index stocks_product_id_idx on public.stocks(product_id);
    create index stock_in_items_product_id_idx on public.stock_in_items(product_id);
    create index stock_adjustment_items_product_id_idx on public.stock_adjustment_items(product_id);
    create index product_images_product_id_idx on public.product_images(product_id);
    create unique index product_images_one_active_per_product_idx
        on public.product_images(product_id) where is_active;
    create index banners_product_id_idx on public.banners(product_id);
    create index sale_items_product_id_idx on public.sale_items(product_id);
    create index picked_products_product_id_idx on public.picked_products(product_id);

    alter table public.stocks drop column legacy_product_id;
    alter table public.stock_in_items drop column legacy_product_id;
    alter table public.stock_adjustment_items drop column legacy_product_id;
    alter table public.product_images drop column legacy_product_id;
    alter table public.banners drop column legacy_product_id;
    alter table public.sale_items drop column legacy_product_id;
    alter table public.picked_products drop column legacy_product_id;
    alter table public.products drop column legacy_id;
end;
$$;

-- Existing deployed RPCs contain jsonb_to_recordset declarations with a
-- bigint product_id. Recompile those bodies to parse UUID values instead.
do $$
declare
    function_record record;
    definition text;
begin
    for function_record in
        select procedure.oid
        from pg_proc procedure
        join pg_namespace namespace on namespace.oid = procedure.pronamespace
        where namespace.nspname = 'public'
          and procedure.proname in ('save_stock_in', 'save_stock_adjustment', 'save_sale')
    loop
        definition := pg_get_functiondef(function_record.oid);
        if position('product_id bigint' in definition) > 0 then
            execute replace(definition, 'product_id bigint', 'product_id uuid');
        end if;
    end loop;
end;
$$;

commit;
