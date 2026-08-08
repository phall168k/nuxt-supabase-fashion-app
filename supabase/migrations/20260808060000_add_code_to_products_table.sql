begin;

alter table public.products
    add column code varchar(50);

-- Give existing products a stable, unique code before enforcing constraints.
update public.products
set code = 'PRD' || case
    when length(id::text) < 7 then lpad(id::text, 7, '0')
    else id::text
end
where code is null;

alter table public.products
    add constraint products_code_key unique (code);

commit;
