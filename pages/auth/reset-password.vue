<template>
  <main class="grid min-h-screen place-items-center bg-slate-50 px-4 py-8">
    <section class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
      <div v-if="checkingLink" class="py-10 text-center">
        <Icon name="lucide:loader-circle" size="38" class="mx-auto animate-spin text-slate-700" />
        <p class="mt-4 text-sm text-slate-500">{{ $t('auth.oauth_finishing') }}</p>
      </div>

      <div v-else-if="invalidLink" class="py-5 text-center">
        <Icon name="lucide:circle-alert" size="42" class="mx-auto text-red-500" />
        <p class="mt-4 text-sm leading-6 text-slate-600">{{ $t('auth.invalid_reset_link') }}</p>
        <NuxtLink to="/auth/login" class="mt-5 inline-flex text-sm font-semibold text-slate-900 underline">
          {{ $t('auth.back_to_login') }}
        </NuxtLink>
      </div>

      <template v-else>
        <div class="mb-7 text-center">
          <span class="mx-auto grid h-14 w-14 place-items-center rounded-full bg-slate-100 text-slate-700">
            <Icon name="lucide:key-round" size="28" />
          </span>
          <h1 class="mt-4 text-2xl font-bold text-slate-900">{{ $t('auth.new_password_title') }}</h1>
          <p class="mt-2 text-sm leading-6 text-slate-500">{{ $t('auth.new_password_description') }}</p>
        </div>

        <el-form label-position="top" @submit.prevent="updatePassword">
          <el-form-item :label="$t('auth.new_password')">
            <el-input v-model="password" type="password" show-password autocomplete="new-password" :placeholder="$t('sign_up.password_placeholder')">
              <template #prefix><Icon name="lucide:lock-keyhole" /></template>
            </el-input>
          </el-form-item>
          <el-form-item :label="$t('auth.confirm_new_password')">
            <el-input v-model="confirmPassword" type="password" show-password autocomplete="new-password" :placeholder="$t('sign_up.confirm_password_placeholder')">
              <template #prefix><Icon name="lucide:lock-keyhole" /></template>
            </el-input>
          </el-form-item>
          <el-button type="primary" native-type="submit" class="mt-2 !w-full" size="large" :loading="saving">
            {{ $t('auth.update_password') }}
          </el-button>
        </el-form>
      </template>
    </section>
  </main>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'auth' })
useSeoMeta({ title: 'Fashion Store | Reset Password' })

const route = useRoute()
const supabase = useSupabaseClient()
const { t } = useI18n()
const checkingLink = ref(true)
const invalidLink = ref(false)
const saving = ref(false)
const password = ref('')
const confirmPassword = ref('')

onMounted(async () => {
  try {
    const code = typeof route.query.code === 'string' ? route.query.code : ''
    if (code) {
      const { error } = await supabase.auth.exchangeCodeForSession(code)
      if (error) throw error
    }
    const { data, error } = await supabase.auth.getSession()
    if (error || !data.session) throw error || new Error(t('auth.invalid_reset_link'))
  } catch {
    invalidLink.value = true
  } finally {
    checkingLink.value = false
  }
})

const updatePassword = async () => {
  if (password.value.length < 8) {
    useNotification(t('sign_up.password_length'), 'error')
    return
  }
  if (password.value !== confirmPassword.value) {
    useNotification(t('sign_up.password_mismatch'), 'error')
    return
  }

  saving.value = true
  try {
    const { error } = await supabase.auth.updateUser({ password: password.value })
    if (error) throw error
    useNotification(t('auth.password_updated'))
    await navigateTo('/', { replace: true })
  } catch (error: any) {
    useNotification(error?.message || t('client_account.password_update_failed'), 'error')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
:deep(.el-input__wrapper) {
  min-height: 44px;
}
</style>
