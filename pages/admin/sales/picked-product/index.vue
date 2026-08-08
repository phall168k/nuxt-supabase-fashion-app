<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('picked_product.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('picked_product.description') }}</p>
        </div>
        <el-button type="primary" @click="openCreateDialog">
          <Icon name="solar:add-circle-outline" size="18" />
          <span class="ml-1">{{ t('create') }}</span>
        </el-button>
      </div>

      <el-table v-loading="loading" :data="items" stripe row-key="id" class="w-full">
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column :label="t('columns.thumbnail')" width="90" align="center">
          <template #default="{ row }">
            <el-image v-if="row.product.thumbnailUrl" :src="row.product.thumbnailUrl" fit="cover" class="h-11 w-11 rounded border" />
            <span v-else class="text-slate-400">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="product.code" :label="t('columns.code')" min-width="130" />
        <el-table-column :label="t('columns.product')" min-width="220">
          <template #default="{ row }">{{ productName(row.product) }}</template>
        </el-table-column>
        <el-table-column prop="quantity" :label="t('columns.quantity')" width="120" align="right" />
        <el-table-column :label="t('columns.picked_by')" min-width="190">
          <template #default="{ row }">{{ pickerLabel(row.pickedById) }}</template>
        </el-table-column>
        <el-table-column prop="createdAt" :label="t('columns.created_at')" min-width="180">
          <template #default="{ row }">{{ displayDate(row.createdAt) }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.action')" fixed="right" width="140" align="center">
          <template #default="{ row }">
            <div class="flex justify-center gap-2">
              <el-button type="success" circle @click="openEditDialog(row)"><Icon name="solar:pen-2-outline" size="17" /></el-button>
              <el-button type="danger" circle @click="deleteItem(row)"><Icon name="solar:trash-bin-trash-outline" size="17" /></el-button>
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
        <el-pagination v-model:current-page="params.page" background layout="prev, pager, next" :page-size="params.limit" :total="meta.totalItems" @current-change="loadItems" />
      </div>
    </div>

    <el-dialog v-model="dialogVisible" :title="editingItem ? t('picked_product.edit_title') : t('picked_product.create_title')" width="560px" align-center append-to-body>
      <el-form id="picked-product-form" ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
        <el-form-item :label="t('columns.product')" prop="productId">
          <el-select v-model="form.productId" filterable :disabled="Boolean(editingItem)" :placeholder="t('picked_product.select_product')" class="w-full" @change="clampQuantity">
            <el-option
              v-for="product in productOptions"
              :key="product.id"
              :value="product.id"
              :label="`${product.code} · ${productName(product)} · ${t('picked_product.available')}: ${product.available}`"
              :disabled="product.available <= 0 || (!editingItem && pickedProductIds.has(product.id))"
            />
          </el-select>
        </el-form-item>
        <el-form-item :label="t('columns.quantity')" prop="quantity">
          <el-input-number v-model="form.quantity" :min="1" :max="selectedProduct?.available ?? 1" :precision="0" class="!w-full" />
          <p v-if="selectedProduct" class="mt-1 text-xs text-slate-500">{{ t('picked_product.stock_help', { count: selectedProduct.available }) }}</p>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" native-type="submit" form="picked-product-form" :loading="submitting">{{ t('save') }}</el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules } from 'element-plus'

definePageMeta({ middleware: 'auth' })
useHead({ title: 'MINI-POS-PICKED-PRODUCT' })

interface ProductOption { id: number; code: string; nameEn: string; nameKh: string; available: number; thumbnailUrl: string | null }
interface PickedItem { id: number; productId: number; quantity: number; pickedById: string; createdAt: string; product: ProductOption }
interface PickedRow {
  id: number; product_id: number; quantity: number; picked_by_id: string; created_at: string
  product: { id: number; code: string; name_en: string; name_kh: string; stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null; images: Array<{ image_path: string; is_active: boolean; sort_order: number }> }
}

const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const bucketName = 'fashion-images'
const pageSizes = [10, 20, 50, 100]
const pickedSelect = 'id, product_id, quantity, picked_by_id, created_at, product:products!inner(id, code, name_en, name_kh, stock:stocks(stock_in, stock_out, stock_adjustment), images:product_images(image_path, is_active, sort_order))'

const loading = ref(false)
const submitting = ref(false)
const items = ref<PickedItem[]>([])
const productOptions = ref<ProductOption[]>([])
const params = reactive({ page: 1, limit: 10 })
const meta = reactive({ totalItems: 0 })
const dialogVisible = ref(false)
const editingItem = ref<PickedItem | null>(null)
const formRef = ref<FormInstance>()
const form = reactive({ productId: null as number | null, quantity: 1 })

const rules = computed<FormRules>(() => ({
  productId: [{ required: true, message: t('picked_product.product_required'), trigger: 'change' }],
  quantity: [{ required: true, message: t('picked_product.quantity_required'), trigger: 'change' }],
}))
const selectedProduct = computed(() => productOptions.value.find(product => product.id === form.productId))
const pickedProductIds = computed(() => new Set(
  items.value.filter(item => item.pickedById === user.value?.id).map(item => item.productId),
))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('picked_product.title'))
  breadcrumbStore.setBreadcrumbs([t('sales'), t('picked_product.title')])
})

const productName = (product: ProductOption) => locale.value === 'km' ? product.nameKh : product.nameEn
const publicUrl = (path: string) => supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl
const pickerLabel = (id: string) => id === user.value?.id ? t('picked_product.you') : `${id.slice(0, 8)}…`
const displayDate = (value: string) => new Intl.DateTimeFormat(locale.value, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
const errorMessage = (error: unknown, fallback: string) => typeof error === 'object' && error && 'message' in error ? String((error as { message?: string }).message || fallback) : fallback
const mapProduct = (row: PickedRow['product']): ProductOption => {
  const image = [...(row.images ?? [])].filter(item => item.is_active).sort((a, b) => a.sort_order - b.sort_order)[0]
  return {
    id: row.id, code: row.code, nameEn: row.name_en, nameKh: row.name_kh,
    available: Math.max(0, Number(row.stock?.stock_in ?? 0) + Number(row.stock?.stock_adjustment ?? 0) - Number(row.stock?.stock_out ?? 0)),
    thumbnailUrl: image ? publicUrl(image.image_path) : null,
  }
}

const loadProducts = async () => {
  const { data, error } = await supabase.from('products').select('id, code, name_en, name_kh, stock:stocks(stock_in, stock_out, stock_adjustment), images:product_images(image_path, is_active, sort_order)').order('name_en')
  if (error) { useNotification(errorMessage(error, t('picked_product.load_products_failed')), 'error'); return }
  productOptions.value = ((data ?? []) as unknown as PickedRow['product'][]).map(mapProduct)
}
const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const { data, count, error } = await supabase.from('picked_products').select(pickedSelect, { count: 'exact' }).order('created_at', { ascending: false }).range(from, from + params.limit - 1)
    if (error) throw error
    items.value = ((data ?? []) as unknown as PickedRow[]).map(row => ({ id: row.id, productId: row.product_id, quantity: row.quantity, pickedById: row.picked_by_id, createdAt: row.created_at, product: mapProduct(row.product) }))
    meta.totalItems = count ?? 0
  } catch (error) { useNotification(errorMessage(error, t('picked_product.load_failed')), 'error') }
  finally { loading.value = false }
}

const resetForm = (item?: PickedItem) => { form.productId = item?.productId ?? null; form.quantity = item?.quantity ?? 1; nextTick(() => formRef.value?.clearValidate()) }
const openCreateDialog = () => { editingItem.value = null; resetForm(); dialogVisible.value = true }
const openEditDialog = (item: PickedItem) => { editingItem.value = item; resetForm(item); dialogVisible.value = true }
const clampQuantity = () => { if (selectedProduct.value && form.quantity > selectedProduct.value.available) form.quantity = Math.max(1, selectedProduct.value.available) }

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || !form.productId || !selectedProduct.value) return
  if (form.quantity > selectedProduct.value.available) { useNotification(t('picked_product.quantity_exceeds_stock'), 'error'); return }
  try {
    submitting.value = true
    const values = { product_id: form.productId, quantity: form.quantity, updated_at: new Date().toISOString() }
    const { error } = editingItem.value
      ? await supabase.from('picked_products').update(values).eq('id', editingItem.value.id)
      : await supabase.from('picked_products').insert({ ...values, picked_by_id: user.value?.id })
    if (error) throw error
    useNotification(editingItem.value ? t('picked_product.updated') : t('picked_product.created'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) { useNotification(errorMessage(error, t('picked_product.save_failed')), 'error') }
  finally { submitting.value = false }
}

const deleteItem = async (item: PickedItem) => {
  try {
    await ElMessageBox.confirm(t('picked_product.confirm_delete', { product: productName(item.product) }), t('picked_product.delete_title'), { confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning' })
    const { error } = await supabase.from('picked_products').delete().eq('id', item.id)
    if (error) throw error
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('picked_product.deleted'))
    await loadItems()
  } catch (error) { if (error !== 'cancel' && error !== 'close') useNotification(errorMessage(error, t('picked_product.delete_failed')), 'error') }
}
const handleLimitChange = () => { params.page = 1; loadItems() }
onMounted(() => { loadItems(); loadProducts() })
</script>
