<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('payment_method.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('payment_method.description') }}</p>
        </div>
        <div class="flex flex-col gap-2 sm:flex-row">
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('payment_method.search_placeholder')"
            class="sm:!w-[260px]"
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
        <el-table-column :label="t('columns.logo')" width="90" align="center">
          <template #default="{ row }">
            <el-image v-if="row.logoUrl" :src="row.logoUrl" fit="contain" class="h-11 w-11 rounded border border-slate-200" />
            <span v-else class="text-slate-400">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" :label="t('columns.name')" min-width="180" />
        <el-table-column prop="bankAccount" :label="t('columns.bank_account')" min-width="170">
          <template #default="{ row }">{{ row.bankAccount || '—' }}</template>
        </el-table-column>
        <el-table-column prop="merchantCity" :label="t('columns.merchant_city')" min-width="150" />
        <el-table-column prop="currency" :label="t('columns.currency')" width="110" align="center">
          <template #default="{ row }">{{ row.currency || '—' }}</template>
        </el-table-column>
        <el-table-column prop="storeLabel" :label="t('columns.store_label')" min-width="170">
          <template #default="{ row }">{{ row.storeLabel || '—' }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.payment_type')" width="125" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isCashed ? 'warning' : 'primary'">
              {{ row.isCashed ? t('payment_method.cash') : t('payment_method.non_cash') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.status')" width="105" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isActive ? 'success' : 'info'">{{ row.isActive ? t('active') : t('inactive') }}</el-tag>
          </template>
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

    <el-dialog v-model="dialogVisible" :title="editingItem ? t('payment_method.edit_title') : t('payment_method.create_title')" width="800px" align-center append-to-body>
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <div class="grid grid-cols-1 gap-x-4 sm:grid-cols-2">
          <el-form-item :label="t('columns.name')" prop="name">
            <el-input v-model="form.name" maxlength="255" />
          </el-form-item>
          <el-form-item :label="t('columns.bank_account')">
            <el-input v-model="form.bankAccount" maxlength="100" />
          </el-form-item>
          <el-form-item :label="t('columns.merchant_city')" prop="merchantCity">
            <el-input v-model="form.merchantCity" maxlength="100" />
          </el-form-item>
          <el-form-item :label="t('columns.currency')">
            <el-input v-model="form.currency" maxlength="10" placeholder="USD" />
          </el-form-item>
          <el-form-item :label="t('columns.store_label')">
            <el-input v-model="form.storeLabel" maxlength="255" />
          </el-form-item>
        </div>
        <div class="mb-4 flex flex-wrap gap-8">
          <el-form-item :label="t('columns.payment_type')" class="!mb-0">
            <el-switch v-model="form.isCashed" :active-text="t('payment_method.cash')" :inactive-text="t('payment_method.non_cash')" />
          </el-form-item>
          <el-form-item :label="t('columns.status')" class="!mb-0">
            <el-switch v-model="form.isActive" :active-text="t('active')" :inactive-text="t('inactive')" />
          </el-form-item>
        </div>
        <el-form-item :label="t('columns.logo')">
          <div class="flex w-full items-center gap-4">
            <el-image v-if="logoPreview" :src="logoPreview" fit="contain" class="h-24 w-24 rounded border border-slate-200" />
            <div v-else class="flex h-24 w-24 items-center justify-center rounded border border-dashed border-slate-300 text-slate-400">
              <Icon name="solar:gallery-outline" size="28" />
            </div>
            <div class="space-y-2">
              <el-upload accept="image/jpeg,image/png,image/webp,image/svg+xml" :auto-upload="false" :show-file-list="false" :on-change="handleLogoChange">
                <el-button>{{ t('payment_method.choose_logo') }}</el-button>
              </el-upload>
              <el-button v-if="logoPreview" type="danger" text @click="removeLogo">{{ t('payment_method.remove_logo') }}</el-button>
              <p class="text-xs text-slate-500">{{ t('payment_method.logo_help') }}</p>
            </div>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" :loading="submitting" @click="submit">{{ t('save') }}</el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules, UploadFile } from 'element-plus'

definePageMeta({ middleware: 'auth' })
useHead({ title: 'Payment Method | Fashion Store' })

interface PaymentMethod {
  id: number; name: string; logoPath: string | null; logoUrl: string | null
  bankAccount: string | null; merchantCity: string; currency: string | null
  storeLabel: string | null; isCashed: boolean; isActive: boolean
}
interface PaymentMethodRow {
  id: number; name: string; logo_path: string | null; bank_account: string | null
  merchant_city: string; currency: string | null; store_label: string | null
  is_cashed: boolean; is_active: boolean
}

const bucketName = 'fashion-images'
const maxLogoSize = 2 * 1024 * 1024
const pageSizes = [10, 20, 50, 100]
const { t } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const loading = ref(false)
const submitting = ref(false)
const items = ref<PaymentMethod[]>([])
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingItem = ref<PaymentMethod | null>(null)
const formRef = ref<FormInstance>()
const emptyForm = () => ({ name: '', bankAccount: '', merchantCity: '', currency: '', storeLabel: '', isCashed: true, isActive: true })
const form = reactive(emptyForm())
const logoFile = ref<File | null>(null)
const logoPreview = ref<string | null>(null)
const removeExistingLogo = ref(false)
const rules = computed<FormRules>(() => ({
  name: [{ required: true, message: t('payment_method.name_required'), trigger: 'blur' }],
  merchantCity: [{ required: true, message: t('payment_method.city_required'), trigger: 'blur' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('payment_method.title'))
  breadcrumbStore.setBreadcrumbs([t('sales'), t('payment_method.title')])
})

const errorMessage = (error: unknown, fallback: string) => typeof error === 'object' && error && 'message' in error
  ? String((error as { message?: string }).message || fallback) : fallback
const publicUrl = (path: string | null) => path ? supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl : null
const mapItem = (row: PaymentMethodRow): PaymentMethod => ({
  id: row.id, name: row.name, logoPath: row.logo_path, logoUrl: publicUrl(row.logo_path), bankAccount: row.bank_account,
  merchantCity: row.merchant_city, currency: row.currency, storeLabel: row.store_label, isCashed: row.is_cashed, isActive: row.is_active,
})

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase.from('payment_methods').select('*', { count: 'exact' }).order('created_at', { ascending: false }).range(from, from + params.limit - 1)
    if (search) query = query.or(`name.ilike.%${search}%,bank_account.ilike.%${search}%,store_label.ilike.%${search}%`)
    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as PaymentMethodRow[]).map(mapItem)
    meta.totalItems = count ?? 0
  } catch (error) { useNotification(errorMessage(error, t('payment_method.load_failed')), 'error') }
  finally { loading.value = false }
}

const resetForm = (item?: PaymentMethod) => {
  Object.assign(form, item ? {
    name: item.name, bankAccount: item.bankAccount ?? '', merchantCity: item.merchantCity,
    currency: item.currency ?? '', storeLabel: item.storeLabel ?? '', isCashed: item.isCashed, isActive: item.isActive,
  } : emptyForm())
  logoFile.value = null; logoPreview.value = item?.logoUrl ?? null; removeExistingLogo.value = false
  nextTick(() => formRef.value?.clearValidate())
}
const openCreateDialog = () => { editingItem.value = null; resetForm(); dialogVisible.value = true }
const openEditDialog = (item: PaymentMethod) => { editingItem.value = item; resetForm(item); dialogVisible.value = true }

const handleLogoChange = (uploadFile: UploadFile) => {
  const file = uploadFile.raw
  if (!file) return
  if (!['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'].includes(file.type)) { useNotification(t('payment_method.invalid_logo'), 'error'); return }
  if (file.size > maxLogoSize) { useNotification(t('payment_method.logo_too_large'), 'error'); return }
  if (logoPreview.value?.startsWith('blob:')) URL.revokeObjectURL(logoPreview.value)
  logoFile.value = file; logoPreview.value = URL.createObjectURL(file); removeExistingLogo.value = false
}
const removeLogo = () => {
  if (logoPreview.value?.startsWith('blob:')) URL.revokeObjectURL(logoPreview.value)
  logoFile.value = null; logoPreview.value = null; removeExistingLogo.value = true
}
const uploadLogo = async (file: File) => {
  const ext = file.name.split('.').pop()?.toLowerCase() || 'png'
  const path = `payment-methods/${crypto.randomUUID()}.${ext}`
  const { error } = await supabase.storage.from(bucketName).upload(path, file, { contentType: file.type, cacheControl: '3600' })
  if (error) throw error
  return path
}
const removeStoredLogo = async (path: string) => {
  const { error } = await supabase.storage.from(bucketName).remove([path]); if (error) throw error
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false); if (!valid) return
  let uploadedPath: string | null = null
  const oldPath = editingItem.value?.logoPath ?? null
  try {
    submitting.value = true
    if (logoFile.value) uploadedPath = await uploadLogo(logoFile.value)
    const logoPath = uploadedPath ?? (removeExistingLogo.value ? null : oldPath)
    const values = {
      name: form.name.trim(), logo_path: logoPath, bank_account: form.bankAccount.trim() || null,
      merchant_city: form.merchantCity.trim(), currency: form.currency.trim().toUpperCase() || null,
      store_label: form.storeLabel.trim() || null, is_cashed: form.isCashed, is_active: form.isActive,
      updated_at: new Date().toISOString(),
    }
    const { error } = editingItem.value
      ? await supabase.from('payment_methods').update(values).eq('id', editingItem.value.id)
      : await supabase.from('payment_methods').insert({ ...values, created_by_user_id: user.value?.id })
    if (error) throw error
    if (oldPath && oldPath !== logoPath) await removeStoredLogo(oldPath).catch(() => useNotification(t('payment_method.logo_cleanup_failed'), 'warning'))
    useNotification(editingItem.value ? t('payment_method.updated') : t('payment_method.created'))
    dialogVisible.value = false; await loadItems()
  } catch (error) {
    if (uploadedPath) await removeStoredLogo(uploadedPath).catch(() => undefined)
    useNotification(errorMessage(error, t('payment_method.save_failed')), 'error')
  } finally { submitting.value = false }
}

const deleteItem = async (item: PaymentMethod) => {
  try {
    await ElMessageBox.confirm(t('payment_method.confirm_delete', { name: item.name }), t('payment_method.delete_title'), {
      confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning',
    })
    const { error } = await supabase.from('payment_methods').delete().eq('id', item.id); if (error) throw error
    if (item.logoPath) await removeStoredLogo(item.logoPath).catch(() => useNotification(t('payment_method.logo_cleanup_failed'), 'warning'))
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('payment_method.deleted')); await loadItems()
  } catch (error) {
    if (error === 'cancel' || error === 'close') return
    useNotification(errorMessage(error, t('payment_method.delete_failed')), 'error')
  }
}
const searchItems = () => { params.page = 1; loadItems() }
const handleLimitChange = () => { params.page = 1; loadItems() }
onMounted(loadItems)
onBeforeUnmount(() => { if (logoPreview.value?.startsWith('blob:')) URL.revokeObjectURL(logoPreview.value) })
</script>
