<template>
  <div>
    <h1>User</h1>
  </div>
</template>

<script lang="ts" setup>
  definePageMeta({
    middleware: 'auth',
    title: 'System-User'
  });

  const supabase = useSupabaseClient();

 
</script>
