<template>
  <main class="py-6 sm:py-8 lg:py-10">
    <h1 class="sr-only">{{ t('home.seo_heading') }}</h1>
    <section class="mx-auto w-[90%] overflow-hidden rounded-lg bg-slate-100 shadow-sm">
      <el-carousel
        v-if="banners.length"
        height="clamp(280px, 37vw, 620px)"
        :interval="5000"
        arrow="hover"
        trigger="click"
      >
        <el-carousel-item v-for="banner in banners" :key="banner.id">
          <component
            :is="banner.product ? NuxtLinkComponent : 'div'"
            :to="banner.product ? productPath(banner) : undefined"
            class="group relative block h-full w-full"
          >
            <el-image
              :src="banner.thumbnailUrl"
              :alt="banner.title"
              fit="cover"
              class="h-full w-full"
            >
              <template #placeholder>
                <div class="flex h-full w-full items-center justify-center bg-slate-100">
                  <Icon name="solar:gallery-wide-outline" size="42" class="text-slate-300" />
                </div>
              </template>
              <template #error>
                <div class="flex h-full w-full items-center justify-center bg-slate-100">
                  <Icon name="solar:gallery-remove-outline" size="42" class="text-slate-300" />
                </div>
              </template>
            </el-image>

            <div class="absolute inset-0 bg-gradient-to-r from-black/65 via-black/20 to-transparent" />
            <div class="absolute inset-y-0 left-0 flex w-full max-w-2xl items-center px-6 sm:px-10 lg:px-16">
              <div class="text-white">
                <h2 class="text-2xl font-bold tracking-tight sm:text-4xl lg:text-5xl">
                  {{ banner.title }}
                </h2>
                <p v-if="banner.description" class="mt-3 line-clamp-3 max-w-xl text-sm text-white/90 sm:text-base lg:text-lg">
                  {{ banner.description }}
                </p>
                <span class="mt-5 inline-flex items-center gap-2 rounded-md bg-white px-4 py-2 text-sm font-semibold text-slate-900 transition group-hover:bg-slate-100">
                  {{ t('home.shop_now') }}
                  <Icon name="lucide:arrow-right" size="17" />
                </span>
              </div>
            </div>
          </component>
        </el-carousel-item>
      </el-carousel>

      <div v-else class="flex h-[clamp(280px,37vw,620px)] flex-col items-center justify-center text-slate-400">
        <Icon name="solar:gallery-wide-outline" size="48" />
        <p class="mt-3 text-sm">{{ t('home.no_banners') }}</p>
      </div>
    </section>

    <section class="mx-auto mt-10 w-[90%] sm:mt-14">
      <div class="mb-5 flex items-end justify-between">
        <div>
          <h2 class="text-xl font-bold text-slate-900 sm:text-2xl">{{ t('home.products') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('home.products_description') }}</p>
        </div>
        <NuxtLink to="/search" class="text-sm font-semibold text-slate-700 hover:text-black">
          {{ t('home.view_all_products') }}
        </NuxtLink>
      </div>

      <div
        v-infinite-scroll="loadMoreProducts"
        :infinite-scroll-disabled="productsLoading || !hasMoreProducts"
        :infinite-scroll-distance="300"
        class="grid grid-cols-2 gap-x-3 gap-y-7 sm:grid-cols-3 sm:gap-x-5 lg:grid-cols-4 xl:grid-cols-5"
      >
        <article
          v-for="product in products"
          :key="product.id"
          class="group relative min-w-0"
        >
          <NuxtLink :to="productItemPath(product)" class="block">
          <div class="relative aspect-[3/4] overflow-hidden rounded-md bg-slate-100">
            <el-image
              v-if="product.thumbnailUrl"
              :src="product.thumbnailUrl"
              :alt="productTitle(product)"
              fit="cover"
              class="h-full w-full transition duration-300 group-hover:scale-105"
              lazy
            >
              <template #placeholder>
                <div class="flex h-full items-center justify-center text-slate-300">
                  <Icon name="solar:gallery-wide-outline" size="36" />
                </div>
              </template>
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
          </NuxtLink>

          <ClientAddToCartButton :product-id="product.id" class="absolute right-2 top-2 z-10" />

          <NuxtLink :to="productItemPath(product)" class="block">
          <h3 class="mt-3 truncate text-sm font-medium text-slate-800 transition group-hover:text-black sm:text-base">
            {{ productTitle(product) }}
          </h3>
          <div class="mt-1 flex flex-wrap items-baseline gap-2">
            <span
              class="text-sm text-slate-500"
              :class="{ 'line-through': product.discount > 0 }"
            >
              {{ formatPrice(product.unitPrice) }}
            </span>
            <span v-if="product.discount > 0" class="font-semibold text-rose-600">
              {{ formatPrice(product.unitPrice - product.discount) }}
            </span>
          </div>
          </NuxtLink>
        </article>
      </div>

      <div v-if="productsLoading" class="flex justify-center py-8">
        <Icon name="svg-spinners:ring-resize" size="30" class="text-slate-500" />
      </div>
      <p v-else-if="!products.length" class="py-12 text-center text-sm text-slate-500">
        {{ t('home.no_products') }}
      </p>
      <p v-else-if="!hasMoreProducts" class="py-8 text-center text-xs text-slate-400">
        {{ t('home.all_products_loaded') }}
      </p>
    </section>
  </main>
</template>

<script setup lang="ts">
interface BannerRow {
  id: number
  title: string
  description: string | null
  thumbnail_path: string
  product: { id: string; code: string } | null
}

interface Banner {
  id: number
  title: string
  description: string | null
  thumbnailUrl: string
  product: { id: string; code: string } | null
}

interface ProductImageRow {
  image_path: string
  is_active: boolean
  sort_order: number
}

interface ProductRow {
  id: string
  code: string
  name_en: string
  name_kh: string
  unit_price: number
  discount: number
  images: ProductImageRow[]
  stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null
}

interface Product {
  id: string
  code: string
  nameEn: string
  nameKh: string
  unitPrice: number
  discount: number
  thumbnailUrl: string | null
}

definePageMeta({ 
  layout: 'client', 
  title: 'Fashion Shop' 
})

const { t, locale } = useI18n()
const supabase = useSupabaseClient()
const NuxtLinkComponent = resolveComponent('NuxtLink')
const requestUrl = useRequestURL()
const bucketName = 'fashion-images'
const productPageSize = 15
const products = ref<Product[]>([])
const productsLoading = ref(false)
const hasMoreProducts = ref(true)
const fetchedProductCount = ref(0)

const { data: bannerRows } = await useAsyncData('client-banners', async () => {
  const { data, error } = await supabase
    .from('banners')
    .select('id, title, description, thumbnail_path, product:products(id, code)')
    .eq('is_active', true)
    .order('created_at', { ascending: false })

  if (error) throw error
  return (data ?? []) as unknown as BannerRow[]
}, { default: () => [] })

const banners = computed<Banner[]>(() => bannerRows.value.map(row => ({
  id: row.id,
  title: row.title,
  description: row.description,
  thumbnailUrl: supabase.storage.from(bucketName).getPublicUrl(row.thumbnail_path).data.publicUrl,
  product: row.product,
})))

const productPath = (banner: Banner) => ({
  path: `/detail/${banner.product!.id}`,
})

const productTitle = (product: Product) => locale.value === 'km' ? product.nameKh : product.nameEn
const formatPrice = (value: number) => new Intl.NumberFormat('en-US', {
  style: 'currency', currency: 'USD', minimumFractionDigits: 2,
}).format(Math.max(0, value))
const productItemPath = (product: Product) => `/detail/${product.id}`

const loadMoreProducts = async () => {
  if (productsLoading.value || !hasMoreProducts.value) return

  try {
    productsLoading.value = true
    let availableRows: ProductRow[] = []

    // Continue through empty out-of-stock batches so infinite scroll does not
    // stop before reaching later products that are available.
    while (!availableRows.length && hasMoreProducts.value) {
      const from = fetchedProductCount.value
      const { data, error } = await supabase
        .from('products')
        .select('id, code, name_en, name_kh, unit_price, discount, stock:stocks!inner(stock_in, stock_out, stock_adjustment), images:product_images(image_path, is_active, sort_order)')
        .order('id', { ascending: true })
        .range(from, from + productPageSize - 1)

      if (error) throw error
      const rows = (data ?? []) as unknown as ProductRow[]
      fetchedProductCount.value += rows.length
      hasMoreProducts.value = rows.length === productPageSize
      availableRows = rows.filter(row => row.stock
        && Number(row.stock.stock_in) + Number(row.stock.stock_adjustment) - Number(row.stock.stock_out) > 0)
    }

    products.value.push(...availableRows.map(row => {
      const thumbnail = [...(row.images ?? [])]
        .filter(image => image.is_active)
        .sort((a, b) => a.sort_order - b.sort_order)[0]
      return {
        id: row.id,
        code: row.code,
        nameEn: row.name_en,
        nameKh: row.name_kh,
        unitPrice: Number(row.unit_price),
        discount: Number(row.discount ?? 0),
        thumbnailUrl: thumbnail
          ? supabase.storage.from(bucketName).getPublicUrl(thumbnail.image_path).data.publicUrl
          : null,
      }
    }))
  } catch {
    hasMoreProducts.value = false
  } finally {
    productsLoading.value = false
  }
}

await loadMoreProducts()

const canonicalUrl = computed(() => `${requestUrl.origin}${requestUrl.pathname}`)
const seoTitle = computed(() => t('home.seo_title'))
const seoDescription = computed(() => t('home.seo_description'))
const socialImage = computed(() => banners.value[0]?.thumbnailUrl)

useSeoMeta(() => ({
  title: seoTitle.value,
  description: seoDescription.value,
  ogTitle: seoTitle.value,
  ogDescription: seoDescription.value,
  ogSiteName: t('app.title'),
  ogType: 'website',
  ogUrl: canonicalUrl.value,
  ogImage: socialImage.value,
  ogLocale: locale.value === 'km' ? 'km_KH' : 'en_US',
  twitterCard: 'summary_large_image',
  twitterTitle: seoTitle.value,
  twitterDescription: seoDescription.value,
  twitterImage: socialImage.value,
  robots: 'index, follow',
}))

useHead(() => ({
  htmlAttrs: { lang: locale.value === 'km' ? 'km' : 'en' },
  link: [{ rel: 'canonical', href: canonicalUrl.value }],
  meta: [{ property: 'fb:app_id', content: '390063447027213' }],
  script: [{
    type: 'application/ld+json',
    innerHTML: JSON.stringify({
      '@context': 'https://schema.org',
      '@type': 'OnlineStore',
      name: t('app.title'),
      url: canonicalUrl.value,
      description: seoDescription.value,
      hasOfferCatalog: {
        '@type': 'OfferCatalog',
        name: t('home.products'),
        itemListElement: products.value.map((product, index) => ({
          '@type': 'ListItem',
          position: index + 1,
          url: `${requestUrl.origin}${productItemPath(product)}`,
          item: {
            '@type': 'Product',
            name: productTitle(product),
            image: product.thumbnailUrl || undefined,
            sku: product.code,
            offers: {
              '@type': 'Offer',
              priceCurrency: 'USD',
              price: Math.max(0, product.unitPrice - product.discount).toFixed(2),
              availability: 'https://schema.org/InStock',
            },
          },
        })),
      },
    }),
  }],
}))
</script>

<style scoped>
:deep(.el-carousel__container) {
  height: clamp(280px, 37vw, 620px) !important;
}

:deep(.el-carousel__indicators--horizontal) {
  bottom: 12px;
}
</style>
