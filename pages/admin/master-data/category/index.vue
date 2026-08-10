<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('category.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('category.description') }}</p>
        </div>

        <div class="flex flex-col gap-2 sm:flex-row sm:items-center">
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('category.search_placeholder')"
            class="sm:!w-[260px]"
            @keydown.enter="loadItems"
            @clear="loadItems"
          >
            <template #prefix>
              <Icon name="solar:magnifer-outline" />
            </template>
          </el-input>
          <el-button type="primary" @click="openCreateDialog">
            <Icon name="solar:add-circle-outline" size="18" />
            <span class="ml-1">{{ t('create') }}</span>
          </el-button>
        </div>
      </div>

      <el-table
        v-loading="loading"
        :data="items"
        stripe
        class="w-full"
        row-key="id"
        :tree-props="{ children: 'children' }"
        :indent="28"
      >
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column :label="t('columns.icon')" width="90" align="center">
          <template #default="{ row }">
            <Icon v-if="row.icon" :name="row.icon" size="24" />
            <span v-else class="text-slate-400">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="code" :label="t('columns.code')" min-width="140" />
        <el-table-column prop="nameEn" :label="t('columns.name_en')" min-width="220" />
        <el-table-column prop="nameKh" :label="t('columns.name_kh')" min-width="220" />
        <el-table-column :label="t('columns.created_by')" min-width="180">
          <template #default="{ row }">
            {{ displayCreatedBy(row.createdBy) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.created_at')" min-width="190">
          <template #default="{ row }">
            {{ displayCreatedAt(row.createdAt) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.action')" fixed="right" width="140" align="center">
          <template #default="{ row }">
            <div class="flex items-center justify-center gap-2">
              <el-tooltip :content="t('edit')" placement="top">
                <el-button type="success" circle @click="openEditDialog(row)">
                  <Icon name="solar:pen-2-outline" size="17" />
                </el-button>
              </el-tooltip>
              <el-tooltip :content="t('delete')" placement="top">
                <el-button type="danger" circle @click="deleteItem(row)">
                  <Icon name="solar:trash-bin-trash-outline" size="17" />
                </el-button>
              </el-tooltip>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <div class="flex flex-col gap-3 border-t border-slate-200 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-2 text-sm text-slate-600">
          <span>{{ t('dashboard.rows') }}</span>
          <el-select v-model="params.limit" class="!w-[88px]" @change="handleLimitChange">
            <el-option
              v-for="size in pageSizes"
              :key="size"
              :label="size"
              :value="size"
            />
          </el-select>
          <span>{{ t('total') }}: {{ meta.totalItems }}</span>
        </div>

        <el-pagination
          v-model:current-page="params.page"
          background
          layout="prev, pager, next"
          :page-size="params.limit"
          :total="meta.totalItems"
          @current-change="loadItems"
        />
      </div>
    </div>

    <el-dialog
      v-model="dialogVisible"
      :title="editingItem ? t('category.edit_title') : t('category.create_title')"
      width="720px"
      align-center
      append-to-body
      modal-class="admin-dialog-mask"
      draggable
    >
      <el-form
        id="category-form"
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent="submit"
      >
        <el-form-item :label="t('columns.code')" prop="code">
          <el-input v-model="form.code" :placeholder="t('category.code_auto_generated')" disabled />
        </el-form-item>
        <el-form-item :label="t('columns.icon')" prop="icon">
          <el-input v-model="form.icon" placeholder="solar:t-shirt-outline">
            <template #prefix>
              <Icon v-if="form.icon" :name="form.icon" size="18" />
              <Icon v-else name="solar:gallery-outline" size="18" />
            </template>
          </el-input>
          <p class="mt-1 text-xs text-slate-500">{{ t('category.icon_help') }}</p>
        </el-form-item>
        <el-form-item :label="t('columns.name_en')" prop="nameEn">
          <el-input v-model="form.nameEn" placeholder="Beverage" />
        </el-form-item>
        <el-form-item :label="t('columns.name_kh')" prop="nameKh">
          <el-input v-model="form.nameKh" :placeholder="t('columns.name_kh')" />
        </el-form-item>
        <el-form-item :label="t('columns.parent_category')" prop="parentId">
          <el-select
            v-model="form.parentId"
            :placeholder="t('category.select_parent')"
            :loading="loadingParents"
            clearable
            filterable
            class="w-full"
          >
            <el-option
              v-for="parent in parentOptions"
              :key="parent.id"
              :value="parent.id"
              :label="`[${parent.id}] ${parent.nameEn} / ${parent.nameKh}`"
            />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button
          type="primary"
          native-type="submit"
          form="category-form"
          :loading="submitting"
        >
          {{ t('save') }}
        </el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules } from 'element-plus'

definePageMeta({
  middleware: 'auth',
})

useHead({
  title: 'MINI-POS-CATEGORY'
})

interface Category {
  id: number
  code: string
  icon: string | null
  nameEn: string
  nameKh: string
  parentId: number | null
  children?: Category[]
  createdAt?: string | Date | null
  createdBy?: string | {
    username?: string
    name?: string
    email?: string
  } | null
}

interface CategoryRow {
  id: number
  code: string
  icon: string | null
  name_en: string
  name_kh: string
  parent_id: number | null
  created_at: string | null
  created_by_user_id: string | null
}

const pageSizes = [10, 20, 50, 100]

const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const loading = ref(false)
const loadingParents = ref(false)
const submitting = ref(false)
const items = ref<Category[]>([])
const parentOptions = ref<Category[]>([])
const meta = reactive({
  totalItems: 0,
  currentPage: 1,
  totalPages: 1,
})
const params = reactive({
  search: '',
  page: 1,
  limit: 10,
})

const formRef = ref<FormInstance>()
const dialogVisible = ref(false)
const editingItem = ref<Category | null>(null)

const emptyForm = () => ({
  code: '',
  icon: '',
  nameEn: '',
  nameKh: '',
  parentId: null as number | null,
})

const form = reactive(emptyForm())

const rules = computed<FormRules>(() => ({
  nameEn: [{ required: true, message: t('category.name_en_required'), trigger: 'blur' }],
  nameKh: [{ required: true, message: t('category.name_kh_required'), trigger: 'blur' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('menu.category'))
  breadcrumbStore.setBreadcrumbs([t('menu.master_data'), t('menu.category')])
})

watch(
  () => params.search,
  () => {
    params.page = 1
  },
)

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null) {
    const maybeError = error as {
      message?: string
      data?: {
        message?: string
      }
    }

    return maybeError.data?.message ?? maybeError.message ?? fallback
  }

  return fallback
}

const mapCategory = (row: CategoryRow): Category => ({
  id: row.id,
  code: row.code,
  icon: row.icon,
  nameEn: row.name_en,
  nameKh: row.name_kh,
  parentId: row.parent_id,
  createdAt: row.created_at,
  createdBy: row.created_by_user_id,
})

const displayCreatedBy = (createdBy: Category['createdBy']) => {
  if (!createdBy) return '-'

  if (typeof createdBy === 'string') return createdBy

  return createdBy.username ?? createdBy.name ?? createdBy.email ?? '-'
}

const displayCreatedAt = (createdAt: Category['createdAt']) => {
  if (!createdAt) return '-'

  const date = new Date(createdAt)

  if (Number.isNaN(date.getTime())) return '-'

  return new Intl.DateTimeFormat(locale.value, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

const resetForm = (value = emptyForm()) => {
  Object.assign(form, {
    code: value.code,
    icon: value.icon ?? '',
    nameEn: value.nameEn,
    nameKh: value.nameKh,
    parentId: value.parentId,
  })
  nextTick(() => formRef.value?.clearValidate())
}

const loadParentOptions = async (excludeId?: number) => {
  try {
    loadingParents.value = true

    const { data, error } = await supabase
      .from('categories')
      .select('id, code, icon, name_en, name_kh, parent_id, created_at, created_by_user_id')
      .is('parent_id', null)
      .order('name_en')

    if (error) throw error

    parentOptions.value = ((data ?? []) as CategoryRow[])
      .filter(row => row.id !== excludeId)
      .map(mapCategory)
  } catch (error) {
    parentOptions.value = []
    useNotification(getErrorMessage(error, t('category.load_parents_failed')), 'error')
  } finally {
    loadingParents.value = false
  }
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const to = from + params.limit - 1
    const search = params.search.trim().replace(/[,%()]/g, '')

    let query = supabase
      .from('categories')
      .select('id, code, icon, name_en, name_kh, parent_id, created_at, created_by_user_id', { count: 'exact' })
      .is('parent_id', null)
      .order('created_at', { ascending: false })
      .range(from, to)

    if (search) {
      query = query.or(
        `code.ilike.%${search}%,name_en.ilike.%${search}%,name_kh.ilike.%${search}%`,
      )
    }

    const { data, count, error } = await query

    if (error) throw error

    const parentRows = (data ?? []) as CategoryRow[]
    const parentIds = parentRows.map(row => row.id)
    let children: CategoryRow[] = []

    if (parentIds.length) {
      const { data: childData, error: childError } = await supabase
        .from('categories')
        .select('id, code, icon, name_en, name_kh, parent_id, created_at, created_by_user_id')
        .in('parent_id', parentIds)
        .order('created_at', { ascending: false })

      if (childError) throw childError
      children = (childData ?? []) as CategoryRow[]
    }

    items.value = parentRows.map((row) => ({
      ...mapCategory(row),
      children: children
        .filter(child => child.parent_id === row.id)
        .map(mapCategory),
    }))
    meta.totalItems = count ?? 0
    meta.currentPage = params.page
    meta.totalPages = Math.max(1, Math.ceil(meta.totalItems / params.limit))
  } catch (error) {
    useNotification(getErrorMessage(error, t('category.load_failed')), 'error')
  } finally {
    loading.value = false
  }
}

const handleLimitChange = () => {
  params.page = 1
  loadItems()
}

const openCreateDialog = () => {
  editingItem.value = null
  resetForm()
  dialogVisible.value = true
  loadParentOptions()
}

const openEditDialog = async (item: Category) => {
  editingItem.value = item
  resetForm(item)
  dialogVisible.value = true
  loadParentOptions(item.id)

  try {
    submitting.value = true
    const { data, error } = await supabase
      .from('categories')
      .select('id, code, icon, name_en, name_kh, parent_id, created_at, created_by_user_id')
      .eq('id', item.id)
      .single()

    if (error) throw error

    resetForm(mapCategory(data as CategoryRow))
  } catch (error) {
    useNotification(getErrorMessage(error, t('category.load_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)

  if (!valid) return

  try {
    submitting.value = true
    const values = {
      icon: form.icon.trim() || null,
      name_en: form.nameEn.trim(),
      name_kh: form.nameKh.trim(),
      parent_id: form.parentId,
    }

    const { error } = editingItem.value
      ? await supabase
          .from('categories')
          .update({ ...values, code: form.code })
          .eq('id', editingItem.value.id)
      : await supabase
          .from('categories')
          .insert({
            ...values,
            created_by_user_id: user.value?.id ?? null,
          })

    if (error) throw error

    useNotification(editingItem.value ? t('category.updated') : t('category.created'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) {
    useNotification(getErrorMessage(error, t('category.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const deleteItem = async (item: Category) => {
  try {
    await ElMessageBox.confirm(
      t('category.confirm_delete', { code: item.code }),
      t('category.delete_title'),
      {
        confirmButtonText: t('delete'),
        cancelButtonText: t('cancel'),
        type: 'warning',
      },
    )

    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', item.id)

    if (error) throw error

    if (item.parentId === null && items.value.length === 1 && params.page > 1) {
      params.page -= 1
    }

    useNotification(t('category.deleted'))
    await loadItems()
  } catch (error) {
    if (error === 'cancel' || error === 'close') {
      return
    }

    useNotification(getErrorMessage(error, t('category.delete_failed')), 'error')
  }
}

onMounted(() => {
  loadItems()
})
</script>
