<template>
  <section class="space-y-5">
    <div class="overflow-hidden rounded-lg border border-slate-200 bg-white">
      <div class="flex flex-col gap-3 border-b border-slate-200 p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 class="font-semibold text-slate-900">{{ t('user_profile.title') }}</h2>
          <p class="mt-1 text-sm text-slate-500">{{ t('user_profile.description') }}</p>
        </div>
        <div class="flex gap-2">
          <el-input v-model="params.search" clearable :placeholder="t('user_profile.search_placeholder')" class="!w-[280px]" @keydown.enter="searchProfiles" @clear="searchProfiles">
            <template #prefix><Icon name="solar:magnifer-outline" /></template>
          </el-input>
          <el-select v-model="params.role" clearable :placeholder="t('user_profile.all_roles')" class="!w-[150px]" @change="searchProfiles">
            <el-option :label="t('user_profile.customer')" value="customer" />
            <el-option :label="t('user_profile.admin')" value="admin" />
          </el-select>
        </div>
      </div>

      <el-table v-loading="loading" :data="profiles" stripe row-key="id" class="w-full">
        <template #empty>{{ t('no_data') }}</template>
        <el-table-column :label="t('user_profile.profile')" width="92" align="center">
          <template #default="{ row }">
            <el-avatar :size="46" :src="profileUrl(row.profile)">
              {{ initials(row.fullName) }}
            </el-avatar>
          </template>
        </el-table-column>
        <el-table-column prop="fullName" :label="t('user_profile.full_name')" min-width="200" />
        <el-table-column prop="userId" :label="t('user_profile.user_id')" min-width="300" show-overflow-tooltip />
        <el-table-column :label="t('user_profile.role')" width="130" align="center">
          <template #default="{ row }">
            <el-tag :type="row.role === 'admin' ? 'danger' : 'primary'" effect="light">{{ t(`user_profile.${row.role}`) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('user_profile.created_at')" min-width="180">
          <template #default="{ row }">{{ formatDateTime(row.createdAt) }}</template>
        </el-table-column>
        <el-table-column :label="t('columns.action')" fixed="right" width="100" align="center">
          <template #default="{ row }">
            <el-button type="success" circle @click="openEdit(row)"><Icon name="solar:pen-2-outline" size="17" /></el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="flex flex-col gap-3 border-t border-slate-200 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center gap-2 text-sm text-slate-600">
          <span>{{ t('dashboard.rows') }}</span>
          <el-select v-model="params.limit" class="!w-[88px]" @change="changeLimit">
            <el-option v-for="size in pageSizes" :key="size" :label="size" :value="size" />
          </el-select>
          <span>{{ t('total') }}: {{ totalProfiles }}</span>
        </div>
        <el-pagination v-model:current-page="params.page" background layout="prev, pager, next" :page-size="params.limit" :total="totalProfiles" @current-change="loadProfiles" />
      </div>
    </div>

    <el-dialog v-model="dialogVisible" :title="t('user_profile.edit_title')" width="min(92vw, 560px)" align-center append-to-body @closed="clearUploadPreview">
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-form-item :label="t('user_profile.profile')">
          <div class="flex items-center gap-4">
            <el-avatar :size="88" :src="avatarPreview || undefined">{{ initials(form.fullName) }}</el-avatar>
            <div class="space-y-2">
              <el-upload accept="image/jpeg,image/png,image/webp" :auto-upload="false" :show-file-list="false" :on-change="selectAvatar">
                <el-button>{{ t('user_profile.choose_profile') }}</el-button>
              </el-upload>
              <el-button v-if="avatarPreview" type="danger" text @click="removeAvatar">{{ t('user_profile.remove_profile') }}</el-button>
              <p class="text-xs text-slate-400">{{ t('user_profile.profile_help') }}</p>
            </div>
          </div>
        </el-form-item>
        <el-form-item :label="t('user_profile.user_id')"><el-input :model-value="editingProfile?.userId" disabled /></el-form-item>
        <el-form-item :label="t('user_profile.full_name')" prop="fullName"><el-input v-model="form.fullName" maxlength="255" /></el-form-item>
        <el-form-item :label="t('user_profile.role')" prop="role">
          <el-select v-model="form.role" class="w-full">
            <el-option :label="t('user_profile.customer')" value="customer" />
            <el-option :label="t('user_profile.admin')" value="admin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" :loading="saving" @click="saveProfile">{{ t('save') }}</el-button>
      </template>
    </el-dialog>
  </section>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules, UploadFile } from 'element-plus'

type UserRole = 'customer' | 'admin'
interface ProfileRow { id: number; user_id: string; full_name: string; role: UserRole; profile: string | null; created_at: string; updated_at: string }
interface UserProfile { id: number; userId: string; fullName: string; role: UserRole; profile: string | null; createdAt: string; updatedAt: string }

definePageMeta({ middleware: 'auth' })
useHead({ title: 'User Profiles | Fashion Shop' })

const { t, locale } = useI18n()
const supabase = useSupabaseClient()
const breadcrumbStore = useBreadcrumbStore()
const bucketName = 'fashion-images'
const pageSizes = [10, 20, 50, 100]
const maxProfileSize = 2 * 1024 * 1024
const loading = ref(false)
const saving = ref(false)
const profiles = ref<UserProfile[]>([])
const totalProfiles = ref(0)
const params = reactive({ search: '', role: '' as '' | UserRole, page: 1, limit: 10 })
const dialogVisible = ref(false)
const editingProfile = ref<UserProfile | null>(null)
const formRef = ref<FormInstance>()
const form = reactive({ fullName: '', role: 'customer' as UserRole })
const avatarFile = ref<File | null>(null)
const avatarPreview = ref<string | null>(null)
const removeExistingAvatar = ref(false)

const rules = computed<FormRules>(() => ({
  fullName: [{ required: true, message: t('user_profile.full_name_required'), trigger: 'blur' }],
  role: [{ required: true, message: t('user_profile.role_required'), trigger: 'change' }],
}))

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('user_profile.title'))
  breadcrumbStore.setBreadcrumbs([t('system'), t('user_profile.title')])
})

const profileUrl = (path: string | null) => path ? supabase.storage.from(bucketName).getPublicUrl(path).data.publicUrl : undefined
const initials = (name: string) => name.trim().split(/\s+/).slice(0, 2).map(part => part[0]?.toUpperCase()).join('') || '?'
const formatDateTime = (value: string) => new Intl.DateTimeFormat(locale.value === 'km' ? 'km-KH' : 'en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value))
const mapProfile = (row: ProfileRow): UserProfile => ({ id: row.id, userId: row.user_id, fullName: row.full_name, role: row.role, profile: row.profile, createdAt: row.created_at, updatedAt: row.updated_at })
const errorMessage = (error: unknown, fallback: string) => error && typeof error === 'object' && 'message' in error ? String((error as { message?: unknown }).message || fallback) : fallback

const loadProfiles = async () => {
  loading.value = true
  try {
    const from = (params.page - 1) * params.limit
    const search = params.search.trim().replace(/[,%()]/g, '')
    let query = supabase.from('user_profiles').select('*', { count: 'exact' }).order('created_at', { ascending: false }).range(from, from + params.limit - 1)
    if (search) {
      query = /^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(search)
        ? query.or(`full_name.ilike.%${search}%,user_id.eq.${search}`)
        : query.ilike('full_name', `%${search}%`)
    }
    if (params.role) query = query.eq('role', params.role)
    const { data, count, error } = await query
    if (error) throw error
    profiles.value = ((data ?? []) as ProfileRow[]).map(mapProfile)
    totalProfiles.value = count ?? 0
  }
  catch (error) { useNotification(errorMessage(error, t('user_profile.load_failed')), 'error') }
  finally { loading.value = false }
}

const clearUploadPreview = () => {
  if (avatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(avatarPreview.value)
  avatarFile.value = null
}
const openEdit = (profile: UserProfile) => {
  clearUploadPreview()
  editingProfile.value = profile
  form.fullName = profile.fullName
  form.role = profile.role
  avatarPreview.value = profileUrl(profile.profile) || null
  removeExistingAvatar.value = false
  dialogVisible.value = true
  nextTick(() => formRef.value?.clearValidate())
}
const selectAvatar = (upload: UploadFile) => {
  const file = upload.raw
  if (!file) return
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) { useNotification(t('user_profile.invalid_profile'), 'error'); return }
  if (file.size > maxProfileSize) { useNotification(t('user_profile.profile_too_large'), 'error'); return }
  if (avatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(avatarPreview.value)
  avatarFile.value = file; avatarPreview.value = URL.createObjectURL(file); removeExistingAvatar.value = false
}
const removeAvatar = () => {
  if (avatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(avatarPreview.value)
  avatarFile.value = null; avatarPreview.value = null; removeExistingAvatar.value = true
}
const uploadAvatar = async (file: File, userId: string) => {
  const extensionByType: Record<string, string> = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  }
  const extension = extensionByType[file.type] || 'jpg'
  const path = `user-profiles/${userId}-${crypto.randomUUID()}.${extension}`
  const { error } = await supabase.storage.from(bucketName).upload(path, file, { contentType: file.type, cacheControl: '3600' })
  if (error) throw error
  return path
}

const saveProfile = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || saving.value || !editingProfile.value) return
  saving.value = true
  let uploadedPath: string | null = null
  const oldPath = editingProfile.value.profile
  try {
    if (avatarFile.value) uploadedPath = await uploadAvatar(avatarFile.value, editingProfile.value.userId)
    const profilePath = uploadedPath ?? (removeExistingAvatar.value ? null : oldPath)
    const { error } = await supabase.rpc('admin_update_user_profile', {
      p_user_id: editingProfile.value.userId,
      p_full_name: form.fullName.trim(),
      p_role: form.role,
      p_profile: profilePath,
    })
    if (error) throw error
    if (oldPath && oldPath !== profilePath) await supabase.storage.from(bucketName).remove([oldPath])
    useNotification(t('user_profile.updated'))
    dialogVisible.value = false
    await loadProfiles()
  }
  catch (error) {
    if (uploadedPath) await supabase.storage.from(bucketName).remove([uploadedPath])
    useNotification(errorMessage(error, t('user_profile.save_failed')), 'error')
  }
  finally { saving.value = false }
}

const searchProfiles = () => { params.page = 1; loadProfiles() }
const changeLimit = () => { params.page = 1; loadProfiles() }
onMounted(loadProfiles)
onBeforeUnmount(clearUploadPreview)
</script>
