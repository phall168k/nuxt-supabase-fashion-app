<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('banner.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('banner.description') }}</p>
        </div>
        <div class="flex flex-col gap-2 sm:flex-row">
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('banner.search_placeholder')"
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
        <el-table-column :label="t('columns.thumbnail')" width="150" align="center">
          <template #default="{ row }">
            <el-image
              :src="row.thumbnailUrl"
              :preview-src-list="[row.thumbnailUrl]"
              preview-teleported
              fit="cover"
              class="h-16 w-28 rounded border border-slate-200"
            />
          </template>
        </el-table-column>
        <el-table-column prop="title" :label="t('columns.title')" min-width="220" />
        <el-table-column :label="t('columns.product')" min-width="220">
          <template #default="{ row }">
            {{ row.product.code }} · {{ productName(row.product) }}
          </template>
        </el-table-column>
        <el-table-column prop="description" :label="t('columns.description')" min-width="260" show-overflow-tooltip>
          <template #default="{ row }">{{ row.description || '—' }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.status')" width="110" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isActive ? 'success' : 'info'">
              {{ row.isActive ? t('active') : t('inactive') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.created_at')" min-width="180">
          <template #default="{ row }">{{ displayDate(row.createdAt) }}</template>
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
      :title="editingItem ? t('banner.edit_title') : t('banner.create_title')"
      width="800px"
      align-center
      append-to-body
      draggable
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-form-item :label="t('columns.title')" prop="title">
          <el-input v-model="form.title" maxlength="255" show-word-limit />
        </el-form-item>
        <el-form-item :label="t('columns.product')" prop="productId">
          <el-select v-model="form.productId" filterable :placeholder="t('banner.select_product')" class="w-full">
            <el-option
              v-for="product in productOptions"
              :key="product.id"
              :value="product.id"
              :label="`${product.code} · ${productName(product)}`"
            />
          </el-select>
        </el-form-item>
        <el-form-item :label="t('columns.description')">
          <el-input v-model="form.description" type="textarea" :rows="3" maxlength="1000" show-word-limit />
        </el-form-item>
        <el-form-item :label="t('columns.status')">
          <el-switch v-model="form.isActive" :active-text="t('active')" :inactive-text="t('inactive')" />
        </el-form-item>
        <el-form-item :label="t('columns.thumbnail')" required>
          <div class="w-full space-y-3">
            <el-image
              v-if="thumbnailPreview"
              :src="thumbnailPreview"
              fit="cover"
              class="h-40 w-full rounded-md border border-slate-200"
            />
            <el-upload
              accept="image/jpeg,image/png,image/webp,image/gif"
              :auto-upload="false"
              :show-file-list="false"
              :on-change="handleThumbnailChange"
            >
              <el-button>{{ t('banner.choose_image') }}</el-button>
            </el-upload>
            <p class="text-xs text-slate-500">{{ t('banner.image_help') }}</p>
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
useHead({ title: 'MINI-POS-BANNER' })

interface ProductOption { id: string; code: string; nameEn: string; nameKh: string }
interface Banner {
  id: number
  title: string
  description: string | null
  thumbnailPath: string
  thumbnailUrl: string
  productId: string
  product: ProductOption
  isActive: boolean
  createdAt: string
}
interface BannerRow {
  id: number
  title: string
  description: string | null
  thumbnail_path: string
  product_id: string
  is_active: boolean
  created_at: string
  product: { id: string; code: string; name_en: string; name_kh: string }
}

const bucketName = 'fashion-images'
const maxImageSize = 5 * 1024 * 1024
const pageSizes = [10, 20, 50, 100]
const bannerSelect = 'id, title, description, thumbnail_path, product_id, is_active, created_at, product:products(id, code, name_en, name_kh)'
const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const loading = ref(false)
const submitting = ref(false)
const items = ref<Banner[]>([])
const productOptions = ref<ProductOption[]>([])
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingItem = ref<Banner | null>(null)
const formRef = ref<FormInstance>()
const form = reactive({ title: '', description: '', productId: null as string | null, isActive: true })
const thumbnailFile = ref<File | null>(null)
const thumbnailPreview = ref<string | null>(null)

const rules = computed<FormRules>(() => ({
  title: [{ required: true, message: t('banner.title_required'), trigger: 'blur' }],
  productId: [{ required: true, message: t('banner.product_required'), trigger: 'change' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('banner.title'))
  breadcrumbStore.setBreadcrumbs([t('website_content'), t('banner.title')])
})

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null && 'message' in error) {
    return String((error as { message?: string }).message || fallback)
  }
  return fallback
}

const publicUrl = (path: string) => supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl
const productName = (product: ProductOption) => locale.value === 'km' ? product.nameKh : product.nameEn
const mapBanner = (row: BannerRow): Banner => ({
  id: row.id,
  title: row.title,
  description: row.description,
  thumbnailPath: row.thumbnail_path,
  thumbnailUrl: publicUrl(row.thumbnail_path),
  productId: row.product_id,
  isActive: row.is_active,
  createdAt: row.created_at,
  product: { id: row.product.id, code: row.product.code, nameEn: row.product.name_en, nameKh: row.product.name_kh },
})

const displayDate = (value: string) => new Intl.DateTimeFormat(locale.value, {
  year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit',
}).format(new Date(value))

const loadProducts = async () => {
  const { data, error } = await supabase.from('products').select('id, code, name_en, name_kh').order('name_en')
  if (error) {
    useNotification(getErrorMessage(error, t('banner.load_products_failed')), 'error')
    return
  }
  productOptions.value = (data ?? []).map(row => ({
    id: row.id as number, code: row.code as string, nameEn: row.name_en as string, nameKh: row.name_kh as string,
  }))
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase.from('banners').select(bannerSelect, { count: 'exact' })
      .order('created_at', { ascending: false }).range(from, from + params.limit - 1)
    if (search) query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`)
    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as unknown as BannerRow[]).map(mapBanner)
    meta.totalItems = count ?? 0
  } catch (error) {
    useNotification(getErrorMessage(error, t('banner.load_failed')), 'error')
  } finally {
    loading.value = false
  }
}

const resetForm = (item?: Banner) => {
  Object.assign(form, item ? {
    title: item.title, description: item.description ?? '', productId: item.productId, isActive: item.isActive,
  } : { title: '', description: '', productId: null, isActive: true })
  thumbnailFile.value = null
  thumbnailPreview.value = item?.thumbnailUrl ?? null
  nextTick(() => formRef.value?.clearValidate())
}

const openCreateDialog = () => { editingItem.value = null; resetForm(); dialogVisible.value = true }
const openEditDialog = (item: Banner) => { editingItem.value = item; resetForm(item); dialogVisible.value = true }

const handleThumbnailChange = (uploadFile: UploadFile) => {
  const file = uploadFile.raw
  if (!file) return
  if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
    useNotification(t('banner.invalid_image_type'), 'error'); return
  }
  if (file.size > maxImageSize) { useNotification(t('banner.image_too_large'), 'error'); return }
  if (thumbnailPreview.value?.startsWith('blob:')) URL.revokeObjectURL(thumbnailPreview.value)
  thumbnailFile.value = file
  thumbnailPreview.value = URL.createObjectURL(file)
}

const uploadThumbnail = async (file: File) => {
  const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const path = `banners/${crypto.randomUUID()}.${extension}`
  const { error } = await supabase.storage.from(bucketName).upload(path, file, {
    contentType: file.type, cacheControl: '3600', upsert: false,
  })
  if (error) throw error
  return path
}

const removeImage = async (path: string) => {
  const { error } = await supabase.storage.from(bucketName).remove([path])
  if (error) throw error
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || !form.productId) return
  if (!thumbnailFile.value && !editingItem.value?.thumbnailPath) {
    useNotification(t('banner.thumbnail_required'), 'error'); return
  }

  let uploadedPath: string | null = null
  try {
    submitting.value = true
    if (thumbnailFile.value) uploadedPath = await uploadThumbnail(thumbnailFile.value)
    const thumbnailPath = uploadedPath ?? editingItem.value?.thumbnailPath
    const values = {
      title: form.title.trim(), description: form.description.trim() || null,
      product_id: form.productId, is_active: form.isActive,
      thumbnail_path: thumbnailPath, updated_at: new Date().toISOString(),
    }
    const { error } = editingItem.value
      ? await supabase.from('banners').update(values).eq('id', editingItem.value.id)
      : await supabase.from('banners').insert({ ...values, created_by_user_id: user.value?.id })
    if (error) throw error
    if (uploadedPath && editingItem.value?.thumbnailPath) {
      await removeImage(editingItem.value.thumbnailPath).catch(() => useNotification(t('banner.image_cleanup_failed'), 'warning'))
    }
    useNotification(editingItem.value ? t('banner.updated') : t('banner.created'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) {
    if (uploadedPath) await removeImage(uploadedPath).catch(() => undefined)
    useNotification(getErrorMessage(error, t('banner.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const deleteItem = async (item: Banner) => {
  try {
    await ElMessageBox.confirm(t('banner.confirm_delete', { title: item.title }), t('banner.delete_title'), {
      confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning',
    })
    const { error } = await supabase.from('banners').delete().eq('id', item.id)
    if (error) throw error
    await removeImage(item.thumbnailPath).catch(() => useNotification(t('banner.image_cleanup_failed'), 'warning'))
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('banner.deleted'))
    await loadItems()
  } catch (error) {
    if (error === 'cancel' || error === 'close') return
    useNotification(getErrorMessage(error, t('banner.delete_failed')), 'error')
  }
}

const searchItems = () => { params.page = 1; loadItems() }
const handleLimitChange = () => { params.page = 1; loadItems() }

onMounted(() => { loadItems(); loadProducts() })
onBeforeUnmount(() => {
  if (thumbnailPreview.value?.startsWith('blob:')) URL.revokeObjectURL(thumbnailPreview.value)
})
</script>
