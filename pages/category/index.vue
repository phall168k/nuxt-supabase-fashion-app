<template>
  <main class="mx-auto w-[90%] py-8 sm:py-12">
    <header class="mb-7">
      <h1 class="text-2xl font-bold text-slate-900 sm:text-3xl">
        {{ category ? categoryName(category) : t('category.products_title') }}
      </h1>
      <p class="mt-2 text-sm text-slate-500">
        {{ category ? t('category.products_description', { category: categoryName(category) }) : t('category.select_category') }}
      </p>
    </header>

    <div
      v-infinite-scroll="loadMoreProducts"
      :infinite-scroll-disabled="loading || !hasMore || !category"
      :infinite-scroll-distance="300"
      class="grid grid-cols-2 gap-x-3 gap-y-7 sm:grid-cols-3 sm:gap-x-5 lg:grid-cols-4 xl:grid-cols-5"
    >
      <article
        v-for="product in products"
        :key="product.id"
        class="group relative min-w-0"
      >
        <NuxtLink :to="`/detail/${product.id}`" class="block">
        <div class="aspect-[3/4] overflow-hidden rounded-md bg-slate-100">
          <el-image
            v-if="product.thumbnailUrl"
            :src="product.thumbnailUrl"
            :alt="productName(product)"
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

        <NuxtLink :to="`/detail/${product.id}`" class="block">
        <h2 class="mt-3 truncate text-sm font-medium text-slate-800 group-hover:text-black sm:text-base">
          {{ productName(product) }}
        </h2>
        <div class="mt-1 flex flex-wrap items-baseline gap-2">
          <span class="text-sm text-slate-500" :class="{ 'line-through': product.discount > 0 }">
            {{ formatPrice(product.unitPrice) }}
          </span>
          <span v-if="product.discount > 0" class="font-semibold text-rose-600">
            {{ formatPrice(product.unitPrice - product.discount) }}
          </span>
        </div>
        </NuxtLink>
      </article>
    </div>

    <div v-if="loading" class="flex justify-center py-10">
      <Icon name="svg-spinners:ring-resize" size="30" class="text-slate-500" />
    </div>
    <div v-else-if="loadError" class="py-12 text-center">
      <p class="text-sm text-rose-600">{{ t('category.products_load_failed') }}</p>
      <el-button class="mt-4" @click="retry">{{ t('search.try_again') }}</el-button>
    </div>
    <p v-else-if="categoryCode && !category" class="py-12 text-center text-sm text-slate-500">
      {{ t('category.not_found') }}
    </p>
    <p v-else-if="!categoryCode" class="py-12 text-center text-sm text-slate-500">
      {{ t('category.select_category') }}
    </p>
    <p v-else-if="!products.length" class="py-12 text-center text-sm text-slate-500">
      {{ t('category.no_products') }}
    </p>
    <p v-else-if="!hasMore" class="py-8 text-center text-xs text-slate-400">
      {{ t('home.all_products_loaded') }}
    </p>
  </main>
</template>

<script setup lang="ts">
interface CategoryRow { id: number; code: string; name_en: string; name_kh: string }
interface ProductImageRow { image_path: string; is_active: boolean; sort_order: number }
interface ProductRow {
  id: string
  code: string
  name_en: string
  name_kh: string
  unit_price: number
  discount: number
  stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null
  images: ProductImageRow[]
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

definePageMeta({ layout: 'client' })

const route = useRoute()
const { t, locale } = useI18n()
const supabase = useSupabaseClient()
const bucketName = 'fashion-images'
const pageSize = 10
const category = ref<CategoryRow | null>(null)
const products = ref<Product[]>([])
const loading = ref(false)
const hasMore = ref(true)
const loadError = ref(false)
const fetchedCount = ref(0)
const requestVersion = ref(0)
const categoryCode = computed(() => typeof route.query['category-code'] === 'string'
  ? route.query['category-code'].trim()
  : '')

const categoryName = (item: CategoryRow) => locale.value === 'km' ? item.name_kh : item.name_en
const productName = (product: Product) => locale.value === 'km' ? product.nameKh : product.nameEn
const formatPrice = (value: number) => new Intl.NumberFormat('en-US', {
  style: 'currency', currency: 'USD', minimumFractionDigits: 2,
}).format(Math.max(0, value))

const loadMoreProducts = async () => {
  if (loading.value || !hasMore.value || !category.value) return
  const version = requestVersion.value

  try {
    loading.value = true
    loadError.value = false
    let availableRows: ProductRow[] = []

    while (!availableRows.length && hasMore.value && version === requestVersion.value) {
      const from = fetchedCount.value
      const { data, error } = await supabase
        .from('products')
        .select('id, code, name_en, name_kh, unit_price, discount, stock:stocks!inner(stock_in, stock_out, stock_adjustment), images:product_images(image_path, is_active, sort_order)')
        .eq('category_id', category.value.id)
        .order('id', { ascending: true })
        .range(from, from + pageSize - 1)

      if (error) throw error
      if (version !== requestVersion.value) return

      const rows = (data ?? []) as unknown as ProductRow[]
      fetchedCount.value += rows.length
      hasMore.value = rows.length === pageSize
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
    if (version === requestVersion.value) loadError.value = true
  } finally {
    if (version === requestVersion.value) loading.value = false
  }
}

const resetCategory = async () => {
  requestVersion.value += 1
  const version = requestVersion.value
  category.value = null
  products.value = []
  fetchedCount.value = 0
  hasMore.value = true
  loadError.value = false
  loading.value = false

  if (!categoryCode.value) return

  loading.value = true
  try {
    const { data, error } = await supabase
      .from('categories')
      .select('id, code, name_en, name_kh')
      .eq('code', categoryCode.value)
      .eq('is_active', true)
      .maybeSingle()

    if (error) throw error
    if (version !== requestVersion.value) return
    category.value = data as CategoryRow | null
  } catch {
    if (version === requestVersion.value) loadError.value = true
  } finally {
    if (version === requestVersion.value) loading.value = false
  }

  if (category.value && version === requestVersion.value) await loadMoreProducts()
}

const retry = () => resetCategory()

watch(categoryCode, resetCategory)
onMounted(resetCategory)
useHead(() => ({
  title: `${category.value ? categoryName(category.value) : t('category.products_title')} | Fashion Shop`,
}))
</script>
