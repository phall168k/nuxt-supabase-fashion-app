<template>
  <section class="min-h-screen pt-[80px]">
    <nav class="fixed inset-x-0 top-0 z-50 flex h-[80px] w-full flex-col items-center justify-center border-b bg-white/95 shadow-sm backdrop-blur">
      <nav class="h-[50px] w-[90%] flex items-center justify-center pt-2">
        <div class="w-[30%]">
          <NuxtLink class="text-[20px] font-bold text-slate-900" to="/">{{ $t('app.title') }}</NuxtLink>
        </div>
        <div class="w-[40%] flex items-center justify-center">
          <!-- <el-image class="h-5" src="https://myten11.com/images/logos/logo1.png" fit="cover"/> -->
        </div>
        <div class="w-[30%] h-full flex items-center justify-end gap-3">
          <Icon  
            @click="handleChangeLocalizaiton(locale === 'en' ? 'km' : 'en')"
            :size="25" 
            class="cursor-pointer"
            :name="locale === 'km' ? 'emojione:flag-for-cambodia' : 'emojione:flag-for-united-kingdom'"
          />
          <el-input
            v-model="searchKeyword"
            :placeholder="t('search.placeholder')"
            clearable
            @keydown.enter="submitSearch"
            @clear="submitSearch"
          >
            <template #prefix>
              <Icon name="iconamoon:search-bold"/>
            </template>
          </el-input>
          <Icon size="25" name="lucide:user-round"/>
          <Icon size="25" name="iconamoon:shopping-bag-light"/>
        </div>
      </nav>
      <nav
        class="h-[30px] w-[90%] flex items-center justify-start gap-8 pb-2"
        aria-label="Product categories"
        @mouseleave="closeDropdown"
      >
        <div
          v-for="category in categories"
          :key="category.id"
          class="h-full flex items-center"
          @mouseenter="openDropdown(category.id)"
        >
          <button
            type="button"
            class="category-trigger"
            :class="{ 'category-trigger--active': activeCategoryId === category.id }"
            :aria-expanded="activeCategoryId === category.id"
            :aria-controls="`category-menu-${category.id}`"
            @click="toggleDropdown(category.id)"
            @focus="openDropdown(category.id)"
          >
            <span>{{ categoryName(category) }}</span>
            <Icon
              name="lucide:chevron-down"
              size="15"
              class="transition-transform duration-200"
              :class="{ 'rotate-180': activeCategoryId === category.id }"
            />
          </button>

          <Transition name="category-menu">
            <section
              v-if="activeCategoryId === category.id"
              :id="`category-menu-${category.id}`"
              class="category-dropdown"
              @mouseenter="openDropdown(category.id)"
            >
              <div class="mx-auto w-[90%] py-5">
                <NuxtLink
                  :to="categoryPath(category)"
                  class="inline-flex items-center gap-2 font-semibold text-gray-900 hover:text-black"
                  @click="closeDropdown"
                >
                  <Icon :name="category.icon || defaultCategoryIcon" size="20" />
                  {{ categoryName(category) }}
                </NuxtLink>
                <div class="mt-4 grid max-w-2xl grid-cols-1 gap-x-20 gap-y-3 sm:grid-cols-2">
                  <NuxtLink
                    v-for="child in category.children"
                    :key="child.id"
                    :to="categoryPath(child)"
                    class="group flex min-w-0 items-center gap-3 text-sm text-gray-600 hover:text-black"
                    @click="closeDropdown"
                  >
                    <span class="category-thumbnail">
                      <Icon
                        :name="child.icon || defaultCategoryIcon"
                        size="20"
                        class="text-gray-500 transition-transform duration-200 group-hover:scale-110"
                      />
                    </span>
                    <span class="truncate">{{ categoryName(child) }}</span>
                  </NuxtLink>
                </div>
              </div>
            </section>
          </Transition>
        </div>
      </nav>
    </nav>
    <slot />
  </section>
</template>

<script setup lang="ts">
  interface CategoryRow {
    id: number
    code: string
    name_en: string
    name_kh: string
    icon: string | null
    parent_id: number | null
  }

  interface Category extends CategoryRow {
    children: Category[]
  }

  const { t, locale, setLocale } = useI18n()
  const route = useRoute()
  const router = useRouter()
  const searchKeyword = ref(typeof route.query.q === 'string' ? route.query.q : '')
  const handleChangeLocalizaiton = (e: any) => {
    setLocale(e);
  }

  const activeCategoryId = ref<number | null>(null)
  const defaultCategoryIcon = 'solar:tag-outline'
  const supabase = useSupabaseClient()

  watch(() => route.query.q, value => {
    searchKeyword.value = typeof value === 'string' ? value : ''
  })

  const submitSearch = () => {
    const keyword = searchKeyword.value.trim()
    closeDropdown()
    router.push({ path: '/search', query: keyword ? { q: keyword } : {} })
  }

  const { data: categoryRows } = await useAsyncData('client-categories', async () => {
    const { data, error } = await supabase
      .from('categories')
      .select('id, code, name_en, name_kh, icon, parent_id')
      .eq('is_active', true)
      .order('name_en')

    if (error) throw error
    return (data ?? []) as CategoryRow[]
  }, { default: () => [] })

  const categories = computed<Category[]>(() => {
    const nodes = new Map<number, Category>()
    for (const row of categoryRows.value) nodes.set(row.id, { ...row, children: [] })

    const roots: Category[] = []
    for (const category of nodes.values()) {
      const parent = category.parent_id === null ? null : nodes.get(category.parent_id)
      if (parent) parent.children.push(category)
      else roots.push(category)
    }
    return roots
  })

  const categoryName = (category: Category) => {
    return locale.value === 'km' ? category.name_kh : category.name_en;
  };

  const categoryPath = (category: Category) => ({
    path: '/category',
    query: { 'category-code': category.code },
  });

  const openDropdown = (categoryId: number) => {
    activeCategoryId.value = categoryId;
  };

  const closeDropdown = () => {
    activeCategoryId.value = null;
  };

  const toggleDropdown = (categoryId: number) => {
    activeCategoryId.value = activeCategoryId.value === categoryId
      ? null
      : categoryId;
  };
</script>

<style scoped>
  .category-trigger {
    display: flex;
    height: 100%;
    align-items: center;
    gap: 0.25rem;
    border-bottom: 2px solid transparent;
    color: #374151;
    font-size: 0.875rem;
    transition: color 150ms ease, border-color 150ms ease;
  }

  .category-trigger:hover,
  .category-trigger--active {
    border-bottom-color: #111827;
    color: #111827;
  }

  .category-dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    width: 100%;
    min-height: 250px;
    border-top: 1px solid #f3f4f6;
    background: #fff;
    box-shadow: 0 12px 24px rgb(0 0 0 / 8%);
  }

  .category-thumbnail {
    display: flex;
    width: 2.25rem;
    height: 2.25rem;
    flex: 0 0 2.25rem;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    border-radius: 9999px;
    background: #f3f4f6;
  }

  .category-menu-enter-active,
  .category-menu-leave-active {
    transition: opacity 150ms ease, transform 150ms ease;
    transform-origin: top;
  }

  .category-menu-enter-from,
  .category-menu-leave-to {
    opacity: 0;
    transform: translateY(-4px);
  }
</style>
