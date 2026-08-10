<template>
  <div class="w-full h-screen flex items-start justify-center overflow-hidden">
    <div class="w-[100%] md:w-[25%] h-screen flex items-center justify-center">
      <el-form
        label-position="top"
        @submit.prevent="handleLogin"
        class="px-4 w-full border rounded-md shadow-md"
      >
        <div class="w-full flex items-center justify-center mb-4">
          <Icon :size="100" :name="$t('app.icon')"/>
        </div>
        <div class="text-center font-bold text-gray-700">ចូលប្រព័ន្ធគ្រប់គ្រង</div>
        <el-form-item
          label="ឈ្មោះអ្នកប្រើប្រាស់"
        >
          <el-input
            v-model="formData.email"
            placeholder="Username"
            clearable
          >
            <template #prefix>
              <Icon name="iconoir:user"/>
            </template>            

          </el-input>
        </el-form-item>
      <el-form-item
        label="អក្សរសម្ងាត់"
      >
        <el-input
            v-model="formData.password"
            type="password"
            show-password
            placeholder="Password"
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
            ចូលប្រព័ន្ធ
          </el-button>
        </el-form-item>
        <p class="mb-5 text-center text-sm text-slate-500">
          {{ $t('sign_up.no_account') }}
          <NuxtLink to="/auth/sign-up" class="font-semibold text-slate-900 hover:underline">
            {{ $t('sign_up.submit') }}
          </NuxtLink>
        </p>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
  definePageMeta({
      layout: 'auth',
      middleware: 'auth',
  });

  useSeoMeta({
    title: 'MINI POS - Login',
  })

  interface FormData {
    email: string;
    password: string;
  }

  const formData = ref<FormData>({
    email: 'phall@gmail.com',
    password: '123',
  });

  const loading = ref<boolean>(false);
  const supabase = useSupabaseClient();
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
