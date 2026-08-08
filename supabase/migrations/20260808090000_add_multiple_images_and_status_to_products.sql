begin;

alter table public.products
    add column thumbnail_paths text[] not null default '{}',
    add column is_active boolean not null default true;

update public.products
set thumbnail_paths = array[thumbnail_path]
where thumbnail_path is not null
  and btrim(thumbnail_path) <> '';

alter table public.products
    drop column thumbnail_path;

commit;
