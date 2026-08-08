begin;

alter table public.categories
    add column name_en varchar(255),
    add column name_kh varchar(255);

-- Preserve existing category names until translations can be updated.
update public.categories
set
    name_en = name,
    name_kh = name;

alter table public.categories
    alter column name_en set not null,
    alter column name_kh set not null,
    drop column name;

commit;
