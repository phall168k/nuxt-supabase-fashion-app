<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('stock.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('stock.description') }}</p>
        </div>

        <div class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row">
          <el-cascader
            v-model="params.categoryId"
            :options="categoryCascaderOptions"
            :props="{ checkStrictly: true, emitPath: false }"
            clearable
            filterable
            :placeholder="t('category.title')"
            class="sm:!w-[220px]"
            @change="searchItems"
          />
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('stock.search_placeholder')"
            class="sm:!w-[280px]"
            @keydown.enter="searchItems"
            @clear="searchItems"
          >
            <template #prefix>
              <Icon name="solar:magnifer-outline" />
            </template>
          </el-input>
        </div>
      </div>

      <el-table v-loading="loading" :data="items" stripe class="w-full" row-key="id">
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column :label="t('columns.thumbnail')" width="90" align="center">
          <template #default="{ row }">
            <el-image
              v-if="row.product.thumbnailUrl"
              :src="row.product.thumbnailUrl"
              fit="cover"
              class="h-11 w-11 rounded border border-slate-200"
            />
            <span v-else class="text-slate-400">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="product.code" :label="t('columns.code')" min-width="130" />
        <el-table-column :label="t('columns.product')" min-width="210">
          <template #default="{ row }">
            {{ productName(row.product) }}
          </template>
        </el-table-column>
        <el-table-column prop="minStock" :label="t('columns.min_stock')" width="120" align="right" />
        <el-table-column prop="stockIn" :label="t('columns.stock_in')" width="110" align="right" />
        <el-table-column prop="stockOut" :label="t('columns.stock_out')" width="110" align="right" />
        <el-table-column prop="stockAdjustment" :label="t('columns.stock_adjustment')" width="150" align="right" />
        <el-table-column :label="t('columns.current_stock')" width="130" align="right">
          <template #default="{ row }">
            <span :class="row.currentStock <= row.minStock ? 'font-semibold text-red-600' : 'font-semibold text-emerald-600'">
              {{ row.currentStock }}
            </span>
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.status')" width="125" align="center">
          <template #default="{ row }">
            <el-tag :type="row.currentStock <= row.minStock ? 'danger' : 'success'">
              {{ row.currentStock <= row.minStock ? t('stock.low_stock') : t('stock.in_stock') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.action')" fixed="right" width="90" align="center">
          <template #default="{ row }">
            <el-tooltip :content="t('edit')" placement="top">
              <el-button type="success" circle @click="openEditDialog(row)">
                <Icon name="solar:pen-2-outline" size="17" />
              </el-button>
            </el-tooltip>
          </template>
        </el-table-column>
      </el-table>

      <div class="flex flex-col gap-3 border-t border-slate-200 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-2 text-sm text-slate-600">
          <span>{{ t('dashboard.rows') }}</span>
          <el-select v-model="params.limit" class="!w-[88px]" @change="handleLimitChange">
            <el-option v-for="size in pageSizes" :key="size" :label="size" :value="size" />
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
      :title="t('stock.edit_title')"
      width="700px"
      align-center
      draggable
      append-to-body
    >
      <div v-if="editingItem" class="mb-4 rounded-md bg-slate-50 p-3">
        <p class="text-sm font-semibold text-slate-900">
          {{ editingItem.product.code }} · {{ productName(editingItem.product) }}
        </p>
      </div>

      <el-form
        id="stock-form"
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent="submit"
      >
        <div class="grid grid-cols-1 gap-x-4 sm:grid-cols-2">
          <el-form-item :label="t('columns.min_stock')" prop="minStock">
            <el-input-number v-model="form.minStock" :min="0" :precision="0" class="!w-full" />
          </el-form-item>
          <el-form-item :label="t('columns.stock_in')" prop="stockIn">
            <el-input-number v-model="form.stockIn" :min="0" :precision="0" class="!w-full" />
          </el-form-item>
          <el-form-item :label="t('columns.stock_out')" prop="stockOut">
            <el-input-number v-model="form.stockOut" :min="0" :precision="0" class="!w-full" />
          </el-form-item>
          <el-form-item :label="t('columns.stock_adjustment')" prop="stockAdjustment">
            <el-input-number v-model="form.stockAdjustment" :precision="0" class="!w-full" />
          </el-form-item>
        </div>
        <div class="rounded-md border border-slate-200 bg-slate-50 p-3 text-sm">
          <span class="text-slate-600">{{ t('columns.current_stock') }}:</span>
          <strong class="ml-2 text-slate-900">{{ formCurrentStock }}</strong>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" native-type="submit" form="stock-form" :loading="submitting">
          {{ t('save') }}
        </el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules } from 'element-plus'

definePageMeta({ middleware: 'auth' })
useHead({ title: 'Sock | Fashion Store' })

interface StockProduct {
  id: string
  code: string | null
  nameEn: string
  nameKh: string
  thumbnailPath: string | null
  thumbnailUrl: string | null
}

interface CategoryOption {
  id: number
  code: string
  nameEn: string
  nameKh: string
  parentId: number | null
}

interface CategoryCascaderOption {
  value: number
  label: string
  children?: CategoryCascaderOption[]
}

interface StockItem {
  id: number
  productId: string
  minStock: number
  stockIn: number
  stockOut: number
  stockAdjustment: number
  currentStock: number
  product: StockProduct
}

interface StockRow {
  id: number
  product_id: string
  min_stock: number
  stock_in: number
  stock_out: number
  stock_adjustment: number
  product: {
    id: string
    code: string | null
    name_en: string
    name_kh: string
    images: Array<{
      image_path: string
      is_active: boolean
      sort_order: number
    }>
  }
}

const bucketName = 'fashion-images'
const pageSizes = [10, 20, 50, 100]
const stockSelect = 'id, product_id, min_stock, stock_in, stock_out, stock_adjustment, product:products!inner(id, code, name_en, name_kh, images:product_images(image_path, is_active, sort_order))'

const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()

const loading = ref(false)
const submitting = ref(false)
const items = ref<StockItem[]>([])
const categoryOptions = ref<CategoryOption[]>([])
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', categoryId: null as number | null, page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingItem = ref<StockItem | null>(null)
const formRef = ref<FormInstance>()
const form = reactive({ minStock: 0, stockIn: 0, stockOut: 0, stockAdjustment: 0 })

const rules = computed<FormRules>(() => ({
  minStock: [{ required: true, message: t('stock.value_required'), trigger: 'change' }],
  stockIn: [{ required: true, message: t('stock.value_required'), trigger: 'change' }],
  stockOut: [{ required: true, message: t('stock.value_required'), trigger: 'change' }],
  stockAdjustment: [{ required: true, message: t('stock.value_required'), trigger: 'change' }],
}))

const formCurrentStock = computed(() => form.stockIn - form.stockOut + form.stockAdjustment)

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('stock.title'))
  breadcrumbStore.setBreadcrumbs([t('inventory'), t('stock.title')])
})

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null && 'message' in error) {
    return String((error as { message?: string }).message || fallback)
  }
  return fallback
}

const imageUrl = (path: string | null) => path
  ? supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl
  : null

const mapStock = (row: StockRow): StockItem => {
  const stockIn = Number(row.stock_in)
  const stockOut = Number(row.stock_out)
  const stockAdjustment = Number(row.stock_adjustment)
  const thumbnail = [...(row.product.images ?? [])]
    .sort((a, b) => Number(b.is_active) - Number(a.is_active) || a.sort_order - b.sort_order)[0]

  return {
    id: row.id,
    productId: row.product_id,
    minStock: Number(row.min_stock),
    stockIn,
    stockOut,
    stockAdjustment,
    currentStock: stockIn - stockOut + stockAdjustment,
    product: {
      id: row.product.id,
      code: row.product.code,
      nameEn: row.product.name_en,
      nameKh: row.product.name_kh,
      thumbnailPath: thumbnail?.image_path ?? null,
      thumbnailUrl: imageUrl(thumbnail?.image_path ?? null),
    },
  }
}

const productName = (product: StockProduct) => locale.value === 'km' ? product.nameKh : product.nameEn
const categoryName = (category: CategoryOption) => locale.value === 'km' ? category.nameKh : category.nameEn
const categoryCascaderOptions = computed<CategoryCascaderOption[]>(() => {
  const nodes = new Map<number, CategoryCascaderOption>()
  categoryOptions.value.forEach(category => nodes.set(category.id, {
    value: category.id,
    label: `${category.code} · ${categoryName(category)}`,
    children: [],
  }))

  const roots: CategoryCascaderOption[] = []
  categoryOptions.value.forEach(category => {
    const node = nodes.get(category.id)!
    const parent = category.parentId === null ? undefined : nodes.get(category.parentId)
    if (parent) parent.children!.push(node)
    else roots.push(node)
  })

  nodes.forEach(node => {
    if (!node.children?.length) delete node.children
  })
  return roots
})

const categoryFilterIds = (categoryId: number | null) => {
  if (categoryId === null) return null
  const selected = categoryOptions.value.find(category => category.id === categoryId)
  if (!selected || selected.parentId !== null) return [categoryId]

  const ids = [categoryId]
  const appendChildren = (parentId: number) => {
    categoryOptions.value
      .filter(category => category.parentId === parentId)
      .forEach(category => {
        ids.push(category.id)
        appendChildren(category.id)
      })
  }
  appendChildren(categoryId)
  return ids
}

const loadCategories = async () => {
  const { data, error } = await supabase
    .from('categories')
    .select('id, code, name_en, name_kh, parent_id')
    .eq('is_active', true)
    .order('name_en')
  if (error) throw error
  categoryOptions.value = (data ?? []).map(category => ({
    id: category.id,
    code: category.code,
    nameEn: category.name_en,
    nameKh: category.name_kh,
    parentId: category.parent_id,
  }))
}

const matchingProductIds = async (search: string, categoryIds: number[] | null) => {
  if (!search && categoryIds === null) return null
  let query = supabase
    .from('products')
    .select('id')
  if (search) query = query.or(`code.ilike.%${search}%,name_en.ilike.%${search}%,name_kh.ilike.%${search}%`)
  if (categoryIds) query = query.in('category_id', categoryIds)
  const { data, error } = await query
  if (error) throw error
  return (data ?? []).map(row => String(row.id))
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    const selectedCategoryId = typeof params.categoryId === 'number' ? params.categoryId : null
    const productIds = await matchingProductIds(search, categoryFilterIds(selectedCategoryId))

    if (productIds?.length === 0) {
      items.value = []
      meta.totalItems = 0
      return
    }

    let query = supabase
      .from('stocks')
      .select(stockSelect, { count: 'exact' })
      .order('id', { ascending: false })
      .range(from, from + params.limit - 1)

    if (productIds) query = query.in('product_id', productIds)

    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as unknown as StockRow[]).map(mapStock)
    meta.totalItems = count ?? 0
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock.load_failed')), 'error')
  } finally {
    loading.value = false
  }
}

const searchItems = () => {
  params.page = 1
  loadItems()
}

const handleLimitChange = () => {
  params.page = 1
  loadItems()
}

const openEditDialog = (item: StockItem) => {
  editingItem.value = item
  Object.assign(form, {
    minStock: item.minStock,
    stockIn: item.stockIn,
    stockOut: item.stockOut,
    stockAdjustment: item.stockAdjustment,
  })
  dialogVisible.value = true
  nextTick(() => formRef.value?.clearValidate())
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || !editingItem.value) return

  try {
    submitting.value = true
    const { error } = await supabase
      .from('stocks')
      .update({
        min_stock: form.minStock,
        stock_in: form.stockIn,
        stock_out: form.stockOut,
        stock_adjustment: form.stockAdjustment,
        updated_at: new Date().toISOString(),
      })
      .eq('id', editingItem.value.id)
    if (error) throw error
    useNotification(t('stock.updated'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

onMounted(async () => {
  try {
    await Promise.all([loadCategories(), loadItems()])
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock.load_failed')), 'error')
  }
})
</script>
