<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('sale.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('sale.description') }}</p>
        </div>
        <div class="flex flex-col gap-2 sm:flex-row">
          <el-select
            v-model="params.status"
            class="sm:!w-[150px]"
            :placeholder="t('sale.all_statuses')"
            @change="filterItems"
          >
            <el-option :label="t('sale.all_statuses')" value="" />
            <el-option :label="t('sale.status_draft')" value="draft" />
            <el-option :label="t('sale.status_completed')" value="completed" />
          </el-select>
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('sale.search_placeholder')"
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
                <el-table-column :label="t('columns.unit_price')" width="130" align="right">
                  <template #default="scope">{{ formatMoney(scope.row.unitPrice) }}</template>
                </el-table-column>
                <el-table-column :label="t('columns.discount')" width="130" align="right">
                  <template #default="scope">{{ formatMoney(scope.row.discount) }}</template>
                </el-table-column>
                <el-table-column :label="t('columns.subtotal')" width="140" align="right">
                  <template #default="scope">{{ formatMoney(lineSubtotal(scope.row)) }}</template>
                </el-table-column>
              </el-table>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="code" :label="t('columns.code')" min-width="150" />
        <el-table-column prop="saleDate" :label="t('columns.sale_date')" min-width="150" />
        <el-table-column prop="paymentMethod.name" :label="t('columns.payment_method')" min-width="170" />
        <el-table-column :label="t('columns.status')" width="115" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'completed' ? 'success' : 'warning'">
              {{ t(`sale.status_${row.status}`) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.items')" width="100" align="right">
          <template #default="{ row }">{{ row.items.length }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.total_quantity')" width="150" align="right">
          <template #default="{ row }">{{ totalQuantity(row.items) }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.total_amount')" width="150" align="right">
          <template #default="{ row }">{{ formatMoney(totalAmount(row.items)) }}</template>
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
      :title="editingItem ? t('sale.edit_title') : t('sale.create_title')"
      fullscreen
      align-center
      append-to-body
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <div class="grid grid-cols-1 gap-x-4 sm:grid-cols-2">
          <el-form-item :label="t('columns.code')">
            <el-input v-model="form.code" readonly />
          </el-form-item>
          <el-form-item :label="t('columns.sale_date')" prop="saleDate">
            <el-date-picker
              v-model="form.saleDate"
              type="date"
              value-format="YYYY-MM-DD"
              :placeholder="t('sale.select_date')"
              class="!w-full"
              @change="refreshCodePreview"
            />
          </el-form-item>
          <el-form-item :label="t('columns.payment_method')" prop="paymentMethodId">
            <el-select v-model="form.paymentMethodId" filterable :placeholder="t('sale.select_payment_method')" class="w-full">
              <el-option v-for="method in paymentMethodOptions" :key="method.id" :value="method.id" :label="method.name" />
            </el-select>
          </el-form-item>
          <el-form-item :label="t('columns.status')" prop="status">
            <el-select v-model="form.status" class="w-full">
              <el-option :label="t('sale.status_draft')" value="draft" />
              <el-option :label="t('sale.status_completed')" value="completed" />
            </el-select>
          </el-form-item>
        </div>
        <el-form-item :label="t('columns.description')">
          <el-input v-model="form.description" type="textarea" :rows="2" maxlength="500" show-word-limit />
        </el-form-item>

        <div class="mb-3 flex items-center justify-between">
          <h3 class="font-semibold text-slate-900">{{ t('columns.items') }}</h3>
          <el-button type="primary" plain @click="addLine">
            <Icon name="solar:add-circle-outline" size="17" />
            <span class="ml-1">{{ t('sale.add_item') }}</span>
          </el-button>
        </div>

        <div class="space-y-3">
          <div
            v-for="(line, index) in form.items"
            :key="line.key"
            class="grid grid-cols-1 gap-3 rounded-md border border-slate-200 p-3 lg:grid-cols-[minmax(220px,1fr)_105px_115px_115px_115px_40px]"
          >
            <el-form-item :label="t('columns.product')" class="!mb-0">
              <el-select v-model="line.productId" filterable :placeholder="t('sale.select_product')" class="w-full">
                <el-option
                  v-for="product in productOptions"
                  :key="product.id"
                  :value="product.id"
                  :label="`${product.code || '—'} · ${productName(product)} · ${t('sale.available')}: ${availableForProduct(product.id)}`"
                  :disabled="isProductSelected(product.id, index) || availableForProduct(product.id) <= 0"
                />
              </el-select>
            </el-form-item>
            <el-form-item :label="t('columns.quantity')" class="!mb-0">
              <el-input-number
                v-model="line.quantity"
                :min="1"
                :max="maximumQuantity(line)"
                :precision="0"
                class="!w-full"
              />
            </el-form-item>
            <el-form-item :label="t('columns.unit_price')" class="!mb-0">
              <el-input :model-value="formatMoney(selectedProduct(line)?.unitPrice ?? line.unitPrice)" readonly />
            </el-form-item>
            <el-form-item :label="t('columns.discount')" class="!mb-0">
              <el-input :model-value="formatMoney(selectedProduct(line)?.discount ?? line.discount)" readonly />
            </el-form-item>
            <el-form-item :label="t('sale.available')" class="!mb-0">
              <el-input :model-value="line.productId ? availableForProduct(line.productId) : '—'" readonly />
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
useHead({ title: 'MINI-POS-SALE' })

type SaleStatus = 'draft' | 'completed'

interface ProductOption {
  id: string
  code: string | null
  nameEn: string
  nameKh: string
  unitPrice: number
  discount: number
  available: number
}

interface PaymentMethodOption { id: number; name: string }

interface SaleLine {
  id?: number
  key: string
  productId: string | null
  quantity: number
  unitPrice: number
  discount: number
  product?: ProductOption
}

interface SaleItem {
  id: number
  code: string
  saleDate: string
  paymentMethodId: number
  paymentMethod: PaymentMethodOption
  status: SaleStatus
  description: string | null
  items: SaleLine[]
}

interface SaleRow {
  id: number
  code: string
  sale_date: string
  payment_method_id: number
  status: SaleStatus
  payment_method: PaymentMethodOption
  description: string | null
  items: Array<{
    id: number
    product_id: string
    quantity: number
    unit_price: number
    discount: number
    product: { id: string; code: string | null; name_en: string; name_kh: string }
  }>
}

const pageSizes = [10, 20, 50, 100]
const saleSelect = 'id, code, sale_date, payment_method_id, description, status, payment_method:payment_methods(id, name), items:sale_items(id, product_id, quantity, unit_price, discount, product:products(id, code, name_en, name_kh))'
const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()

const loading = ref(false)
const submitting = ref(false)
const items = ref<SaleItem[]>([])
const productOptions = ref<ProductOption[]>([])
const paymentMethodOptions = ref<PaymentMethodOption[]>([])
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', status: '' as '' | SaleStatus, page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingItem = ref<SaleItem | null>(null)
const formRef = ref<FormInstance>()
const nextExpectedId = ref(1)

const newLine = (): SaleLine => ({
  key: crypto.randomUUID(),
  productId: null,
  quantity: 1,
  unitPrice: 0,
  discount: 0,
})

const today = () => new Date().toISOString().slice(0, 10)
const form = reactive({ code: '', saleDate: today(), paymentMethodId: null as number | null, status: 'draft' as SaleStatus, description: '', items: [newLine()] })
const rules = computed<FormRules>(() => ({
  saleDate: [{ required: true, message: t('sale.date_required'), trigger: 'change' }],
  paymentMethodId: [{ required: true, message: t('sale.payment_method_required'), trigger: 'change' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('sale.title'))
  breadcrumbStore.setBreadcrumbs([t('sales'), t('sale.title')])
})

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null && 'message' in error) {
    return String((error as { message?: string }).message || fallback)
  }
  return fallback
}

const productName = (product: ProductOption) => locale.value === 'km' ? product.nameKh : product.nameEn
const totalQuantity = (lines: SaleLine[]) => lines.reduce((sum, line) => sum + line.quantity, 0)
const selectedProduct = (line: SaleLine) => productOptions.value.find(product => product.id === line.productId)
const lineSubtotal = (line: SaleLine) => line.quantity * Math.max(0, line.unitPrice - line.discount)
const totalAmount = (lines: SaleLine[]) => lines.reduce((sum, line) => sum + lineSubtotal(line), 0)
const formatMoney = (value: number) => new Intl.NumberFormat(locale.value === 'km' ? 'km-KH' : 'en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value)

const formatCode = (id: number, date: string) => {
  const year = date?.slice(2, 4) || new Date().getFullYear().toString().slice(-2)
  return `SAL${year}${String(id).padStart(6, '0')}`
}

const mapRow = (row: SaleRow): SaleItem => ({
  id: row.id,
  code: row.code,
  saleDate: row.sale_date,
  paymentMethodId: row.payment_method_id,
  paymentMethod: row.payment_method,
  status: row.status,
  description: row.description,
  items: (row.items ?? []).map(line => ({
    id: line.id,
    key: String(line.id),
    productId: line.product_id,
    quantity: line.quantity,
    unitPrice: Number(line.unit_price),
    discount: Number(line.discount),
    product: {
      id: line.product.id,
      code: line.product.code,
      nameEn: line.product.name_en,
      nameKh: line.product.name_kh,
      unitPrice: Number(line.unit_price),
      discount: Number(line.discount),
      available: 0,
    },
  })),
})

const loadProducts = async () => {
  const { data, error } = await supabase.from('products').select('id, code, name_en, name_kh, unit_price, discount, stock:stocks(stock_in, stock_out, stock_adjustment)').order('name_en')
  if (error) {
    useNotification(getErrorMessage(error, t('sale.load_products_failed')), 'error')
    return
  }
  productOptions.value = (data ?? []).map((row: any) => ({
    id: row.id as number,
    code: row.code as string | null,
    nameEn: row.name_en as string,
    nameKh: row.name_kh as string,
    unitPrice: Number(row.unit_price),
    discount: Number(row.discount ?? 0),
    available: Number(row.stock?.stock_in ?? 0) + Number(row.stock?.stock_adjustment ?? 0) - Number(row.stock?.stock_out ?? 0),
  }))
}

const loadPaymentMethods = async () => {
  const { data, error } = await supabase.from('payment_methods').select('id, name').eq('is_active', true).order('name')
  if (error) {
    useNotification(getErrorMessage(error, t('sale.load_payment_methods_failed')), 'error')
    return
  }
  paymentMethodOptions.value = (data ?? []).map(row => ({ id: Number(row.id), name: String(row.name) }))
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase.from('sales').select(saleSelect, { count: 'exact' })
      .order('sale_date', { ascending: false }).order('id', { ascending: false })
      .range(from, from + params.limit - 1)
    if (search) query = query.or(`code.ilike.%${search}%,description.ilike.%${search}%`)
    if (params.status) query = query.eq('status', params.status)
    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as unknown as SaleRow[]).map(mapRow)
    meta.totalItems = count ?? 0
  } catch (error) {
    useNotification(getErrorMessage(error, t('sale.load_failed')), 'error')
  } finally {
    loading.value = false
  }
}

const loadNextCode = async () => {
  const { data, error } = await supabase.from('sales').select('id').order('id', { ascending: false }).limit(1)
  if (error) throw error
  nextExpectedId.value = Number(data?.[0]?.id ?? 0) + 1
  form.code = formatCode(nextExpectedId.value, form.saleDate)
}

const refreshCodePreview = () => {
  if (!editingItem.value) form.code = formatCode(nextExpectedId.value, form.saleDate)
}

const resetForm = (item?: SaleItem) => {
  Object.assign(form, item ? {
    code: item.code,
    saleDate: item.saleDate,
    paymentMethodId: item.paymentMethodId,
    status: item.status,
    description: item.description ?? '',
    items: item.items.map(line => ({ ...line })),
  } : { code: '', saleDate: today(), paymentMethodId: null, status: 'draft', description: '', items: [newLine()] })
  nextTick(() => formRef.value?.clearValidate())
}

const openCreateDialog = async () => {
  editingItem.value = null
  resetForm()
  dialogVisible.value = true
  try {
    await loadNextCode()
  } catch (error) {
    useNotification(getErrorMessage(error, t('sale.code_preview_failed')), 'warning')
  }
}

const openEditDialog = (item: SaleItem) => {
  editingItem.value = item
  resetForm(item)
  dialogVisible.value = true
}

const addLine = () => form.items.push(newLine())
const removeLine = (index: number) => form.items.splice(index, 1)
const isProductSelected = (productId: string, currentIndex: number) => form.items.some(
  (line, index) => index !== currentIndex && line.productId === productId,
)
const originalCompletedQuantity = (productId: string) => {
  if (editingItem.value?.status !== 'completed') return 0
  return editingItem.value.items.find(line => line.productId === productId)?.quantity ?? 0
}
const availableForProduct = (productId: string) => {
  const product = productOptions.value.find(option => option.id === productId)
  return Math.max(0, (product?.available ?? 0) + originalCompletedQuantity(productId))
}
const maximumQuantity = (line: SaleLine) => line.productId ? availableForProduct(line.productId) : 1

const validateLines = () => {
  if (!form.items.length || form.items.some(line => !line.productId || line.quantity <= 0)) {
    useNotification(t('sale.items_required'), 'error')
    return false
  }
  if (new Set(form.items.map(line => line.productId)).size !== form.items.length) {
    useNotification(t('sale.duplicate_product'), 'error')
    return false
  }
  if (form.items.some(line => line.productId && line.quantity > availableForProduct(line.productId))) {
    useNotification(t('sale.quantity_exceeds_stock'), 'error')
    return false
  }
  return true
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || !validateLines()) return
  try {
    submitting.value = true
    const { error } = await supabase.rpc('save_sale', {
      p_id: editingItem.value?.id ?? null,
      p_sale_date: form.saleDate,
      p_payment_method_id: form.paymentMethodId,
      p_status: form.status,
      p_description: form.description,
      p_items: form.items.map(line => ({
        product_id: line.productId,
        quantity: line.quantity,
      })),
    })
    if (error) throw error
    useNotification(editingItem.value ? t('sale.updated') : t('sale.created'))
    dialogVisible.value = false
    await Promise.all([loadItems(), loadProducts()])
  } catch (error) {
    useNotification(getErrorMessage(error, t('sale.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const deleteItem = async (item: SaleItem) => {
  try {
    await ElMessageBox.confirm(
      t('sale.confirm_delete', { code: item.code }),
      t('sale.delete_title'),
      { confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning' },
    )
    const { error } = await supabase.rpc('delete_sale', { p_id: item.id })
    if (error) throw error
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('sale.deleted'))
    await Promise.all([loadItems(), loadProducts()])
  } catch (error) {
    if (error === 'cancel' || error === 'close') return
    useNotification(getErrorMessage(error, t('sale.delete_failed')), 'error')
  }
}

const searchItems = () => { params.page = 1; loadItems() }
const filterItems = () => { params.page = 1; loadItems() }
const handleLimitChange = () => { params.page = 1; loadItems() }

onMounted(() => {
  loadItems()
  loadProducts()
  loadPaymentMethods()
})
</script>
