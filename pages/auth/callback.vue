<template>
  <main class="grid min-h-screen place-items-center bg-slate-50 px-4">
    <section class="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
      <Icon v-if="loading" name="lucide:loader-circle" size="38" class="mx-auto animate-spin text-slate-700" />
      <Icon v-else name="lucide:circle-alert" size="38" class="mx-auto text-red-500" />
      <p class="mt-4 font-medium text-slate-800">
        {{ loading ? $t('auth.oauth_finishing') : errorMessage }}
      </p>
      <NuxtLink v-if="!loading" to="/auth/login" class="mt-5 inline-flex text-sm font-semibold text-slate-900 underline">
        {{ $t('auth.back_to_login') }}
      </NuxtLink>
    </section>
  </main>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const route = useRoute()
const supabase = useSupabaseClient()
const { t } = useI18n()
const loading = ref(true)
const errorMessage = ref(t('auth.oauth_failed'))

onMounted(async () => {
  try {
    const oauthError = typeof route.query.error_description === 'string'
      ? route.query.error_description
      : ''
    if (oauthError) throw new Error(oauthError)

    const code = typeof route.query.code === 'string' ? route.query.code : ''
    if (!code) throw new Error(t('auth.oauth_failed'))

    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (error) throw error

    const requestedPath = typeof route.query.next === 'string' ? route.query.next : '/'
    const nextPath = requestedPath.startsWith('/') && !requestedPath.startsWith('//') ? requestedPath : '/'
    await navigateTo(nextPath, { replace: true })
  } catch (error: any) {
    errorMessage.value = error?.message || t('auth.oauth_failed')
    loading.value = false
  }
})
</script>
