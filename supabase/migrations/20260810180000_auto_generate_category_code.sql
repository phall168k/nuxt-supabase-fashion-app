begin;

create sequence if not exists public.category_code_seq start with 1;

do $$
declare
    highest_code bigint;
begin
    select coalesce(max(substring(code from '^CAT([0-9]+)$')::bigint), 0)
    into highest_code
    from public.categories
    where code ~ '^CAT[0-9]+$';

    perform setval(
        'public.category_code_seq',
        greatest(highest_code, 1),
        highest_code > 0
    );
end;
$$;

alter table public.categories
    alter column code set default (
        'CAT' || lpad(nextval('public.category_code_seq')::text, 5, '0')
    );

alter sequence public.category_code_seq owned by public.categories.code;

commit;
