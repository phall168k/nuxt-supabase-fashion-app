<template>
  <main class="py-6 sm:py-8 lg:py-10">
    <section class="mx-auto w-[90%] overflow-hidden rounded-lg bg-slate-100 shadow-sm">
      <el-carousel
        v-if="banners.length"
        height="clamp(280px, 37vw, 620px)"
        :interval="5000"
        arrow="hover"
        trigger="click"
      >
        <el-carousel-item v-for="banner in banners" :key="banner.id">
          <NuxtLink :to="productPath(banner)" class="group relative block h-full w-full">
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
                <h1 class="text-2xl font-bold tracking-tight sm:text-4xl lg:text-5xl">
                  {{ banner.title }}
                </h1>
                <p v-if="banner.description" class="mt-3 line-clamp-3 max-w-xl text-sm text-white/90 sm:text-base lg:text-lg">
                  {{ banner.description }}
                </p>
                <span class="mt-5 inline-flex items-center gap-2 rounded-md bg-white px-4 py-2 text-sm font-semibold text-slate-900 transition group-hover:bg-slate-100">
                  {{ t('home.shop_now') }}
                  <Icon name="lucide:arrow-right" size="17" />
                </span>
              </div>
            </div>
          </NuxtLink>
        </el-carousel-item>
      </el-carousel>

      <div v-else class="flex h-[clamp(280px,37vw,620px)] flex-col items-center justify-center text-slate-400">
        <Icon name="solar:gallery-wide-outline" size="48" />
        <p class="mt-3 text-sm">{{ t('home.no_banners') }}</p>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
interface BannerRow {
  id: number
  title: string
  description: string | null
  thumbnail_path: string
  product: { id: number; code: string } | null
}

interface Banner {
  id: number
  title: string
  description: string | null
  thumbnailUrl: string
  product: { id: number; code: string } | null
}

definePageMeta({ layout: 'client', title: 'Fashion Shop' })

const { t } = useI18n()
const supabase = useSupabaseClient()
const bucketName = 'fashion-images'

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
  path: '/products',
  query: { product: banner.product?.code ?? banner.product?.id },
})
</script>

<style scoped>
:deep(.el-carousel__container) {
  height: clamp(280px, 37vw, 620px) !important;
}

:deep(.el-carousel__indicators--horizontal) {
  bottom: 12px;
}
</style>
