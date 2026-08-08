begin;

alter table public.products
    add column discount numeric(12, 2) not null default 0,
    add constraint products_discount_range_check
        check (discount >= 0 and discount <= unit_price);

commit;
