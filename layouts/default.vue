<template>
  <div class="min-h-screen bg-slate-100 text-slate-800">
    <aside
      class="fixed inset-y-0 left-0 z-40 flex h-screen flex-col overflow-hidden border-r border-slate-200 bg-white transition-all duration-200"
      :class="collapseStore.isCollapsed ? 'w-[72px]' : 'w-[260px]'"
    >
      <div class="flex h-16 shrink-0 items-center gap-3 border-b border-slate-200 px-4">
        <Icon :size="30" :name="$t('app.icon')"/>
        <div v-show="!collapseStore.isCollapsed" class="min-w-0">
          <p class="truncate text-sm font-semibold text-slate-900">{{ $t('app.title') }}</p>
          <p class="truncate text-xs text-slate-500">{{ t('headers.admin_console') }}</p>
        </div>
      </div>

      <el-scrollbar class="min-h-0 flex-1" height="100%">
        <el-menu
          :collapse="collapseStore.isCollapsed"
          :default-active="activeMenu"
          unique-opened
          class="!border-0 px-2 py-3"
          router
        >
          <template
            v-for="item in filteredMenus"
            :key="item.index"
          >
            <el-menu-item
              v-if="!item.children"
              :index="item.index"
            >
              <el-icon>
                <Icon :name="item.icon" size="20" />
              </el-icon>
              <template #title>{{ t(item.label) }}</template>
            </el-menu-item>

            <el-sub-menu
              v-else
              :index="item.index"
            >
              <template #title>
                <el-icon>
                  <Icon :name="item.icon" size="20" />
                </el-icon>
                <span>{{ t(item.label) }}</span>
              </template>

              <el-menu-item
                v-for="child in item.children"
                :key="child.index"
                :index="child.index"
              >
                <el-icon>
                  <Icon :name="child.icon" size="18" />
                </el-icon>
                <template #title>{{ t(child.label) }}</template>
              </el-menu-item>
            </el-sub-menu>
          </template>

        </el-menu>
      </el-scrollbar>
    </aside>

    <header
      class="fixed right-0 top-0 z-30 flex h-16 items-center justify-between border-b border-slate-200 bg-white px-5 transition-all duration-200"
      :class="collapseStore.isCollapsed ? 'left-[72px]' : 'left-[260px]'"
    >
      <div class="flex min-w-0 items-center gap-4">
        <el-button text circle @click="collapseStore.setCollapse">
          <Icon
            :name="collapseStore.isCollapsed ? 'solar:hamburger-menu-outline' : 'solar:sidebar-minimalistic-outline'"
            size="22"
          />
        </el-button>

        <div class="min-w-0">
          <h1 class="truncate text-lg font-semibold text-slate-900">
            {{ pageTitle }}
          </h1>
          <el-breadcrumb separator="/" class="mt-1">
            <el-breadcrumb-item
              v-for="item in breadcrumbs"
              :key="item"
            >
              {{ item }}
            </el-breadcrumb-item>
          </el-breadcrumb>
        </div>
      </div>

      <div class="flex items-center gap-3">
        <el-segmented
          v-model="selectedLocale"
          :options="languageOptions"
          size="small"
          class="language-switcher hidden sm:flex"
        >
          <template #default="{ item }">
            <span class="language-switcher__option">
              <Icon
                :name="item.flag"
                class="language-switcher__flag"
                aria-hidden="true"
              />
              <span class="language-switcher__label">{{ item.label }}</span>
            </span>
          </template>
        </el-segmented>
        <el-button text circle>
          <Icon name="solar:bell-outline" size="20" />
        </el-button>
        <el-dropdown trigger="click">
          <button class="flex items-center gap-3 rounded-md px-2 py-1.5 text-left hover:bg-slate-100">
            <span class="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-sm font-semibold text-orange-500 border">
            </span>
            <span class="hidden leading-tight sm:block">
              <span class="block text-sm font-medium text-slate-900"></span>
              <span class="block text-xs text-slate-500">{{ user?.email }}</span>
            </span>
            <Icon name="solar:alt-arrow-down-outline" size="16" />
          </button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="edit-profile">
                <Icon name="mynaui:user" size="17" class="mr-2" />
                {{ t('headers.edit_profile') }}
              </el-dropdown-item>
              <el-dropdown-item command="change-password">
                <Icon name="solar:lock-password-outline" size="17" class="mr-2" />
                {{ t('headers.change_password') }}
              </el-dropdown-item>
              <el-dropdown-item command="logout" @click="logout()">
                <Icon name="solar:logout-broken" size="17" class="mr-2" />
                {{ t('headers.logout') }}
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </header>

    <main
      class="min-h-screen pt-16 transition-all duration-200"
      :class="collapseStore.isCollapsed ? 'pl-[72px]' : 'pl-[260px]'"
    >
      <div class="p-5">
        <slot />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">

interface RoleOption {
  id: number
  name: string
}

interface HeaderUser {
  id: number
  username: string
  email: string
  telegramChatId?: string | null
  isActive: boolean
  isAdmin?: boolean
  createdAt?: string | Date
  updatedAt?: string | Date
  deletedAt?: string | Date | null
  role?: RoleOption[] | number[]
  roles?: RoleOption[] | number[] | string[]
  permissions?: string[]
}

interface UserResponse {
  payload: HeaderUser
}

interface RoleListResponse {
  payload: RoleOption[]
}

const route = useRoute()
const collapseStore = useCollapseStore()
const breadcrumbStore = useBreadcrumbStore()
const { t, locale, setLocale } = useI18n()

const activeMenu = computed(() => route.path)
const pageTitle = computed(() => breadcrumbStore.pageTitle || t('menu.dashboard'))
const breadcrumbs = computed(() => breadcrumbStore.breadcrumbs.length ? breadcrumbStore.breadcrumbs : [t('menu.dashboard')])
type AppLocale = 'en' | 'km'

const selectedLocale = ref<AppLocale>(locale.value as AppLocale)


const languageOptions = [
  { label: 'English', value: 'en', flag: 'circle-flags:us' },
  { label: 'ខ្មែរ', value: 'km', flag: 'circle-flags:kh' },
]

interface MenuChild {
  index: string;
  label: string;
  icon: string;
}

interface MenuItem {
  index: string;
  label: string;
  icon: string;
  children?: MenuChild[];
}

const menuItems: MenuItem[] = [
  {
    index: '/',
    label: 'dashboard.title',
    icon: 'solar:widget-5-outline',
  },
  {
    index: 'master-data',
    label: 'master_data',
    icon: 'solar:database-outline',
    children: [
      { 
        index: '/admin/master-data/category/', 
        label: 'category.title', 
        icon: 'solar:folder-with-files-outline',
      },
      {
        index: '/admin/master-data/product/',
        label: 'product.title',
        icon: 'solar:t-shirt-outline',
      },
    ],
  },
  {
    index: 'system',
    label: 'system',
    icon: 'solar:settings-outline',
    children: [
      { 
        index: '/admin/system/user/', 
        label: 'user.title', 
        icon: 'solar:user-id-outline',
      }
    ],
  },
]

const filterMenus = (menus: MenuItem[]): MenuItem[] => {
  return menus.reduce<MenuItem[]>((result, menu) => {
    if (!menu.children?.length) {
      result.push(menu);
      return result;
    }

    result.push({
      ...menu,
      children: [...menu.children],
    });

    return result;
  }, []);
};

const filteredMenus = computed(() =>
  filterMenus(menuItems),
);


watch(selectedLocale, async (value) => {
  await setLocale(value)
})

watch(locale, (value) => {
  selectedLocale.value = value as AppLocale
})

const user = useSupabaseUser();
const supabase = useSupabaseClient();

const logout = async () => {
  await supabase.auth.signOut();
  await navigateTo('/auth/login');
}


</script>

<style scoped>
.language-switcher {
  --el-segmented-bg-color: #f8fafc;
  --el-segmented-item-hover-bg-color: #eef2f7;
  --el-segmented-item-selected-bg-color: #f59e0b;
  --el-segmented-item-selected-color: #ffffff;
  --el-segmented-item-selected-disabled-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 2px;
}

.language-switcher :deep(.el-segmented__group) {
  align-items: center;
  gap: 2px;
}

.language-switcher :deep(.el-segmented__item) {
  min-width: 96px;
  height: 25px;
  border-radius: 6px;
  padding: 0 10px;
}

.language-switcher :deep(.el-segmented__item-label) {
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

.language-switcher__option {
  display: inline-flex;
  width: 100%;
  align-items: center;
  justify-content: center;
  gap: 7px;
  white-space: nowrap;
  font-size: 12px;
  font-weight: 400;
}

.language-switcher__flag {
  width: 18px;
  height: 18px;
  flex: 0 0 18px;
  border-radius: 9999px;
  box-shadow: 0 0 0 1px rgb(15 23 42 / 8%);
}

.language-switcher__label {
  min-width: 0;
}
</style>
