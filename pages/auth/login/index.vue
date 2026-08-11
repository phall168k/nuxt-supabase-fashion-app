<template>
  <div class="w-full h-screen flex items-start justify-between overflow-hidden">
    <div class="w-full md:w-[50%] h-screen flex items-center justify-center">
      <el-form
        class="px-4 w-[90%] md:w-[70%]"
        label-position="top"
        @submit.prevent="handleLogin"
      >
        <h1 class="text-[25px] font-bold">{{ $t('sign_up.welcome_back') }}</h1>
        <h2 class="text-[20px] mb-10">{{ $t('sign_up.sign_in_to_enjoy_a_seamless_shopping_experience')}}</h2>
        <el-form-item
          :label="$t('sign_up.email')"
        >
          <el-input
            v-model="formData.email"
            type="email"
            :placeholder="$t('sign_up.email_placeholder')"
            autocomplete="email"
            clearable
          >
            <template #prefix>
              <Icon name="iconoir:user"/>
            </template>            

          </el-input>
        </el-form-item>
      <el-form-item
        :label="$t('sign_up.password')"
      >
        <el-input
            v-model="formData.password"
            type="password"
            show-password
            :placeholder="$t('sign_up.password_placeholder')"
            autocomplete="current-password"
            clearable
          >
            <template #prefix>
              <Icon name="material-symbols:lock-outline"/>
            </template>

          </el-input>
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            native-type="submit"
            class="w-full"
            :disabled="loading"
            :loading="loading"
          >
            {{ $t('sign_up.sign_in') }}
          </el-button>
        </el-form-item>
        <div class="w-full my-2 flex items-center justify-end">
          <button type="button" class="text-red-500 hover:underline" @click="openForgotPassword">
            {{ $t('sign_up.forgot_password') }}
          </button>
        </div>
        <div class="flex items-center justify-between gap-2">
          <div class="h-[1px] bg-gray-400 w-[45%]"/>
          {{ $t('sign_up.or') }}
          <div class="h-[1px] bg-gray-400 w-[45%]"/>
        </div>
        <div class="text-center my-4">
          <el-button class="w-full" :loading="googleLoading" :disabled="loading" @click="handleGoogleAuth">
            <Icon :size="20" name="devicon:google"/>&nbsp;{{ $t('sign_up.continue_with_google') }}
          </el-button>
        </div>
        <p class="mb-5 text-center text-sm text-slate-500">
          {{ $t('sign_up.have_account') }}
          <NuxtLink to="/auth/sign-up" class="font-semibold text-slate-900 hover:underline">
            {{ $t('sign_up.submit') }}
          </NuxtLink>
        </p>
      </el-form>
    </div>
    <div class="h-screen hidden md:block md:w-[45%]">
      <el-image
        src="https://myten11.com/images/collections/hanumanxten11.jpg"
        class="h-full"
        fit="cover"
      />
    </div>
  </div>
  <button @click="handleBackToHome" class="fixed top-[20px] left-[20px]">
    <Icon :size="25" name="material-symbols:arrow-back-rounded"/>
  </button>

  <el-dialog
    v-model="forgotPasswordVisible"
    :title="$t('auth.forgot_password_title')"
    width="min(92vw, 440px)"
    align-center
    append-to-body
  >
    <p class="mb-5 text-sm leading-6 text-slate-500">{{ $t('auth.forgot_password_description') }}</p>
    <el-form @submit.prevent="sendResetEmail">
      <el-form-item :label="$t('sign_up.email')">
        <el-input
          v-model="resetEmail"
          type="email"
          :placeholder="$t('sign_up.email_placeholder')"
          autocomplete="email"
        >
          <template #prefix><Icon name="lucide:mail" /></template>
        </el-input>
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="forgotPasswordVisible = false">{{ $t('auth.cancel') }}</el-button>
      <el-button type="primary" :loading="resetLoading" @click="sendResetEmail">
        {{ $t('auth.send_reset_link') }}
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">

  definePageMeta({
      layout: 'auth',
      middleware: 'auth',
  });

  useSeoMeta({
    title: 'Fashion Store | Sign In',
  })

  const handleBackToHome = () => {
    navigateTo('/');
  }

  interface FormData {
    email: string;
    password: string;
  }

  const formData = ref<FormData>({
    email: '',
    password: '',
  });

  const loading = ref<boolean>(false);
  const googleLoading = ref(false);
  const forgotPasswordVisible = ref(false);
  const resetLoading = ref(false);
  const resetEmail = ref('');
  const { t } = useI18n();
  const supabase = useSupabaseClient();

  const authRedirectUrl = (path: string) => `${window.location.origin}${path}`;

  const handleGoogleAuth = async () => {
    googleLoading.value = true;
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: authRedirectUrl('/auth/callback?next=/') },
      });
      if (error) throw error;
    } catch (error: any) {
      useNotification(error?.message || t('auth.google_failed'), 'error');
      googleLoading.value = false;
    }
  };

  const openForgotPassword = () => {
    resetEmail.value = formData.value.email.trim();
    forgotPasswordVisible.value = true;
  };

  const sendResetEmail = async () => {
    const email = resetEmail.value.trim();
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      useNotification(t('sign_up.email_invalid'), 'error');
      return;
    }
    resetLoading.value = true;
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: authRedirectUrl('/auth/reset-password'),
      });
      if (error) throw error;
      forgotPasswordVisible.value = false;
      useNotification(t('auth.reset_email_sent'));
    } catch (error: any) {
      useNotification(error?.message || t('auth.reset_email_failed'), 'error');
    } finally {
      resetLoading.value = false;
    }
  };
  const handleLogin = async () => {
    loading.value = true;
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email: formData.value.email,
        password: formData.value.password,
      });
      if (error) throw error;
      useNotification('Signed in successfully');
      await navigateTo('/', {
        replace: true,
      });
    } catch (error: any) {
      useNotification(error.message, 'error');
    } finally {
      loading.value = false;
    }
  }

</script>
