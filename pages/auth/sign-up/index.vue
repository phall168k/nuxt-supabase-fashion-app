<template>
  <div class="w-full h-screen flex items-start justify-between overflow-hidden">
    <div class="w-full md:w-[50%] h-screen flex items-center justify-center">
      <el-form
        class="px-4 w-[90%] md:w-[70%]"
        label-position="top"
        @submit.prevent="handleSignUp"
      >
        <h1 class="text-[25px] font-bold">{{ $t('sign_up.create_an_account') }}</h1>
        <h2 class="text-[20px] mb-10">{{ $t('sign_up.get_ten_percentage_off_your_first_fashion_store_purchase')}}</h2>
        <el-form-item :label="$t('sign_up.profile_image')">
          <div class="profile-picker" :class="{ 'profile-picker--selected': profileFile }">
            <input
              ref="profileInput"
              class="sr-only"
              type="file"
              accept="image/jpeg,image/png,image/webp"
              @change="handleProfileChange"
            >

            <button
              type="button"
              class="profile-picker__avatar"
              :aria-label="$t('sign_up.choose_profile')"
              @click="profileInput?.click()"
            >
              <el-avatar :size="84" :src="profilePreview || undefined">
                <Icon name="lucide:user-round" :size="32" />
              </el-avatar>
              <span class="profile-picker__camera">
                <Icon name="lucide:camera" :size="15" />
              </span>
            </button>

            <div class="min-w-0 flex-1">
              <p class="text-sm font-semibold text-slate-800">
                {{ profileFile ? profileFile.name : $t('sign_up.profile_prompt') }}
              </p>
              <p class="mt-1 text-xs leading-5 text-slate-500">
                {{ $t('sign_up.profile_help') }}
              </p>
              <div class="mt-3 flex flex-wrap items-center gap-2">
                <button type="button" class="profile-picker__action" @click="profileInput?.click()">
                  <Icon :name="profileFile ? 'lucide:refresh-cw' : 'lucide:upload'" :size="15" />
                  {{ profileFile ? $t('sign_up.change_profile') : $t('sign_up.choose_profile') }}
                </button>
                <button v-if="profileFile" type="button" class="profile-picker__remove" @click="removeProfile">
                  <Icon name="lucide:trash-2" :size="15" />
                  {{ $t('sign_up.remove_profile') }}
                </button>
              </div>
            </div>
          </div>
        </el-form-item>
        <el-form-item
          :label="$t('sign_up.full_name')"
        >
          <el-input
            v-model="formData.fullName"
            :placeholder="$t('sign_up.full_name_placeholder')"
            clearable
          >
            <template #prefix>
              <Icon name="mingcute:profile-line"/>
            </template>

          </el-input>
        </el-form-item>
        <el-form-item
          :label="$t('sign_up.email')"
        >
          <el-input
            v-model="formData.email"
            :placeholder="$t('sign_up.email_placeholder')"
            clearable
          >
            <template #prefix>
              <Icon name="iconoir:user"/>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item
          :label="$t('sign_up.phone')"
        >
          <el-input
            v-model="formData.phoneNumber"
            :placeholder="$t('sign_up.phone_placeholder')"
            clearable
          >
            <template #prefix>
              <Icon name="solar:phone-outline"/>
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
            clearable
          >
            <template #prefix>
              <Icon name="material-symbols:lock-outline"/>
            </template>

          </el-input>
        </el-form-item>
        <el-form-item
        :label="$t('sign_up.confirm_password')"
      >
        <el-input
            v-model="formData.confirmPassword"
            type="password"
            show-password
            :placeholder="$t('sign_up.confirm_password_placeholder')"
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
            {{ $t('sign_up.submit') }}
          </el-button>
        </el-form-item>
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
          {{ $t('sign_up.no_account') }}
          <NuxtLink to="/auth/login" class="font-semibold text-slate-900 hover:underline">
            {{ $t('sign_up.sign_in') }}
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
</template>

<script setup lang="ts">

  definePageMeta({
      layout: 'auth',
      middleware: 'auth',
  });

  useSeoMeta({
    title: 'Fashion Store | Sign Up',
  })

  const handleBackToHome = () => {
    navigateTo('/');
  }

  interface FormData {
    email: string;
    password: string;
    confirmPassword: string;
    fullName: string;
    phoneNumber?: string | null;
    profile?: string | null;
    role: 'customer';
  }

  const formData = ref<FormData>({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: '',
    phoneNumber: null,
    profile: null,
    role: 'customer',
  });

  const loading = ref<boolean>(false);
  const googleLoading = ref(false);
  const { t } = useI18n();
  const profileInput = ref<HTMLInputElement | null>(null);
  const profileFile = ref<File | null>(null);
  const profilePreview = ref<string | null>(null);
  const supabase = useSupabaseClient();
  const bucketName = 'fashion-images';
  const maxProfileSize = 5 * 1024 * 1024;

  const handleGoogleAuth = async () => {
    googleLoading.value = true;
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: `${window.location.origin}/auth/callback?next=/` },
      });
      if (error) throw error;
    } catch (error: any) {
      useNotification(error?.message || t('auth.google_failed'), 'error');
      googleLoading.value = false;
    }
  };

  const removeProfile = () => {
    if (profilePreview.value) URL.revokeObjectURL(profilePreview.value);
    profileFile.value = null;
    profilePreview.value = null;
    if (profileInput.value) profileInput.value.value = '';
  };

  const handleProfileChange = (event: Event) => {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      useNotification(t('sign_up.profile_invalid'), 'error');
      input.value = '';
      return;
    }
    if (file.size > maxProfileSize) {
      useNotification(t('sign_up.profile_too_large'), 'error');
      input.value = '';
      return;
    }

    if (profilePreview.value) URL.revokeObjectURL(profilePreview.value);
    profileFile.value = file;
    profilePreview.value = URL.createObjectURL(file);
  };

  const validateForm = () => {
    if (formData.value.fullName.trim().length < 2) return t('sign_up.full_name_required');
    if (!/^\S+@\S+\.\S+$/.test(formData.value.email)) return t('sign_up.email_invalid');
    if (formData.value.password.length < 8) return t('sign_up.password_length');
    if (formData.value.password !== formData.value.confirmPassword) return t('sign_up.password_mismatch');
    return null;
  };

  const handleSignUp = async () => {
    const validationError = validateForm();
    if (validationError) {
      useNotification(validationError, 'error');
      return;
    }

    loading.value = true;
    try {
      const signupProfileToken = profileFile.value ? crypto.randomUUID() : null;
      const { data, error } = await supabase.auth.signUp({
        email: formData.value.email.trim(),
        password: formData.value.password,
        options: {
          data: {
            full_name: formData.value.fullName.trim(),
            phone_number: formData.value.phoneNumber?.trim() || null,
            role: 'customer',
            ...(signupProfileToken ? { signup_profile_token: signupProfileToken } : {}),
          },
        },
      });
      if (error) throw error;
      if (!data.user) throw new Error(t('sign_up.failed'));

      if (profileFile.value && signupProfileToken) {
        const extension = profileFile.value.type.split('/')[1] === 'jpeg' ? 'jpg' : profileFile.value.type.split('/')[1];
        const profilePath = `user-profiles/${data.user.id}-${signupProfileToken}.${extension}`;
        const { error: uploadError } = await supabase.storage
          .from(bucketName)
          .upload(profilePath, profileFile.value, {
            contentType: profileFile.value.type,
            cacheControl: '3600',
            upsert: false,
          });
        if (uploadError) throw uploadError;

        const { error: profileError } = await supabase.rpc('complete_signup_profile_avatar', {
          p_user_id: data.user.id,
          p_token: signupProfileToken,
          p_profile: profilePath,
        });
        if (profileError) {
          await supabase.storage.from(bucketName).remove([profilePath]);
          throw profileError;
        }
      }

      useNotification(t('sign_up.success'));
      await navigateTo(data.session ? '/' : '/auth/login', { replace: true });
    } catch (error: any) {
      useNotification(error?.message || t('sign_up.failed'), 'error');
    } finally {
      loading.value = false;
    }
  }

  onBeforeUnmount(() => {
    if (profilePreview.value) URL.revokeObjectURL(profilePreview.value);
  });

</script>

<style scoped>
:deep(.el-input__wrapper) {
  min-height: 42px;
}

.profile-picker {
  display: flex;
  width: 100%;
  align-items: center;
  gap: 1.25rem;
  border: 1px solid #e2e8f0;
  border-radius: 1rem;
  padding: 1rem;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  transition: border-color 180ms ease, box-shadow 180ms ease, transform 180ms ease;
}

.profile-picker:hover,
.profile-picker:focus-within {
  border-color: #94a3b8;
  box-shadow: 0 10px 30px -18px rgb(15 23 42 / 35%);
}

.profile-picker--selected {
  border-color: #cbd5e1;
  background: linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%);
}

.profile-picker__avatar {
  position: relative;
  flex: none;
  border-radius: 9999px;
  padding: 3px;
  background: #ffffff;
  box-shadow: 0 0 0 1px #e2e8f0, 0 8px 20px -10px rgb(15 23 42 / 45%);
  cursor: pointer;
  transition: transform 180ms ease, box-shadow 180ms ease;
}

.profile-picker__avatar:hover,
.profile-picker__avatar:focus-visible {
  transform: translateY(-2px);
  outline: none;
  box-shadow: 0 0 0 3px #e2e8f0, 0 12px 24px -10px rgb(15 23 42 / 50%);
}

.profile-picker__avatar :deep(.el-avatar) {
  background: #f1f5f9;
  color: #64748b;
}

.profile-picker__camera {
  position: absolute;
  right: 0;
  bottom: 2px;
  display: grid;
  width: 28px;
  height: 28px;
  place-items: center;
  border: 3px solid #ffffff;
  border-radius: 9999px;
  background: #0f172a;
  color: #ffffff;
}

.profile-picker__action,
.profile-picker__remove {
  display: inline-flex;
  min-height: 34px;
  align-items: center;
  gap: 0.4rem;
  border-radius: 0.6rem;
  padding: 0.4rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 600;
  transition: background-color 160ms ease, color 160ms ease, border-color 160ms ease;
}

.profile-picker__action {
  border: 1px solid #0f172a;
  background: #0f172a;
  color: #ffffff;
}

.profile-picker__action:hover {
  background: #334155;
  border-color: #334155;
}

.profile-picker__remove {
  color: #dc2626;
}

.profile-picker__remove:hover {
  background: #fef2f2;
}

@media (max-width: 420px) {
  .profile-picker {
    align-items: flex-start;
    gap: 1rem;
    padding: 0.875rem;
  }
}
</style>
