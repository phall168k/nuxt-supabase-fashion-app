begin;

alter table public.products
    add column code varchar(50);

-- Give existing products a stable, unique code before enforcing constraints.
update public.products
set code = 'PRD' || upper(substr(replace(id::text, '-', ''), 1, 10))
where code is null;

alter table public.products
    add constraint products_code_key unique (code);

commit;
