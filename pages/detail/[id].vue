<template>
  <main class="mx-auto w-[90%] py-6 sm:py-10">
    <div v-if="productStatus === 'idle' || productPending" class="flex min-h-[60vh] flex-col items-center justify-center gap-3">
      <Icon name="svg-spinners:ring-resize" size="36" class="text-slate-500" />
      <p class="text-sm text-slate-500">{{ t('detail.loading') }}</p>
    </div>

    <template v-else>
    <nav class="mb-6 flex items-center gap-2 text-sm text-slate-500" aria-label="Breadcrumb">
      <NuxtLink to="/" class="hover:text-slate-900">{{ t('detail.home') }}</NuxtLink>
      <Icon name="lucide:chevron-right" size="15" />
      <span class="truncate text-slate-800">{{ productName }}</span>
    </nav>

    <section class="grid grid-cols-1 gap-8 lg:grid-cols-2 lg:gap-14">
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-[80px_minmax(0,1fr)]">
        <div v-if="product.images.length > 1" class="order-2 flex gap-2 overflow-x-auto sm:order-1 sm:flex-col">
          <button
            v-for="(image, index) in product.images"
            :key="image.id"
            type="button"
            class="h-20 w-16 shrink-0 overflow-hidden rounded-md border-2 bg-slate-100 transition sm:w-20"
            :class="selectedImageIndex === index ? 'border-slate-900' : 'border-transparent hover:border-slate-300'"
            :aria-label="t('detail.select_image', { number: index + 1 })"
            @click="selectedImageIndex = index"
          >
            <el-image :src="image.url" :alt="productName" fit="cover" class="h-full w-full" />
          </button>
        </div>

        <div class="order-1 aspect-[3/4] overflow-hidden rounded-lg bg-slate-100 sm:order-2">
          <el-image
            v-if="selectedImage"
            :src="selectedImage.url"
            :alt="productName"
            :preview-src-list="product.images.map(image => image.url)"
            :initial-index="selectedImageIndex"
            fit="cover"
            class="h-full w-full"
            preview-teleported
          >
            <template #placeholder>
              <div class="flex h-full items-center justify-center text-slate-300">
                <Icon name="solar:gallery-wide-outline" size="54" />
              </div>
            </template>
            <template #error>
              <div class="flex h-full items-center justify-center text-slate-300">
                <Icon name="solar:gallery-remove-outline" size="54" />
              </div>
            </template>
          </el-image>
          <div v-else class="flex h-full items-center justify-center text-slate-300">
            <Icon name="solar:gallery-wide-outline" size="54" />
          </div>
        </div>
      </div>

      <div class="lg:pt-6">
        <p class="text-sm font-medium uppercase tracking-wider text-slate-500">{{ product.categoryName }}</p>
        <h1 class="mt-2 text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">{{ productName }}</h1>
        <p class="mt-2 text-sm text-slate-500">{{ t('detail.code') }}: {{ product.code }}</p>

        <div class="mt-6 flex flex-wrap items-baseline gap-3">
          <span
            class="text-xl text-slate-500"
            :class="{ 'line-through': product.discount > 0 }"
          >
            {{ formatPrice(product.unitPrice) }}
          </span>
          <span v-if="product.discount > 0" class="text-3xl font-bold text-rose-600">
            {{ formatPrice(product.salePrice) }}
          </span>
        </div>

        <div v-if="product.discount > 0" class="mt-3 inline-flex rounded-full bg-rose-50 px-3 py-1 text-sm font-medium text-rose-700">
          {{ t('detail.you_save', { amount: formatPrice(product.discount) }) }}
        </div>

        <div class="my-8 border-t border-slate-200" />

        <div class="flex items-center justify-between rounded-lg bg-slate-50 p-4">
          <div>
            <p class="font-medium text-slate-900">{{ t('detail.availability') }}</p>
            <p class="mt-1 text-sm text-slate-500">{{ t('detail.stock_on_hand') }}</p>
          </div>
          <el-tag :type="product.stockOnHand > 0 ? 'success' : 'danger'" size="large">
            {{ product.stockOnHand > 0 ? t('detail.in_stock', { count: product.stockOnHand }) : t('detail.out_of_stock') }}
          </el-tag>
        </div>

        <ClientAddToCartButton
          v-if="product.id"
          :product-id="product.id"
          variant="button"
          :disabled="product.stockOnHand <= 0"
          class="mt-5 w-full"
        />

        <dl class="mt-6 divide-y divide-slate-200 text-sm">
          <div class="flex justify-between gap-4 py-4">
            <dt class="text-slate-500">{{ t('detail.category') }}</dt>
            <dd class="font-medium text-slate-900">{{ product.categoryName }}</dd>
          </div>
          <div class="flex justify-between gap-4 py-4">
            <dt class="text-slate-500">{{ t('detail.product_code') }}</dt>
            <dd class="font-medium text-slate-900">{{ product.code }}</dd>
          </div>
        </dl>
      </div>
    </section>

    <section v-if="relatedProducts.length" class="mt-14 border-t border-slate-200 pt-10 sm:mt-20 sm:pt-14">
      <h2 class="text-xl font-bold text-slate-900 sm:text-2xl">{{ t('detail.related_products') }}</h2>
      <div class="mt-6 grid grid-cols-2 gap-x-3 gap-y-7 sm:grid-cols-3 sm:gap-x-5 lg:grid-cols-5">
        <NuxtLink
          v-for="item in relatedProducts"
          :key="item.id"
          :to="`/detail/${item.id}`"
          class="group min-w-0"
        >
          <div class="relative aspect-[3/4] overflow-hidden rounded-md bg-slate-100">
            <ClientAddToCartButton :product-id="item.id" class="absolute right-2 top-2 z-10" />
            <el-image
              v-if="item.thumbnailUrl"
              :src="item.thumbnailUrl"
              :alt="relatedProductName(item)"
              fit="cover"
              class="h-full w-full transition duration-300 group-hover:scale-105"
              lazy
            >
              <template #error>
                <div class="flex h-full items-center justify-center text-slate-300">
                  <Icon name="solar:gallery-remove-outline" size="36" />
                </div>
              </template>
            </el-image>
            <div v-else class="flex h-full items-center justify-center text-slate-300">
              <Icon name="solar:gallery-wide-outline" size="36" />
            </div>
          </div>
          <h3 class="mt-3 truncate text-sm font-medium text-slate-800 group-hover:text-black sm:text-base">
            {{ relatedProductName(item) }}
          </h3>
          <div class="mt-1 flex flex-wrap items-baseline gap-2">
            <span class="text-sm text-slate-500" :class="{ 'line-through': item.discount > 0 }">
              {{ formatPrice(item.unitPrice) }}
            </span>
            <span v-if="item.discount > 0" class="font-semibold text-rose-600">
              {{ formatPrice(item.unitPrice - item.discount) }}
            </span>
          </div>
        </NuxtLink>
      </div>
    </section>

    <section v-if="topSellingProducts.length" class="mt-14 border-t border-slate-200 pt-10 sm:mt-20 sm:pt-14">
      <div>
        <h2 class="text-xl font-bold text-slate-900 sm:text-2xl">{{ t('detail.top_selling_products') }}</h2>
        <p class="mt-1 text-sm text-slate-500">{{ t('detail.top_selling_description') }}</p>
      </div>
      <div class="mt-6 grid grid-cols-2 gap-x-3 gap-y-7 sm:grid-cols-3 sm:gap-x-5 lg:grid-cols-5">
        <NuxtLink
          v-for="(item, index) in topSellingProducts"
          :key="item.id"
          :to="`/detail/${item.id}`"
          class="group min-w-0"
        >
          <div class="relative aspect-[3/4] overflow-hidden rounded-md bg-slate-100">
            <span class="absolute left-2 top-2 z-10 rounded-full bg-slate-900 px-2.5 py-1 text-xs font-semibold text-white">
              #{{ index + 1 }}
            </span>
            <el-image
              v-if="item.thumbnailUrl"
              :src="item.thumbnailUrl"
              :alt="relatedProductName(item)"
              fit="cover"
              class="h-full w-full transition duration-300 group-hover:scale-105"
              lazy
            >
              <template #error>
                <div class="flex h-full items-center justify-center text-slate-300">
                  <Icon name="solar:gallery-remove-outline" size="36" />
                </div>
              </template>
            </el-image>
            <div v-else class="flex h-full items-center justify-center text-slate-300">
              <Icon name="solar:gallery-wide-outline" size="36" />
            </div>
          </div>
          <h3 class="mt-3 truncate text-sm font-medium text-slate-800 group-hover:text-black sm:text-base">
            {{ relatedProductName(item) }}
          </h3>
          <div class="mt-1 flex flex-wrap items-baseline gap-2">
            <span class="text-sm text-slate-500" :class="{ 'line-through': item.discount > 0 }">
              {{ formatPrice(item.unitPrice) }}
            </span>
            <span v-if="item.discount > 0" class="font-semibold text-rose-600">
              {{ formatPrice(item.unitPrice - item.discount) }}
            </span>
          </div>
          <p class="mt-1 text-xs text-slate-400">{{ t('detail.units_sold', { count: item.totalSold }) }}</p>
        </NuxtLink>
      </div>
    </section>
    </template>
  </main>
</template>

<script setup lang="ts">
interface ProductImageRow { id: number; image_path: string; is_active: boolean; sort_order: number }
interface ProductRow {
  id: string
  code: string
  name_en: string
  name_kh: string
  unit_price: number
  discount: number
  category: { id: number; name_en: string; name_kh: string } | null
  stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null
  images: ProductImageRow[]
}

interface RelatedProductRow {
  id: string
  name_en: string
  name_kh: string
  unit_price: number
  discount: number
  stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null
  images: ProductImageRow[]
}

interface RelatedProduct {
  id: string
  nameEn: string
  nameKh: string
  unitPrice: number
  discount: number
  thumbnailUrl: string | null
  totalSold?: number
}

definePageMeta({ layout: 'client', key: route => route.fullPath })

const route = useRoute()
const requestUrl = useRequestURL()
const { t, locale } = useI18n()
const supabase = useSupabaseClient()
const bucketName = 'fashion-images'
const productId = String(route.params.id)

if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(productId)) {
  throw createError({ statusCode: 404, statusMessage: 'Product not found' })
}

const {
  data: row,
  pending: productPending,
  status: productStatus,
  error: productError,
} = await useLazyAsyncData(`product-detail-${productId}`, async () => {
  const { data, error } = await supabase
    .from('products')
    .select('id, code, name_en, name_kh, unit_price, discount, category:categories(id, name_en, name_kh), stock:stocks(stock_in, stock_out, stock_adjustment), images:product_images(id, image_path, is_active, sort_order)')
    .eq('id', productId)
    .maybeSingle()

  if (error) throw error
  return data as unknown as ProductRow | null
})

const { data: relatedRows } = await useAsyncData(`related-products-${productId}`, async () => {
  if (!row.value?.category?.id) return []
  const { data, error } = await supabase
    .from('products')
    .select('id, name_en, name_kh, unit_price, discount, stock:stocks!inner(stock_in, stock_out, stock_adjustment), images:product_images(id, image_path, is_active, sort_order)')
    .eq('category_id', row.value.category.id)
    .neq('id', productId)
    .order('id', { ascending: true })
    .limit(50)

  if (error) throw error
  return (data ?? []) as unknown as RelatedProductRow[]
}, { default: () => [], lazy: true, watch: [row] })

const { data: topSellingRows } = await useAsyncData(`top-selling-products-${productId}`, async () => {
  const { data: ranking, error: rankingError } = await supabase.rpc('get_top_selling_products', { p_limit: 10 })
  if (rankingError) throw rankingError
  if (!ranking?.length) return []

  const ids = ranking.map(item => String(item.product_id))
  const { data, error } = await supabase
    .from('products')
    .select('id, name_en, name_kh, unit_price, discount, stock:stocks(stock_in, stock_out, stock_adjustment), images:product_images(id, image_path, is_active, sort_order)')
    .in('id', ids)

  if (error) throw error
  const productsById = new Map(((data ?? []) as unknown as RelatedProductRow[]).map(item => [item.id, item]))
  return ranking.flatMap(rank => {
    const item = productsById.get(String(rank.product_id))
    return item ? [{ ...item, total_sold: Number(rank.total_sold) }] : []
  })
}, { default: () => [], lazy: true })

const product = computed(() => {
  const value = row.value
  if (!value) return {
    id: '',
    code: '',
    nameEn: '',
    nameKh: '',
    categoryName: '',
    unitPrice: 0,
    discount: 0,
    salePrice: 0,
    stockOnHand: 0,
    images: [] as Array<{ id: number; url: string }>,
  }
  const images = [...(value.images ?? [])]
    .sort((a, b) => Number(b.is_active) - Number(a.is_active) || a.sort_order - b.sort_order)
    .map(image => ({
      id: image.id,
      url: supabase.storage.from(bucketName).getPublicUrl(image.image_path).data.publicUrl,
    }))
  const unitPrice = Number(value.unit_price)
  const discount = Number(value.discount ?? 0)
  return {
    id: value.id,
    code: value.code,
    nameEn: value.name_en,
    nameKh: value.name_kh,
    categoryName: locale.value === 'km' ? value.category?.name_kh : value.category?.name_en,
    unitPrice,
    discount,
    salePrice: Math.max(0, unitPrice - discount),
    stockOnHand: Math.max(0, Number(value.stock?.stock_in ?? 0) + Number(value.stock?.stock_adjustment ?? 0) - Number(value.stock?.stock_out ?? 0)),
    images,
  }
})

const productName = computed(() => locale.value === 'km' ? product.value.nameKh : product.value.nameEn)
const relatedProducts = computed<RelatedProduct[]>(() => relatedRows.value
  .filter(item => item.stock && Number(item.stock.stock_in) + Number(item.stock.stock_adjustment) - Number(item.stock.stock_out) > 0)
  .slice(0, 5)
  .map(item => {
    const thumbnail = [...(item.images ?? [])]
      .filter(image => image.is_active)
      .sort((a, b) => a.sort_order - b.sort_order)[0]
    return {
      id: item.id,
      nameEn: item.name_en,
      nameKh: item.name_kh,
      unitPrice: Number(item.unit_price),
      discount: Number(item.discount ?? 0),
      thumbnailUrl: thumbnail
        ? supabase.storage.from(bucketName).getPublicUrl(thumbnail.image_path).data.publicUrl
        : null,
    }
  }))
const topSellingProducts = computed<RelatedProduct[]>(() => topSellingRows.value.map(item => {
  const thumbnail = [...(item.images ?? [])]
    .filter(image => image.is_active)
    .sort((a, b) => a.sort_order - b.sort_order)[0]
  return {
    id: item.id,
    nameEn: item.name_en,
    nameKh: item.name_kh,
    unitPrice: Number(item.unit_price),
    discount: Number(item.discount ?? 0),
    thumbnailUrl: thumbnail
      ? supabase.storage.from(bucketName).getPublicUrl(thumbnail.image_path).data.publicUrl
      : null,
    totalSold: Number(item.total_sold),
  }
}))
const relatedProductName = (item: RelatedProduct) => locale.value === 'km' ? item.nameKh : item.nameEn
const selectedImageIndex = ref(0)
const selectedImage = computed(() => product.value.images[selectedImageIndex.value] ?? null)
const formatPrice = (value: number) => new Intl.NumberFormat('en-US', {
  style: 'currency', currency: 'USD', minimumFractionDigits: 2,
}).format(value)
const seoTitle = computed(() => productName.value
  ? `${productName.value} | ${t('app.title')}`
  : t('app.title'))
const seoThumbnail = computed(() => product.value.images[0]?.url || '')
const seoPrice = computed(() => product.value.salePrice.toFixed(2))
const seoDescription = computed(() => productName.value
  ? `${productName.value} — ${formatPrice(product.value.salePrice)}`
  : t('app.title'))
const canonicalUrl = computed(() => new URL(route.fullPath, requestUrl.origin).toString())

useSeoMeta({
  title: () => seoTitle.value,
  description: () => seoDescription.value,
  ogTitle: () => seoTitle.value,
  ogDescription: () => seoDescription.value,
  ogType: 'website',
  ogUrl: () => canonicalUrl.value,
  ogImage: () => seoThumbnail.value || undefined,
  ogImageAlt: () => productName.value || t('app.title'),
  twitterCard: 'summary_large_image',
  twitterTitle: () => seoTitle.value,
  twitterDescription: () => seoDescription.value,
  twitterImage: () => seoThumbnail.value || undefined,
})

useHead(() => ({
  link: [{ rel: 'canonical', href: canonicalUrl.value }],
  meta: [
    { property: 'product:price:amount', content: seoPrice.value },
    { property: 'product:price:currency', content: 'USD' },
  ],
  script: row.value ? [{
    type: 'application/ld+json',
    textContent: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'Product',
      name: productName.value,
      image: seoThumbnail.value ? [seoThumbnail.value] : undefined,
      sku: product.value.code,
      offers: {
        '@type': 'Offer',
        url: canonicalUrl.value,
        priceCurrency: 'USD',
        price: seoPrice.value,
        availability: product.value.stockOnHand > 0
          ? 'https://schema.org/InStock'
          : 'https://schema.org/OutOfStock',
      },
    }),
  }] : [],
}))

watch(productStatus, status => {
  if (status === 'success' && !row.value) {
    showError({ statusCode: 404, statusMessage: 'Product not found' })
  }
  if (status === 'error') {
    showError({
      statusCode: 500,
      statusMessage: productError.value?.message || 'Unable to load product',
    })
  }
}, { immediate: true })

</script>
