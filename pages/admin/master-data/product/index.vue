<template>
  <section class="space-y-5">
    <div class="rounded-md border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-900">{{ t('product.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('product.description') }}</p>
        </div>

        <div class="flex flex-col gap-2 sm:flex-row sm:items-center">
          <el-input
            v-model="params.search"
            clearable
            :placeholder="t('product.search_placeholder')"
            class="sm:!w-[260px]"
            @keydown.enter="searchItems"
            @clear="searchItems"
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

      <el-table v-loading="loading" :data="items" stripe class="w-full" row-key="id">
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column :label="t('columns.thumbnail')" width="100" align="center">
          <template #default="{ row }">
            <div v-if="row.thumbnailUrls.length" class="relative inline-flex">
            <el-image
              :src="row.thumbnailUrls[0]"
              :preview-src-list="row.thumbnailUrls"
              preview-teleported
              fit="cover"
              class="h-12 w-12 rounded border border-slate-200"
            />
              <span v-if="row.thumbnailUrls.length > 1" class="absolute -right-2 -top-2 rounded-full bg-slate-700 px-1.5 text-[10px] text-white">
                +{{ row.thumbnailUrls.length - 1 }}
              </span>
            </div>
            <span v-else class="text-slate-400">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="code" :label="t('columns.code')" min-width="130" />
        <el-table-column prop="nameEn" :label="t('columns.name_en')" min-width="190" />
        <el-table-column prop="nameKh" :label="t('columns.name_kh')" min-width="190" />
        <el-table-column :label="t('columns.category')" min-width="190">
          <template #default="{ row }">
            {{ categoryLabel(row.category) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.unit_price')" width="140" align="right">
          <template #default="{ row }">
            {{ formatPrice(row.unitPrice) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.discount')" width="120" align="right">
          <template #default="{ row }">
            {{ formatDiscount(row.discount) }}
          </template>
        </el-table-column>
        <el-table-column :label="t('columns.created_at')" min-width="180">
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
      :title="editingItem ? t('product.edit_title') : t('product.create_title')"
      width="800px"
      align-center
      append-to-body
      destroy-on-close
      draggable
    >
      <el-form
        id="product-form"
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent="submit"
      >
        <el-form-item :label="t('columns.category')" prop="categoryId">
          <el-cascader
            v-model="form.categoryId"
            :options="categoryCascaderOptions"
            :props="categoryCascaderProps"
            :placeholder="t('product.select_category')"
            :loading="loadingCategories"
            filterable
            clearable
            class="w-full"
          />
        </el-form-item>
        <el-form-item :label="t('columns.code')">
          <el-input
            v-model="form.code"
            :placeholder="t('product.code_auto_generated')"
            readonly
          >
            <template #prefix>
              <Icon name="solar:hashtag-outline" />
            </template>
          </el-input>
          <p v-if="!editingItem" class="mt-1 text-xs text-slate-500">
            {{ t('product.code_auto_generated_help') }}
          </p>
        </el-form-item>
        <el-form-item :label="t('columns.name_en')" prop="nameEn">
          <el-input v-model="form.nameEn" :placeholder="t('columns.name_en')" />
        </el-form-item>
        <el-form-item :label="t('columns.name_kh')" prop="nameKh">
          <el-input v-model="form.nameKh" :placeholder="t('columns.name_kh')" />
        </el-form-item>
        <el-form-item :label="t('columns.unit_price')" prop="unitPrice">
          <el-input-number
            v-model="form.unitPrice"
            :min="0"
            :precision="2"
            step="any"
            controls-position="right"
            class="!w-full"
          />
        </el-form-item>
        <el-form-item :label="t('columns.discount')" prop="discount">
          <el-input-number
            v-model="form.discount"
            :min="0"
            :max="form.unitPrice"
            :precision="2"
            step="any"
            controls-position="right"
            class="!w-full"
          />
        </el-form-item>
        <el-form-item :label="t('columns.thumbnail')">
          <div class="w-full space-y-3">
            <div v-if="imagePreviews.length" class="flex flex-wrap gap-3">
              <div v-for="preview in imagePreviews" :key="preview.key" class="relative">
                <el-image :src="preview.url" fit="cover" class="h-24 w-24 rounded-md border border-slate-200" />
                <div class="mt-1 flex justify-center">
                  <el-radio v-model="activeImageKey" :value="preview.key" size="small">
                    {{ t('product.use_as_thumbnail') }}
                  </el-radio>
                </div>
                <el-button
                  type="danger"
                  circle
                  size="small"
                  class="!absolute -right-2 -top-2"
                  @click="removeThumbnail(preview)"
                >
                  <Icon name="solar:close-circle-outline" size="15" />
                </el-button>
              </div>
            </div>
            <div class="space-y-2">
              <el-upload
                accept="image/jpeg,image/png,image/webp,image/gif"
                :auto-upload="false"
                :show-file-list="false"
                multiple
                :on-change="handleThumbnailChange"
              >
                <el-button>{{ t('product.choose_images') }}</el-button>
              </el-upload>
              <p class="text-xs text-slate-500">{{ t('product.image_help') }}</p>
            </div>
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" native-type="submit" form="product-form" :loading="submitting">
          {{ t('save') }}
        </el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules, UploadFile } from 'element-plus'

definePageMeta({ middleware: 'auth' })
useHead({ title: 'MINI-POS-PRODUCT' })

interface CategoryOption {
  id: number
  nameEn: string
  nameKh: string
  parentId: number | null
}

interface CategoryCascaderOption {
  value: number
  label: string
  children?: CategoryCascaderOption[]
}

interface Product {
  id: string
  categoryId: number
  code: string
  nameEn: string
  nameKh: string
  unitPrice: number
  discount: number
  createdByUserId: string | null
  images: ProductImage[]
  thumbnailPaths: string[]
  thumbnailUrls: string[]
  createdAt: string | null
  category: CategoryOption | null
}

interface ProductRow {
  id: string
  category_id: number
  code: string
  name_en: string
  name_kh: string
  unit_price: number | string
  discount: number | string
  created_by_user_id: string | null
  images: Array<{
    id: number
    image_path: string
    is_active: boolean
    sort_order: number
  }>
  created_at: string | null
  category: { id: number; name_en: string; name_kh: string } | null
}

interface ProductImage {
  id: number
  path: string
  isActive: boolean
  sortOrder: number
  url: string
}

const bucketName = 'fashion-images'
const pageSizes = [10, 20, 50, 100]
const maxImageSize = 5 * 1024 * 1024
const productSelect = 'id, category_id, code, name_en, name_kh, unit_price, discount, created_by_user_id, created_at, category:categories(id, name_en, name_kh), images:product_images(id, image_path, is_active, sort_order)'

const { t, locale } = useI18n()
const breadcrumbStore = useBreadcrumbStore()
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const loading = ref(false)
const loadingCategories = ref(false)
const submitting = ref(false)
const items = ref<Product[]>([])
const categoryOptions = ref<CategoryOption[]>([])
const categoryCascaderProps = {
  emitPath: false,
  checkStrictly: true,
  value: 'value',
  label: 'label',
  children: 'children',
}
const categoryCascaderOptions = computed<CategoryCascaderOption[]>(() => {
  const childrenByParent = new Map<number, CategoryOption[]>()

  for (const category of categoryOptions.value) {
    if (category.parentId === null) continue
    const children = childrenByParent.get(category.parentId) ?? []
    children.push(category)
    childrenByParent.set(category.parentId, children)
  }

  const toOption = (category: CategoryOption): CategoryCascaderOption => {
    const children = childrenByParent.get(category.id) ?? []
    return {
      value: category.id,
      label: locale.value === 'km' ? category.nameKh : category.nameEn,
      ...(children.length ? { children: children.map(toOption) } : {}),
    }
  }

  return categoryOptions.value
    .filter(category => category.parentId === null)
    .map(toOption)
})
const meta = reactive({ totalItems: 0 })
const params = reactive({ search: '', page: 1, limit: 10 })

const formRef = ref<FormInstance>()
const dialogVisible = ref(false)
const editingItem = ref<Product | null>(null)
interface ImagePreview {
  key: string
  url: string
  id?: number
  path?: string
  file?: File
}
const imagePreviews = ref<ImagePreview[]>([])
const activeImageKey = ref<string | null>(null)

const emptyForm = () => ({
  categoryId: null as number | null,
  code: '',
  nameEn: '',
  nameKh: '',
  unitPrice: 0,
  discount: 0,
})
const form = reactive(emptyForm())

const rules = computed<FormRules>(() => ({
  categoryId: [{ required: true, message: t('product.category_required'), trigger: 'change' }],
  nameEn: [{ required: true, message: t('product.name_en_required'), trigger: 'blur' }],
  nameKh: [{ required: true, message: t('product.name_kh_required'), trigger: 'blur' }],
  unitPrice: [{ required: true, message: t('product.unit_price_required'), trigger: 'change' }],
  discount: [
    { required: true, message: t('product.discount_required'), trigger: 'change' },
    {
      validator: (_rule, value, callback) => {
        if (Number(value) > Number(form.unitPrice)) {
          callback(new Error(t('product.discount_over_price')))
          return
        }
        callback()
      },
      trigger: 'change',
    },
  ],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('product.title'))
  breadcrumbStore.setBreadcrumbs([t('master_data'), t('product.title')])
})

const getErrorMessage = (error: unknown, fallback: string) => {
  if (typeof error === 'object' && error !== null && 'message' in error) {
    return String((error as { message?: string }).message || fallback)
  }
  return fallback
}

const getPublicUrl = (path: string | null) => {
  if (!path) return null
  return supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl
}

const mapProduct = (row: ProductRow): Product => {
  const images = (row.images ?? [])
    .map(image => ({
      id: image.id,
      path: image.image_path,
      isActive: image.is_active,
      sortOrder: image.sort_order,
      url: getPublicUrl(image.image_path) as string,
    }))
    .sort((a, b) => Number(b.isActive) - Number(a.isActive) || a.sortOrder - b.sortOrder)

  return {
    id: row.id,
    categoryId: row.category_id,
    code: row.code,
    nameEn: row.name_en,
    nameKh: row.name_kh,
    unitPrice: Number(row.unit_price),
    discount: Number(row.discount),
    createdByUserId: row.created_by_user_id,
    images,
    thumbnailPaths: images.map(image => image.path),
    thumbnailUrls: images.map(image => image.url),
    createdAt: row.created_at,
    category: row.category
      ? {
          id: row.category.id,
          nameEn: row.category.name_en,
          nameKh: row.category.name_kh,
          parentId: null,
        }
      : null,
  }
}

const categoryLabel = (category: CategoryOption | null) => {
  if (!category) return '—'
  return locale.value === 'km' ? category.nameKh : category.nameEn
}

const formatPrice = (price: number) => new Intl.NumberFormat(locale.value, {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
}).format(price)

const formatDiscount = (discount: number) => formatPrice(discount)

const displayCreatedAt = (value: string | null) => {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat(locale.value, {
    year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit',
  }).format(date)
}

const loadCategories = async () => {
  try {
    loadingCategories.value = true
    const { data, error } = await supabase
      .from('categories')
      .select('id, name_en, name_kh, parent_id')
      .order('name_en')
    if (error) throw error
    categoryOptions.value = (data ?? []).map(row => ({
      id: row.id as number,
      nameEn: row.name_en as string,
      nameKh: row.name_kh as string,
      parentId: row.parent_id as number | null,
    }))
  } catch (error) {
    useNotification(getErrorMessage(error, t('product.load_categories_failed')), 'error')
  } finally {
    loadingCategories.value = false
  }
}

const loadItems = async () => {
  try {
    loading.value = true
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase
      .from('products')
      .select(productSelect, { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, from + params.limit - 1)
    if (search) query = query.or(`code.ilike.%${search}%,name_en.ilike.%${search}%,name_kh.ilike.%${search}%`)
    const { data, count, error } = await query
    if (error) throw error
    items.value = ((data ?? []) as unknown as ProductRow[]).map(mapProduct)
    meta.totalItems = count ?? 0
  } catch (error) {
    useNotification(getErrorMessage(error, t('product.load_failed')), 'error')
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

const resetForm = (item?: Product) => {
  Object.assign(form, item ? {
    categoryId: item.categoryId,
    code: item.code,
    nameEn: item.nameEn,
    nameKh: item.nameKh,
    unitPrice: item.unitPrice,
    discount: item.discount,
  } : emptyForm())
  imagePreviews.value = (item?.images ?? []).map(image => ({
    key: String(image.id),
    id: image.id,
    path: image.path,
    url: image.url,
  }))
  activeImageKey.value = item?.images.find(image => image.isActive)
    ? String(item.images.find(image => image.isActive)?.id)
    : imagePreviews.value[0]?.key ?? null
  nextTick(() => formRef.value?.clearValidate())
}

const loadNextProductCode = async () => {
  try {
    const { data, error } = await supabase
      .from('products')
      .select('id')
      .order('id', { ascending: false })
      .limit(1)

    if (error) throw error

    const latestId = data?.[0]?.id
    const numericId = Number(latestId)
    form.code = Number.isSafeInteger(numericId)
      ? generateProductCode(numericId + 1)
      : generateProductCode(crypto.randomUUID())
  } catch (error) {
    form.code = ''
    useNotification(getErrorMessage(error, t('product.code_preview_failed')), 'warning')
  }
}

const openCreateDialog = () => {
  editingItem.value = null
  resetForm()
  dialogVisible.value = true
  loadNextProductCode()
  if (!categoryOptions.value.length) loadCategories()
}

const openEditDialog = (item: Product) => {
  editingItem.value = item
  resetForm(item)
  dialogVisible.value = true
  if (!categoryOptions.value.length) loadCategories()
}

const handleThumbnailChange = (uploadFile: UploadFile) => {
  const file = uploadFile.raw
  if (!file) return
  if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
    useNotification(t('product.invalid_image_type'), 'error')
    return
  }
  if (file.size > maxImageSize) {
    useNotification(t('product.image_too_large'), 'error')
    return
  }
  if (imagePreviews.value.some(preview => preview.file === file)) return
  const key = crypto.randomUUID()
  imagePreviews.value.push({
    key,
    file,
    url: URL.createObjectURL(file),
  })
  if (!activeImageKey.value) activeImageKey.value = key
}

const removeThumbnail = (preview: ImagePreview) => {
  if (preview.url.startsWith('blob:')) URL.revokeObjectURL(preview.url)
  imagePreviews.value = imagePreviews.value.filter(item => item.key !== preview.key)
  if (activeImageKey.value === preview.key) {
    activeImageKey.value = imagePreviews.value[0]?.key ?? null
  }
}

const uploadThumbnail = async (file: File) => {
  const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const path = `products/${crypto.randomUUID()}.${extension}`
  const { error } = await supabase.storage.from(bucketName).upload(path, file, {
    cacheControl: '3600',
    contentType: file.type,
    upsert: false,
  })
  if (error) throw error
  return path
}

const generateProductCode = (id: string | number) => {
  const value = String(id)
  if (/^\d+$/.test(value)) return `PRD${value.padStart(7, '0')}`
  return `PRD${value.replace(/-/g, '').slice(0, 10).toUpperCase()}`
}

const removeStoredThumbnails = async (paths: string[]) => {
  if (!paths.length) return
  const { error } = await supabase.storage.from(bucketName).remove(paths)
  if (error) throw error
}

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || form.categoryId === null) return

  let uploadedPaths: string[] = []
  let createdProductId: string | null = null
  const oldPaths = editingItem.value?.thumbnailPaths ?? []

  try {
    submitting.value = true
    const uploadedByKey = new Map<string, string>()
    for (const preview of imagePreviews.value) {
      if (!preview.file) continue
      const path = await uploadThumbnail(preview.file)
      uploadedPaths.push(path)
      uploadedByKey.set(preview.key, path)
    }
    const values = {
      category_id: form.categoryId,
      code: form.code,
      name_en: form.nameEn.trim(),
      name_kh: form.nameKh.trim(),
      unit_price: form.unitPrice,
      discount: form.discount,
      updated_at: new Date().toISOString(),
    }

    let productId: string
    if (editingItem.value) {
      const { error } = await supabase
        .from('products')
        .update(values)
        .eq('id', editingItem.value.id)
      if (error) throw error
      productId = editingItem.value.id
    } else {
      const { data, error } = await supabase
        .from('products')
        .insert({
          ...values,
          created_by_user_id: user.value?.id,
        })
        .select('id')
        .single()
      if (error) throw error

      createdProductId = String(data.id)
      productId = createdProductId
      const { error: codeError } = await supabase
        .from('products')
        .update({ code: generateProductCode(createdProductId) })
        .eq('id', createdProductId)
      if (codeError) throw codeError
    }

    const retainedIds = imagePreviews.value
      .map(preview => preview.id)
      .filter((id): id is number => Boolean(id))
    const removedImages = (editingItem.value?.images ?? [])
      .filter(image => !retainedIds.includes(image.id))

    // Clear the previous thumbnail first to satisfy the one-active-image constraint.
    const { error: clearActiveError } = await supabase
      .from('product_images')
      .update({ is_active: false })
      .eq('product_id', productId)
    if (clearActiveError) throw clearActiveError

    if (removedImages.length) {
      const { error: removeRowsError } = await supabase
        .from('product_images')
        .delete()
        .in('id', removedImages.map(image => image.id))
      if (removeRowsError) throw removeRowsError
    }

    const newImageRows = imagePreviews.value.flatMap((preview, index) => {
      const path = uploadedByKey.get(preview.key)
      if (!path) return []
      return [{
        product_id: productId,
        image_path: path,
        is_active: activeImageKey.value === preview.key,
        sort_order: index,
      }]
    })
    if (newImageRows.length) {
      const { error: insertImagesError } = await supabase
        .from('product_images')
        .insert(newImageRows)
      if (insertImagesError) throw insertImagesError
    }

    const activeExistingImage = imagePreviews.value.find(
      preview => preview.id && preview.key === activeImageKey.value,
    )
    if (activeExistingImage?.id) {
      const { error: activateError } = await supabase
        .from('product_images')
        .update({ is_active: true })
        .eq('id', activeExistingImage.id)
      if (activateError) throw activateError
    }

    const removedPaths = removedImages.map(image => image.path)
    if (removedPaths.length) {
      await removeStoredThumbnails(removedPaths).catch(() => {
        useNotification(t('product.old_image_cleanup_failed'), 'warning')
      })
    }

    useNotification(editingItem.value ? t('product.updated') : t('product.created'))
    dialogVisible.value = false
    await loadItems()
  } catch (error) {
    if (createdProductId) {
      await supabase.from('products').delete().eq('id', createdProductId)
    }
    if (uploadedPaths.length) await removeStoredThumbnails(uploadedPaths).catch(() => undefined)
    useNotification(getErrorMessage(error, t('product.save_failed')), 'error')
  } finally {
    submitting.value = false
  }
}

const deleteItem = async (item: Product) => {
  try {
    await ElMessageBox.confirm(
      t('product.confirm_delete', { name: item.nameEn }),
      t('product.delete_title'),
      { confirmButtonText: t('delete'), cancelButtonText: t('cancel'), type: 'warning' },
    )
    const { error } = await supabase.from('products').delete().eq('id', item.id)
    if (error) throw error
    if (item.thumbnailPaths.length) {
      await removeStoredThumbnails(item.thumbnailPaths).catch(() => {
        useNotification(t('product.old_image_cleanup_failed'), 'warning')
      })
    }
    if (items.value.length === 1 && params.page > 1) params.page -= 1
    useNotification(t('product.deleted'))
    await loadItems()
  } catch (error) {
    if (error === 'cancel' || error === 'close') return
    useNotification(getErrorMessage(error, t('product.delete_failed')), 'error')
  }
}

onMounted(() => {
  loadItems()
  loadCategories()
})

onBeforeUnmount(() => {
  imagePreviews.value.forEach((preview) => {
    if (preview.url.startsWith('blob:')) URL.revokeObjectURL(preview.url)
  })
})
</script>
