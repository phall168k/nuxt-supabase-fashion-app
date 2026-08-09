<template>
  <main class="min-h-screen bg-slate-50 px-4 py-8 sm:flex sm:items-center sm:justify-center">
    <section class="mx-auto w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
      <div class="mb-7 text-center">
        <NuxtLink to="/" class="inline-flex items-center gap-2 text-xl font-bold text-slate-900">
          <Icon :name="t('app.icon')" size="42" />
          {{ t('app.title') }}
        </NuxtLink>
        <h1 class="mt-5 text-2xl font-bold text-slate-900">{{ t('sign_up.title') }}</h1>
        <p class="mt-2 text-sm text-slate-500">{{ t('sign_up.description') }}</p>
      </div>

      <div v-if="registrationComplete" class="py-5 text-center">
        <span class="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
          <Icon name="lucide:mail-check" size="30" />
        </span>
        <h2 class="mt-5 text-lg font-semibold text-slate-900">{{ t('sign_up.check_email_title') }}</h2>
        <p class="mt-2 text-sm leading-6 text-slate-500">
          {{ t('sign_up.check_email_description', { email: form.email }) }}
        </p>
        <NuxtLink to="/auth/login" class="mt-6 inline-flex text-sm font-semibold text-slate-900 underline underline-offset-4">
          {{ t('sign_up.go_to_login') }}
        </NuxtLink>
      </div>

      <el-form
        v-else
        ref="formRef"
        :model="form"
        :rules="rules"
        label-position="top"
        hide-required-asterisk
        @submit.prevent="submit"
      >
        <el-form-item :label="t('sign_up.full_name')" prop="fullName">
          <el-input v-model="form.fullName" :placeholder="t('sign_up.full_name_placeholder')" clearable autocomplete="name">
            <template #prefix><Icon name="lucide:user" /></template>
          </el-input>
        </el-form-item>

        <el-form-item :label="t('sign_up.email')" prop="email">
          <el-input v-model="form.email" type="email" :placeholder="t('sign_up.email_placeholder')" clearable autocomplete="email">
            <template #prefix><Icon name="lucide:mail" /></template>
          </el-input>
        </el-form-item>

        <el-form-item :label="t('sign_up.phone')" prop="phone">
          <el-input v-model="form.phone" type="tel" :placeholder="t('sign_up.phone_placeholder')" clearable autocomplete="tel">
            <template #prefix><Icon name="lucide:phone" /></template>
          </el-input>
        </el-form-item>

        <el-form-item :label="t('sign_up.password')" prop="password">
          <el-input v-model="form.password" type="password" :placeholder="t('sign_up.password_placeholder')" show-password autocomplete="new-password">
            <template #prefix><Icon name="lucide:lock-keyhole" /></template>
          </el-input>
        </el-form-item>

        <el-form-item :label="t('sign_up.confirm_password')" prop="confirmPassword">
          <el-input v-model="form.confirmPassword" type="password" :placeholder="t('sign_up.confirm_password_placeholder')" show-password autocomplete="new-password">
            <template #prefix><Icon name="lucide:lock-keyhole" /></template>
          </el-input>
        </el-form-item>

        <el-button type="primary" native-type="submit" class="mt-2 !w-full" size="large" :loading="loading">
          {{ t('sign_up.submit') }}
        </el-button>
      </el-form>

      <p v-if="!registrationComplete" class="mt-6 text-center text-sm text-slate-500">
        {{ t('sign_up.have_account') }}
        <NuxtLink to="/auth/login" class="font-semibold text-slate-900 hover:underline">
          {{ t('sign_up.sign_in') }}
        </NuxtLink>
      </p>

      <div class="mt-6 flex items-center justify-center gap-4 border-t border-slate-100 pt-5 text-sm">
        <NuxtLink to="/" class="text-slate-500 hover:text-slate-900">{{ t('sign_up.back_to_shop') }}</NuxtLink>
        <button type="button" class="text-slate-500 hover:text-slate-900" @click="setLocale(locale === 'en' ? 'km' : 'en')">
          {{ locale === 'en' ? 'ខ្មែរ' : 'English' }}
        </button>
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import type { FormInstance, FormRules } from 'element-plus'

definePageMeta({ layout: 'auth' })

const { t, locale, setLocale } = useI18n()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const formRef = ref<FormInstance>()
const loading = ref(false)
const registrationComplete = ref(false)
const form = reactive({
  fullName: '',
  email: '',
  phone: '',
  password: '',
  confirmPassword: '',
})

const rules = computed<FormRules>(() => ({
  fullName: [
    { required: true, message: t('sign_up.full_name_required'), trigger: 'blur' },
    { min: 2, max: 100, message: t('sign_up.full_name_length'), trigger: 'blur' },
  ],
  email: [
    { required: true, message: t('sign_up.email_required'), trigger: 'blur' },
    { type: 'email', message: t('sign_up.email_invalid'), trigger: ['blur', 'change'] },
  ],
  phone: [{ pattern: /^\+?[0-9\s()-]{8,20}$/, message: t('sign_up.phone_invalid'), trigger: 'blur' }],
  password: [
    { required: true, message: t('sign_up.password_required'), trigger: 'blur' },
    { min: 8, message: t('sign_up.password_length'), trigger: 'blur' },
  ],
  confirmPassword: [
    { required: true, message: t('sign_up.confirm_password_required'), trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        if (value !== form.password) callback(new Error(t('sign_up.password_mismatch')))
        else callback()
      },
      trigger: ['blur', 'change'],
    },
  ],
}))

const submit = async () => {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid || loading.value) return

  loading.value = true
  try {
    const { data, error } = await supabase.auth.signUp({
      email: form.email.trim().toLowerCase(),
      password: form.password,
      options: {
        data: {
          full_name: form.fullName.trim(),
          phone: form.phone.trim() || null,
          role: 'customer',
        },
      },
    })

    if (error) throw error
    useNotification(t('sign_up.success'))

    if (data.session) await navigateTo('/', { replace: true })
    else registrationComplete.value = true
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : t('sign_up.failed')
    useNotification(message, 'error')
  } finally {
    loading.value = false
  }
}

watchEffect(() => {
  if (user.value && !loading.value && !registrationComplete.value) {
    navigateTo('/', { replace: true })
  }
})

useSeoMeta({ title: () => `${t('sign_up.title')} | ${t('app.title')}` })
</script>
