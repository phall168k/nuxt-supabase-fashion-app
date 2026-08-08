<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('stock_in.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('stock_in.description') }}</p>
        </div>
        <div class="flex flex-col gap-2 sm:flex-row">
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('stock_in.search_placeholder')"
            class="sm:!w-[250px]"
            @keydown.enter="searchItems"
            @clear="searchItems"
          >
            <template #prefix><Icon name="solar:magnifer-outline" /></template>
          </el-input>
          <el-button type="primary" @click="openCreateDialog">
            <Icon name="solar:add-circle-outline" size="18" />
            <span class="ml-1">{{ t('create') }}</span>
          </el-button>
        </div>
      </div>

      <el-table v-loading="loading" :data="items" stripe row-key="id" class="w-full">
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column type="expand">
          <template #default="{ row }">
            <div class="px-8 py-3">
              <el-table :data="row.items" size="small" border>
                <el-table-column prop="product.code" :label="t('columns.code')" width="140" />
                <el-table-column :label="t('columns.product')" min-width="220">
                  <template #default="scope">{{ productName(scope.row.product) }}</template>
                </el-table-column>
                <el-table-column prop="quantity" :label="t('columns.quantity')" width="120" align="right" />
                <el-table-column prop="note" :label="t('columns.note')" min-width="200">
                  <template #default="scope">{{ scope.row.note || '—' }}</template>
                </el-table-column>
              </el-table>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="code" :label="t('columns.code')" min-width="150" />
        <el-table-column prop="stockInDate" :label="t('columns.stock_in_date')" min-width="150" />
        <el-table-column :label="t('columns.items')" width="100" align="right">
          <template #default="{ row }">{{ row.items.length }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.total_quantity')" width="150" align="right">
          <template #default="{ row }">{{ totalQuantity(row.items) }}</template>
        </el-table-column>
        <el-table-column prop="description" :label="t('columns.description')" min-width="240">
          <template #default="{ row }">{{ row.description || '—' }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.action')" fixed="right" width="140" align="center">
          <template #default="{ row }">
            <div class="flex justify-center gap-2">
              <el-button type="success" circle @click="openEditDialog(row)">
                <Icon name="solar:pen-2-outline" size="17" />
              </el-button>
              <el-button type="danger" circle @click="deleteItem(row)">
                <Icon name="solar:trash-bin-trash-outline" size="17" />
              </el-button>
            </div>
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
      :title="editingItem ? t('stock_in.edit_title') : t('stock_in.create_title')"
      width="850px"
      align-center
      append-to-body
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <div class="grid grid-cols-1 gap-x-4 sm:grid-cols-2">
          <el-form-item :label="t('columns.code')">
            <el-input v-model="form.code" readonly />
          </el-form-item>
          <el-form-item :label="t('columns.stock_in_date')" prop="stockInDate">
            <el-date-picker
              v-model="form.stockInDate"
              type="date"
              value-format="YYYY-MM-DD"
              :placeholder="t('stock_in.select_date')"
              class="!w-full"
              @change="refreshCodePreview"
            />
          </el-form-item>
        </div>
        <el-form-item :label="t('columns.description')">
          <el-input v-model="form.description" type="textarea" :rows="2" maxlength="500" show-word-limit />
        </el-form-item>

        <div class="mb-3 flex items-center justify-between">
          <h3 class="font-semibold text-slate-900">{{ t('columns.items') }}</h3>
          <el-button type="primary" plain @click="addLine">
            <Icon name="solar:add-circle-outline" size="17" />
            <span class="ml-1">{{ t('stock_in.add_item') }}</span>
          </el-button>
        </div>

        <div class="space-y-3">
          <div
            v-for="(line, index) in form.items"
            :key="line.key"
            class="grid grid-cols-1 gap-3 rounded-md border border-slate-200 p-3 md:grid-cols-[minmax(240px,1fr)_130px_minmax(180px,1fr)_40px]"
          >
            <el-form-item :label="t('columns.product')" class="!mb-0">
              <el-select v-model="line.productId" filterable :placeholder="t('stock_in.select_product')" class="w-full">
                <el-option
                  v-for="product in productOptions"
                  :key="product.id"
                  :value="product.id"
                  :label="`${product.code || '—'} · ${productName(product)}`"
                  :disabled="isProductSelected(product.id, index)"
                />
              </el-select>
            </el-form-item>
            <el-form-item :label="t('columns.quantity')" class="!mb-0">
              <el-input-number v-model="line.quantity" :min="1" :precision="0" class="!w-full" />
            </el-form-item>
            <el-form-item :label="t('columns.note')" class="!mb-0">
              <el-input v-model="line.note" maxlength="255" />
            </el-form-item>
            <div class="flex items-end pb-1">
              <el-button type="danger" text circle :disabled="form.items.length === 1" @click="removeLine(index)">
                <Icon name="solar:trash-bin-trash-outline" size="18" />
              </el-button>
            </div>
          </div>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" :loading="submitting" @click="submit">{{ t('save') }}</el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules } from 'element-plus'

definePageMeta({ middleware: 'auth' })
useHead({ title: 'MINI-POS-STOCK-IN' })

interface ProductOption {
  id: number
  code: string | null
  nameEn: string
  nameKh: string
}

interface StockInLine {
  id?: number
  key: string
  productId: number | null
  quantity: number
  note: string
  product?: ProductOption
}

interface StockInItem {
  id: number
  code: string
  stockInDate: string
  description: string | null
  items: StockInLine[]
}

interface StockInRow {
  id: number
  code: string
  stock_in_date: string
  description: string | null
  items: Array<{
    id: number
    product_id: number
    quantity: number
    note: string | null
    product: { id: number; code: string | null; name_en: string; name_kh: string }
  }>
}

const pageSizes = [10, 20, 50, 100]
const stockInSelect = 'id, code, stock_in_date, description, items:stock_in_items(id, product_id, quantity, note, product:products(id, code, name_en, name_kh))'
const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()

const loading = ref(false)
const submitting = ref(false)
const items = ref<StockInItem[]>([])
const productOptions = ref<ProductOption[]>([])
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingItem = ref<StockInItem | null>(null)
const formRef = ref<FormInstance>()
const nextExpectedId = ref(1)

const newLine = (): StockInLine => ({
  key: crypto.randomUUID(),
  productId: null,
  quantity: 1,
  note: '',
})

const today = () => new Date().toISOString().slice(0, 10)
const form = reactive({ code: '', stockInDate: today(), description: '', items: [newLine()] })
const rules = computed<FormRules>(() => ({
  stockInDate: [{ required: true, message: t('stock_in.date_required'), trigger: 'change' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('stock_in.title'))
  breadcrumbStore.setBreadcrumbs([t('inventory'), t('stock_in.title')])
})

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null && 'message' in error) {
    return String((error as { message?: string }).message || fallback)
  }
  return fallback
}

const productName = (product: ProductOption) => locale.value === 'km' ? product.nameKh : product.nameEn
const totalQuantity = (lines: StockInLine[]) => lines.reduce((sum, line) => sum + line.quantity, 0)

const formatCode = (id: number, date: string) => {
  const year = date?.slice(2, 4) || new Date().getFullYear().toString().slice(-2)
  return `STI${year}${String(id).padStart(5, '0')}`
}

const mapRow = (row: StockInRow): StockInItem => ({
  id: row.id,
  code: row.code,
  stockInDate: row.stock_in_date,
  description: row.description,
  items: (row.items ?? []).map(line => ({
    id: line.id,
    key: String(line.id),
    productId: line.product_id,
    quantity: line.quantity,
    note: line.note ?? '',
    product: {
      id: line.product.id,
      code: line.product.code,
      nameEn: line.product.name_en,
      nameKh: line.product.name_kh,
    },
  })),
})

const loadProducts = async () => {
  const { data, error } = await supabase.from('products').select('id, code, name_en, name_kh').order('name_en')
  if (error) {
    useNotification(getErrorMessage(error, t('stock_in.load_products_failed')), 'error')
    return
  }
  productOptions.value = (data ?? []).map(row => ({
    id: row.id as number,
    code: row.code as string | null,
    nameEn: row.name_en as string,
    nameKh: row.name_kh as string,
  }))
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase.from('stock_ins').select(stockInSelect, { count: 'exact' })
      .order('stock_in_date', { ascending: false }).order('id', { ascending: false })
      .range(from, from + params.limit - 1)
    if (search) query = query.or(`code.ilike.%${search}%,description.ilike.%${search}%`)
    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as unknown as StockInRow[]).map(mapRow)
    meta.totalItems = count ?? 0
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock_in.load_failed')), 'error')
  } finally {
    loading.value = false
  }
}

const loadNextCode = async () => {
  const { data, error } = await supabase.from('stock_ins').select('id').order('id', { ascending: false }).limit(1)
  if (error) throw error
  nextExpectedId.value = Number(data?.[0]?.id ?? 0) + 1
  form.code = formatCode(nextExpectedId.value, form.stockInDate)
}

const refreshCodePreview = () => {
  if (!editingItem.value) form.code = formatCode(nextExpectedId.value, form.stockInDate)
}

const resetForm = (item?: StockInItem) => {
  Object.assign(form, item ? {
    code: item.code,
    stockInDate: item.stockInDate,
    description: item.description ?? '',
    items: item.items.map(line => ({ ...line })),
  } : { code: '', stockInDate: today(), description: '', items: [newLine()] })
  nextTick(() => formRef.value?.clearValidate())
}

const openCreateDialog = async () => {
  editingItem.value = null
  resetForm()
  dialogVisible.value = true
  try {
    await loadNextCode()
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock_in.code_preview_failed')), 'warning')
  }
}

const openEditDialog = (item: StockInItem) => {
  editingItem.value = item
  resetForm(item)
  dialogVisible.value = true
}

const addLine = () => form.items.push(newLine())
const removeLine = (index: number) => form.items.splice(index, 1)
const isProductSelected = (productId: number, currentIndex: number) => form.items.some(
  (line, index) => index !== currentIndex && line.productId === productId,
)

const validateLines = () => {
  if (!form.items.length || form.items.some(line => !line.productId || line.quantity <= 0)) {
    useNotification(t('stock_in.items_required'), 'error')
    return false
  }
  if (new Set(form.items.map(line => line.productId)).size !== form.items.length) {
    useNotification(t('stock_in.duplicate_product'), 'error')
    return false
  }
  return true
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || !validateLines()) return
  try {
    submitting.value = true
    const { error } = await supabase.rpc('save_stock_in', {
      p_id: editingItem.value?.id ?? null,
      p_stock_in_date: form.stockInDate,
      p_description: form.description,
      p_items: form.items.map(line => ({
        product_id: line.productId,
        quantity: line.quantity,
        note: line.note,
      })),
    })
    if (error) throw error
    useNotification(editingItem.value ? t('stock_in.updated') : t('stock_in.created'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) {
    useNotification(getErrorMessage(error, t('stock_in.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const deleteItem = async (item: StockInItem) => {
  try {
    await ElMessageBox.confirm(
      t('stock_in.confirm_delete', { code: item.code }),
      t('stock_in.delete_title'),
      { confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning' },
    )
    const { error } = await supabase.rpc('delete_stock_in', { p_id: item.id })
    if (error) throw error
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('stock_in.deleted'))
    await loadItems()
  } catch (error) {
    if (error === 'cancel' || error === 'close') return
    useNotification(getErrorMessage(error, t('stock_in.delete_failed')), 'error')
  }
}

const searchItems = () => { params.page = 1; loadItems() }
const handleLimitChange = () => { params.page = 1; loadItems() }

onMounted(() => {
  loadItems()
  loadProducts()
})
</script>
