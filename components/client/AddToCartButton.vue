<template>
  <button
    v-if="user"
    type="button"
    class="flex h-9 w-9 items-center justify-center rounded-full bg-white/95 text-slate-800 shadow-md ring-1 ring-black/5 transition hover:bg-slate-900 hover:text-white disabled:cursor-wait disabled:opacity-70"
    :aria-label="t('cart.add_to_cart')"
    :title="t('cart.add_to_cart')"
    :disabled="adding"
    @click.stop.prevent="addToCart"
  >
    <Icon v-if="adding" name="svg-spinners:ring-resize" size="18" />
    <Icon v-else name="solar:cart-plus-outline" size="21" />
  </button>
</template>

<script setup lang="ts">
const props = defineProps<{ productId: number }>()

const { t } = useI18n()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const cartRefresh = useCartRefresh()
const adding = ref(false)

const addToCart = async () => {
  if (adding.value) return

  adding.value = true
  try {
    const { data: authData, error: authError } = await supabase.auth.getUser()
    if (authError) throw authError
    if (!authData.user) throw new Error(t('cart.authentication_required'))

    const { data: existing, error: lookupError } = await supabase
      .from('picked_products')
      .select('id')
      .eq('picked_by_id', authData.user.id)
      .eq('product_id', props.productId)
      .maybeSingle()

    if (lookupError) throw lookupError
    if (existing) {
      useNotification(t('cart.already_added'), 'warning')
      return
    }

    const { error } = await supabase.from('picked_products').insert({
      product_id: props.productId,
      quantity: 1,
      picked_by_id: authData.user.id,
    })
    if (error) {
      if (error.code === '23505') {
        useNotification(t('cart.already_added'), 'warning')
        return
      }
      throw error
    }

    cartRefresh.value += 1
    useNotification(t('cart.added'))
  } catch (error: unknown) {
    useNotification(error instanceof Error ? error.message : t('cart.add_failed'), 'error')
  } finally {
    adding.value = false
  }
}
</script>
