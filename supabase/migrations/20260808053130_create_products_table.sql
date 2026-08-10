begin;

create table public.products (
    id uuid primary key default gen_random_uuid(),

    category_id bigint not null
        references public.categories(id)
        on delete restrict,

    name_en varchar(255) not null,
    name_kh varchar(255) not null,
    unit_price numeric(12, 2) not null
        check (unit_price >= 0),

    created_by_user_id uuid
        references auth.users(id)
        on delete set null,

    thumbnail_path text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index products_category_id_idx
    on public.products(category_id);

create index products_created_at_idx
    on public.products(created_at desc);

alter table public.products enable row level security;

create policy "Public can read products"
    on public.products
    for select
    to public
    using (true);

create policy "Authenticated users can create products"
    on public.products
    for insert
    to authenticated
    with check (created_by_user_id = auth.uid());

create policy "Authenticated users can update products"
    on public.products
    for update
    to authenticated
    using (true)
    with check (true);

create policy "Authenticated users can delete products"
    on public.products
    for delete
    to authenticated
    using (true);

insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'fashion-images',
    'fashion-images',
    true,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Public can view fashion images"
    on storage.objects
    for select
    to public
    using (bucket_id = 'fashion-images');

create policy "Authenticated users can upload fashion images"
    on storage.objects
    for insert
    to authenticated
    with check (bucket_id = 'fashion-images');

create policy "Authenticated users can update fashion images"
    on storage.objects
    for update
    to authenticated
    using (bucket_id = 'fashion-images')
    with check (bucket_id = 'fashion-images');

create policy "Authenticated users can delete fashion images"
    on storage.objects
    for delete
    to authenticated
    using (bucket_id = 'fashion-images');

commit;
