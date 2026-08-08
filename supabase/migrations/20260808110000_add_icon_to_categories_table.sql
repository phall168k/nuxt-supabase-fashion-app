begin;

alter table public.categories
    add column icon varchar(100);

commit;
