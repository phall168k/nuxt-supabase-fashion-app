<template>
  <section class="flex min-h-screen flex-col pt-[80px]">
    <nav class="fixed inset-x-0 top-0 z-50 flex h-[80px] w-full flex-col items-center justify-center border-b bg-white/95 shadow-sm backdrop-blur">
      <nav class="h-[50px] w-[90%] flex items-center justify-between pt-2">
        <div class="w-[50%] flex items-center gap-2">
          <button
            type="button"
            class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-slate-700 transition hover:bg-slate-100 md:hidden"
            aria-label="Open categories"
            @click="categoryDrawerVisible = true"
          >
            <Icon size="25" name="lucide:menu" />
          </button>
          <NuxtLink class="text-[20px] font-bold text-slate-900 flex items-center gap-2" to="/">
            <el-image class="h-8" src="/logo.png" fit="cover"/>
            <span class="hidden md:flex">{{ $t('app.title') }}</span>
          </NuxtLink>
        </div>
        <div class="w-[50%] h-full flex items-center justify-end gap-3">
          
          <Icon  
            @click="handleChangeLocalizaiton(locale === 'en' ? 'km' : 'en')"
            :size="25" 
            class="cursor-pointer"
            :name="locale === 'km' ? 'emojione:flag-for-cambodia' : 'emojione:flag-for-united-kingdom'"
          />
          <el-input
            v-model="searchKeyword"
            :placeholder="t('search.placeholder')"
            clearable
            class="!hidden md:!flex"
            @keydown.enter="submitSearch"
            @clear="submitSearch"
          >
            <template #prefix>
              <Icon name="iconamoon:search-bold"/>
            </template>
          </el-input>
          <button
            type="button"
            class="flex h-9 w-9 items-center justify-center rounded-full text-slate-700 transition hover:bg-slate-100 md:hidden"
            :aria-label="t('search.placeholder')"
            @click="searchDialogVisible = true"
          >
              <Icon size="25" name="iconamoon:search-bold" />
          </button>
          <el-dropdown trigger="click" placement="bottom-end" @command="handleAccountCommand" @visible-change="handleAccountDropdownVisibility">
            <button
              type="button"
              class="flex h-9 w-9 items-center justify-center rounded-full text-slate-700 transition hover:bg-slate-100 hover:text-slate-950"
              :aria-label="t('client_account.account')"
            >
              <el-avatar v-if="user" :key="profileAvatarUrl" :size="34" :src="profileAvatarUrl || undefined" class="border border-slate-200 bg-slate-800 text-xs text-white">
                {{ customerInitials }}
              </el-avatar>
              <Icon v-else size="25" name="lucide:user-round" />
            </button>
            <template #dropdown>
              <el-dropdown-menu class="min-w-48">
                <div v-if="user" v-loading="clientProfileLoading" element-loading-background="rgba(255, 255, 255, 0.82)" class="flex min-h-[69px] min-w-64 items-center gap-3 border-b border-slate-100 px-4 py-3">
                  <el-avatar :key="profileAvatarUrl" :size="44" :src="profileAvatarUrl || undefined" class="shrink-0 bg-slate-800 text-sm text-white">{{ customerInitials }}</el-avatar>
                  <div class="min-w-0">
                    <p class="truncate text-sm font-semibold text-slate-800">{{ customerName }}</p>
                    <p class="mt-0.5 truncate text-xs text-slate-500">{{ user.email }}</p>
                    <el-tag v-if="clientProfile" class="mt-1.5" size="small" effect="plain">{{ t(`user_profile.${clientProfile.role}`) }}</el-tag>
                  </div><button type="button" class="flex h-9 w-9 items-center justify-center rounded-full text-slate-700 transition hover:bg-slate-100" :aria-label="t('cart.title')" @click="openCart">
              <Icon size="25" name="iconamoon:shopping-bag-light" />
            </button>
                </div>
                <el-dropdown-item v-if="clientProfile?.role === 'admin'" command="admin-dashboard">
                  <Icon name="lucide:layout-dashboard" class="mr-2" />
                  {{ t('menu.dashboard') }}
                </el-dropdown-item>
                <el-dropdown-item v-if="user" @click="openProfileDialog">
                  <Icon name="lucide:user-pen" class="mr-2" />
                  {{ t('headers.edit_profile') }}
                </el-dropdown-item>
                <el-dropdown-item v-if="user && !isGoogleUser" command="change-password">
                  <Icon name="lucide:key-round" class="mr-2" />
                  {{ t('headers.change_password') }}
                </el-dropdown-item>
                <el-dropdown-item v-if="user" command="purchase-history">
                  <Icon name="lucide:receipt-text" class="mr-2" />
                  {{ t('purchase_history.menu') }}
                </el-dropdown-item>
                <el-dropdown-item v-if="!user" command="sign-in">
                  <Icon name="lucide:log-in" class="mr-2" />
                  {{ t('sign_up.sign_in') }}
                </el-dropdown-item>
                <el-dropdown-item v-else command="sign-out" :disabled="signingOut" divided>
                  <Icon name="lucide:log-out" class="mr-2" />
                  {{ t('headers.logout') }}
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
          <el-badge :value="cartCount" :hidden="cartCount === 0" :max="99">
            <button type="button" class="flex h-9 w-9 items-center justify-center rounded-full text-slate-700 transition hover:bg-slate-100" :aria-label="t('cart.title')" @click="openCart">
              <Icon size="25" name="iconamoon:shopping-bag-light" />
            </button>
          </el-badge>
        </div>
      </nav>
      <nav
        class="h-[30px] w-[90%] hidden md:flex items-center justify-start gap-8 pb-2"
        aria-label="Product categories"
        @mouseleave="closeDropdown"
      >
        <div
          v-for="category in categories"
          :key="category.id"
          class="h-full flex items-center"
          @mouseenter="openDropdown(category.id)"
        >
          <button
            type="button"
            class="category-trigger"
            :class="{ 'category-trigger--active': activeCategoryId === category.id }"
            :aria-expanded="activeCategoryId === category.id"
            :aria-controls="`category-menu-${category.id}`"
            @click="toggleDropdown(category.id)"
            @focus="openDropdown(category.id)"
          >
            <span>{{ categoryName(category) }}</span>
            <Icon
              name="lucide:chevron-down"
              size="15"
              class="transition-transform duration-200"
              :class="{ 'rotate-180': activeCategoryId === category.id }"
            />
          </button>

          <Transition name="category-menu">
            <section
              v-if="activeCategoryId === category.id"
              :id="`category-menu-${category.id}`"
              class="category-dropdown"
              @mouseenter="openDropdown(category.id)"
            >
              <div class="mx-auto w-[90%] py-5">
                <NuxtLink
                  :to="categoryPath(category)"
                  class="inline-flex items-center gap-2 font-semibold text-gray-900 hover:text-black"
                  @click="closeDropdown"
                >
                  <Icon :name="category.icon || defaultCategoryIcon" size="20" />
                  {{ categoryName(category) }}
                </NuxtLink>
                <div class="mt-4 grid max-w-2xl grid-cols-1 gap-x-20 gap-y-3 sm:grid-cols-2">
                  <NuxtLink
                    v-for="child in category.children"
                    :key="child.id"
                    :to="categoryPath(child)"
                    class="group flex min-w-0 items-center gap-3 text-sm text-gray-600 hover:text-black"
                    @click="closeDropdown"
                  >
                    <span class="category-thumbnail">
                      <Icon
                        :name="child.icon || defaultCategoryIcon"
                        size="20"
                        class="text-gray-500 transition-transform duration-200 group-hover:scale-110"
                      />
                    </span>
                    <span class="truncate">{{ categoryName(child) }}</span>
                  </NuxtLink>
                </div>
              </div>
            </section>
          </Transition>
        </div>
      </nav>
    </nav>

    <el-dialog
      v-model="searchDialogVisible"
      width="min(92vw, 520px)"
      :show-close="false"
      align-center
      append-to-body
      class="mobile-search-dialog"
    >
      <div class="flex items-center gap-2">
        <el-input
          v-model="searchKeyword"
          :placeholder="t('search.placeholder')"
          size="large"
          clearable
          autofocus
          @keyup.enter="submitMobileSearch"
        >
          <template #prefix>
            <Icon name="iconamoon:search-bold" />
          </template>
        </el-input>
        <button
          type="button"
          class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-slate-600 transition hover:bg-slate-100 hover:text-slate-950"
          aria-label="Close search"
          @click="searchDialogVisible = false"
        >
          <Icon name="lucide:x" size="22" />
        </button>
      </div>
    </el-dialog>

    <el-drawer
      v-model="categoryDrawerVisible"
      direction="ltr"
      size="min(88vw, 360px)"
      :show-close="false"
      append-to-body
      class="mobile-category-drawer"
    >
      <template #header>
        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-2">
            <el-image class="h-8 w-8" src="/logo.png" fit="cover" />
            <span class="text-lg font-bold text-slate-900">Categories</span>
          </div>
          <button
            type="button"
            class="flex h-9 w-9 items-center justify-center rounded-full text-slate-600 transition hover:bg-slate-100"
            aria-label="Close categories"
            @click="categoryDrawerVisible = false"
          >
            <Icon name="lucide:x" size="22" />
          </button>
        </div>
      </template>

      <nav aria-label="Product categories" class="space-y-2">
        <section v-for="category in categories" :key="category.id" class="overflow-hidden rounded-xl border border-slate-200 bg-white">
          <div class="flex min-h-12 items-center gap-3 px-4 py-3">
            <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-slate-100 text-slate-600">
              <Icon :name="category.icon || defaultCategoryIcon" size="20" />
            </span>
            <NuxtLink
              :to="categoryPath(category)"
              class="min-w-0 flex-1 truncate font-semibold text-slate-800 transition hover:text-slate-950"
              @click="categoryDrawerVisible = false"
            >
              {{ categoryName(category) }}
            </NuxtLink>
            <button
              v-if="category.children.length"
              type="button"
              class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
              :aria-label="`Toggle ${categoryName(category)} subcategories`"
              :aria-expanded="expandedMobileCategoryIds.includes(category.id)"
              @click="toggleMobileCategory(category.id)"
            >
              <Icon
                name="lucide:chevron-down"
                size="18"
                class="transition-transform duration-200"
                :class="{ 'rotate-180': expandedMobileCategoryIds.includes(category.id) }"
              />
            </button>
            <Icon v-else name="lucide:chevron-right" size="17" class="text-slate-400" />
          </div>

          <Transition name="mobile-category-collapse">
          <div v-if="category.children.length && expandedMobileCategoryIds.includes(category.id)" class="border-t border-slate-100 bg-slate-50/70 px-3 py-2">
            <NuxtLink
              v-for="child in category.children"
              :key="child.id"
              :to="categoryPath(child)"
              class="flex items-center gap-2 rounded-lg px-3 py-2.5 text-sm text-slate-600 transition hover:bg-white hover:text-slate-950"
              @click="categoryDrawerVisible = false"
            >
              <Icon :name="child.icon || defaultCategoryIcon" size="17" class="shrink-0 text-slate-400" />
              <span class="truncate">{{ categoryName(child) }}</span>
            </NuxtLink>
          </div>
          </Transition>
        </section>

        <p v-if="!categories.length" class="py-10 text-center text-sm text-slate-400">No categories available</p>
      </nav>
    </el-drawer>

    <el-drawer v-model="cartDrawerVisible" :title="t('cart.title')" direction="rtl" size="min(92vw, 430px)" append-to-body @open="loadCart">
      <div v-loading="cartLoading" class="min-h-40">
        <div v-if="!cartLoading && cartItems.length" class="divide-y divide-slate-200">
          <article v-for="item in cartItems" :key="item.id" class="flex gap-3 py-4 first:pt-0">
            <NuxtLink :to="`/detail/${item.product.id}`" class="h-24 w-20 shrink-0 overflow-hidden rounded-md bg-slate-100" @click="cartDrawerVisible = false">
              <el-image v-if="item.product.thumbnailUrl" :src="item.product.thumbnailUrl" :alt="cartProductName(item.product)" fit="cover" class="h-full w-full" />
              <span v-else class="flex h-full items-center justify-center text-slate-300"><Icon name="solar:gallery-wide-outline" size="28" /></span>
            </NuxtLink>
            <div class="min-w-0 flex-1">
              <NuxtLink :to="`/detail/${item.product.id}`" class="line-clamp-2 text-sm font-semibold text-slate-800 hover:text-black" @click="cartDrawerVisible = false">{{ cartProductName(item.product) }}</NuxtLink>
              <p class="mt-1 text-sm font-medium text-rose-600">{{ formatCartPrice(item.product.unitPrice - item.product.discount) }}</p>
              <div class="mt-2 inline-flex items-center rounded-md border border-slate-200">
                <button type="button" class="flex h-8 w-8 items-center justify-center text-slate-600 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-40" :aria-label="t('cart.decrease_quantity')" :disabled="item.quantity <= 1 || updatingCartItemId === item.id" @click="changeCartQuantity(item, -1)">
                  <Icon name="lucide:minus" size="15" />
                </button>
                <span class="min-w-9 text-center text-sm font-medium">{{ item.quantity }}</span>
                <button type="button" class="flex h-8 w-8 items-center justify-center text-slate-600 hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-40" :aria-label="t('cart.increase_quantity')" :disabled="item.quantity >= item.product.available || updatingCartItemId === item.id" @click="changeCartQuantity(item, 1)">
                  <Icon v-if="updatingCartItemId === item.id" name="svg-spinners:ring-resize" size="15" />
                  <Icon v-else name="lucide:plus" size="15" />
                </button>
              </div>
            </div>
            <button type="button" class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-slate-400 transition hover:bg-rose-50 hover:text-rose-600 disabled:cursor-wait" :aria-label="t('cart.remove')" :disabled="removingCartItemId === item.id" @click="removeCartItem(item)">
              <Icon v-if="removingCartItemId === item.id" name="svg-spinners:ring-resize" size="17" />
              <Icon v-else name="solar:trash-bin-trash-outline" size="18" />
            </button>
          </article>
        </div>
        <div v-else-if="!cartLoading" class="flex min-h-52 flex-col items-center justify-center text-center text-slate-400">
          <Icon name="iconamoon:shopping-bag-light" size="44" />
          <p class="mt-3 text-sm">{{ t('cart.empty') }}</p>
        </div>
      </div>
      <template #footer>
        <div v-if="cartItems.length" class="space-y-3 border-t border-slate-200 pt-4 text-left">
          <div class="space-y-2 text-sm">
            <div class="flex items-center justify-between text-slate-600">
              <span>{{ t('cart.subtotal') }}</span>
              <span>{{ formatCartPrice(cartSubtotal) }}</span>
            </div>
            <div class="flex items-center justify-between text-rose-600">
              <span>{{ t('cart.total_discount') }}</span>
              <span>-{{ formatCartPrice(cartDiscount) }}</span>
            </div>
            <div class="flex items-center justify-between border-t border-slate-200 pt-2 text-base font-semibold text-slate-900">
              <span>{{ t('cart.final_total') }}</span>
              <span>{{ formatCartPrice(cartTotal) }}</span>
            </div>
          </div>
          <div>
            <p class="mb-2 text-sm font-medium text-slate-700">{{ t('cart.select_payment_method') }}</p>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="method in cartPaymentMethods"
                :key="method.id"
                type="button"
                class="relative flex min-h-16 items-center gap-2.5 rounded-md border p-2.5 text-left transition"
                :class="selectedPaymentMethodId === method.id ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-500' : 'border-slate-200 bg-white hover:border-slate-400'"
                @click="selectedPaymentMethodId = method.id"
              >
                <el-image v-if="method.logoUrl" :src="method.logoUrl" :alt="method.name" fit="contain" class="h-9 w-11 shrink-0 rounded bg-white" />
                <span v-else class="flex h-9 w-11 shrink-0 items-center justify-center rounded bg-slate-100 text-slate-400">
                  <Icon name="solar:card-outline" size="20" />
                </span>
                <span class="min-w-0 flex-1 truncate text-sm font-medium text-slate-700">{{ method.name }}</span>
                <Icon v-if="selectedPaymentMethodId === method.id" name="solar:check-circle-bold" size="18" class="absolute right-1.5 top-1.5 text-blue-600" />
              </button>
            </div>
            <p v-if="!cartPaymentMethods.length" class="rounded-md bg-slate-50 px-3 py-4 text-center text-sm text-slate-500">{{ t('cart.no_payment_methods') }}</p>
          </div>
          <el-button type="primary" class="!w-full" size="large" :disabled="!selectedPaymentMethodId" @click="placeOrder">
            <Icon name="solar:bag-check-outline" size="19" />
            <span class="ml-1">{{ t('cart.place_order') }}</span>
          </el-button>
        </div>
      </template>
    </el-drawer>

    <el-dialog v-model="purchaseOrderDialogVisible" :title="t('cart.purchase_order_title')" class="purchase-order-dialog" fullscreen append-to-body>
      <main class="mx-auto grid max-w-7xl gap-8 lg:grid-cols-[minmax(0,1fr)_380px]">
        <div>
        <div class="mb-6 rounded-md border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800">{{ t('cart.review_notice') }}</div>
        <section class="overflow-hidden rounded-lg border border-slate-200">
          <div class="border-b border-slate-200 bg-slate-50 px-4 py-3 font-semibold text-slate-900">{{ t('cart.order_items') }}</div>
          <div class="divide-y divide-slate-200">
            <article v-for="item in cartItems" :key="item.id" class="grid grid-cols-[64px_minmax(0,1fr)] gap-3 p-4 sm:grid-cols-[72px_minmax(0,1fr)_100px_130px] sm:items-center">
              <div class="h-20 overflow-hidden rounded-md bg-slate-100">
                <el-image v-if="item.product.thumbnailUrl" :src="item.product.thumbnailUrl" :alt="cartProductName(item.product)" fit="cover" class="h-full w-full" />
                <span v-else class="flex h-full items-center justify-center text-slate-300"><Icon name="solar:gallery-wide-outline" size="25" /></span>
              </div>
              <div class="min-w-0"><p class="font-semibold text-slate-800">{{ cartProductName(item.product) }}</p><p class="mt-1 text-sm text-slate-500">{{ formatCartPrice(item.product.unitPrice - item.product.discount) }}</p></div>
              <div class="col-start-2 text-sm text-slate-600 sm:col-start-auto">{{ t('cart.quantity', { count: item.quantity }) }}</div>
              <div class="col-start-2 font-semibold text-slate-900 sm:col-start-auto sm:text-right">{{ formatCartPrice(item.quantity * Math.max(0, item.product.unitPrice - item.product.discount)) }}</div>
            </article>
          </div>
        </section>
        <div class="mt-6 grid gap-6 md:grid-cols-2">
          <section class="rounded-lg border border-slate-200 p-4">
            <h3 class="font-semibold text-slate-900">{{ t('cart.payment_method') }}</h3>
            <div v-if="selectedCartPaymentMethod" class="mt-4 flex items-center gap-3">
              <el-image v-if="selectedCartPaymentMethod.logoUrl" :src="selectedCartPaymentMethod.logoUrl" :alt="selectedCartPaymentMethod.name" fit="contain" class="h-12 w-16 rounded bg-white" />
              <span v-else class="flex h-12 w-16 items-center justify-center rounded bg-slate-100 text-slate-400"><Icon name="solar:card-outline" size="24" /></span>
              <span class="font-medium text-slate-800">{{ selectedCartPaymentMethod.name }}</span>
            </div>
          </section>
          <section class="space-y-3 rounded-lg border border-slate-200 p-4">
            <div class="flex justify-between text-slate-600"><span>{{ t('cart.subtotal') }}</span><span>{{ formatCartPrice(cartSubtotal) }}</span></div>
            <div class="flex justify-between text-rose-600"><span>{{ t('cart.total_discount') }}</span><span>-{{ formatCartPrice(cartDiscount) }}</span></div>
            <div class="flex justify-between border-t border-slate-200 pt-3 text-lg font-bold text-slate-900"><span>{{ t('cart.final_total') }}</span><span>{{ formatCartPrice(cartTotal) }}</span></div>
          </section>
        </div>
        </div>

        <aside class="lg:sticky lg:top-0 lg:self-start">
          <section class="rounded-xl border border-slate-200 bg-white p-5 text-center shadow-sm">
            <div class="flex items-center justify-center gap-3">
              <el-progress type="circle" :percentage="qrTimePercentage" :width="48" :stroke-width="5" color="#ef4444" :status="qrExpired ? 'exception' : undefined" :show-text="false" />
              <div class="text-left">
                <p class="text-sm font-medium text-slate-500">{{ qrExpired ? t('cart.qr_expired') : t('cart.qr_expires_in') }}</p>
                <p class="mt-0.5 font-mono text-2xl font-bold" :class="qrExpired ? 'text-rose-600' : 'text-slate-900'">{{ formattedQrTime }}</p>
              </div>
            </div>
            <div class="mx-auto mt-5 flex aspect-square w-full max-w-[320px] items-center justify-center overflow-hidden rounded-lg border border-slate-200 bg-white p-3">
              <el-image v-if="paymentQrUrl" :src="paymentQrUrl" :alt="t('cart.payment_qr')" fit="contain" class="h-full w-full" />
              <div v-else-if="qrGenerationError" class="px-4 text-sm text-rose-600">{{ qrGenerationError }}</div>
              <Icon v-else name="svg-spinners:ring-resize" size="34" class="text-slate-400" />
            </div>
            <div v-if="selectedCartPaymentMethod" class="mt-4 flex items-center justify-center gap-2 text-sm font-medium text-slate-700">
              <el-image v-if="selectedCartPaymentMethod.logoUrl" :src="selectedCartPaymentMethod.logoUrl" :alt="selectedCartPaymentMethod.name" fit="contain" class="h-7 w-9" />
              <span>{{ selectedCartPaymentMethod.name }}</span>
            </div>
            <div class="mt-5 border-t border-slate-200 pt-4">
              <p class="text-sm text-slate-500">{{ t('cart.amount_to_pay') }}</p>
              <p class="mt-1 text-3xl font-bold text-slate-900">{{ formatCartPrice(cartTotal) }}</p>
            </div>
          </section>
        </aside>
      </main>
    </el-dialog>

    <el-dialog v-model="purchaseHistoryDialogVisible" :title="t('purchase_history.title')" fullscreen append-to-body>
      <div v-loading="purchaseHistoryLoading" class="min-h-56">
        <div v-if="!purchaseHistoryLoading && purchaseHistory.length" class="space-y-4">
          <article v-for="order in purchaseHistory" :key="order.id" class="overflow-hidden rounded-lg border border-slate-200">
            <header class="flex flex-wrap items-center justify-between gap-3 bg-slate-50 px-4 py-3">
              <div>
                <p class="font-semibold text-slate-900">{{ order.code }}</p>
                <p class="mt-0.5 text-xs text-slate-500">{{ formatPurchaseDate(order.saleDate) }}</p>
              </div>
              <div class="flex items-center gap-3">
                <el-tag :type="order.status === 'completed' ? 'success' : 'warning'" effect="light">
                  {{ t(`purchase_history.status_${order.status}`) }}
                </el-tag>
                <span class="font-bold text-slate-900">{{ formatCartPrice(purchaseTotal(order)) }}</span>
              </div>
            </header>
            <div class="divide-y divide-slate-100 px-4">
              <div v-for="line in order.items" :key="line.id" class="grid grid-cols-[56px_minmax(0,1fr)_auto] items-center gap-3 py-3 text-sm">
                <div class="h-14 w-14 overflow-hidden rounded-md bg-slate-100">
                  <el-image v-if="line.product.imageUrl" :src="line.product.imageUrl" :alt="purchaseProductName(line.product)" fit="cover" class="h-full w-full" />
                  <span v-else class="flex h-full items-center justify-center text-slate-300"><Icon name="solar:gallery-wide-outline" size="21" /></span>
                </div>
                <div class="min-w-0">
                  <p class="truncate font-medium text-slate-800">{{ purchaseProductName(line.product) }}</p>
                  <p class="mt-0.5 text-xs text-slate-500">{{ t('purchase_history.quantity', { count: line.quantity }) }} × {{ formatCartPrice(line.unitPrice - line.discount) }}</p>
                </div>
                <span class="font-medium text-slate-700">{{ formatCartPrice(line.quantity * Math.max(0, line.unitPrice - line.discount)) }}</span>
              </div>
            </div>
            <footer class="flex flex-wrap items-center justify-between gap-2 border-t border-slate-200 bg-white px-4 py-3 text-sm text-slate-500">
              <span>{{ t('purchase_history.payment_method') }}: <strong class="font-medium text-slate-700">{{ order.paymentMethod?.name || '—' }}</strong></span>
              <span>{{ t('purchase_history.items', { count: purchaseQuantity(order) }) }}</span>
            </footer>
          </article>
        </div>
        <div v-else-if="!purchaseHistoryLoading" class="flex min-h-56 flex-col items-center justify-center text-center text-slate-400">
          <Icon name="lucide:receipt-text" size="44" />
          <p class="mt-3 text-sm">{{ t('purchase_history.empty') }}</p>
        </div>
      </div>
      <template #footer>
        <el-button @click="purchaseHistoryDialogVisible = false">{{ t('close') }}</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="profileDialogVisible" width="min(94vw, 620px)" align-center append-to-body :show-close="false" @closed="resetProfileEditor">
      <template #header>
        <div class="flex items-center justify-between border-b border-slate-200 pb-4">
          <div><h2 class="text-lg font-bold text-slate-900">{{ t('client_account.profile_title') }}</h2><p class="mt-1 text-sm text-slate-500">{{ t('client_account.profile_description') }}</p></div>
          <button type="button" class="flex h-9 w-9 items-center justify-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-slate-700" @click="profileDialogVisible = false"><Icon name="lucide:x" size="19" /></button>
        </div>
      </template>
      <div class="mb-6 flex flex-col items-center rounded-xl bg-gradient-to-br from-slate-900 to-slate-700 px-5 py-6 text-white sm:flex-row sm:text-left">
        <el-avatar :size="92" :src="profileAvatarPreview || undefined" class="border-4 border-white/25 bg-white/15 text-2xl">{{ profileFormInitials }}</el-avatar>
        <div class="mt-4 min-w-0 flex-1 sm:ml-5 sm:mt-0">
          <p class="truncate text-xl font-bold">{{ profileForm.fullName || customerName }}</p>
          <p class="mt-1 truncate text-sm text-white/70">{{ user?.email }}</p>
          <div class="mt-3 flex flex-wrap justify-center gap-2 sm:justify-start">
            <el-upload accept="image/jpeg,image/png,image/webp" :auto-upload="false" :show-file-list="false" :on-change="selectProfileAvatar"><el-button size="small" plain>{{ t('user_profile.choose_profile') }}</el-button></el-upload>
            <el-button v-if="profileAvatarPreview" size="small" plain @click="removeProfileAvatar">{{ t('user_profile.remove_profile') }}</el-button>
          </div>
          <p class="mt-2 text-xs text-white/55">{{ t('user_profile.profile_help') }}</p>
        </div>
      </div>
      <el-form ref="profileFormRef" :model="profileForm" :rules="profileRules" label-position="top" @submit.prevent="saveProfile">
        <div class="grid gap-x-4 sm:grid-cols-2">
          <el-form-item :label="t('sign_up.full_name')" prop="fullName"><el-input v-model="profileForm.fullName" clearable autocomplete="name"><template #prefix><Icon name="lucide:user-round" /></template></el-input></el-form-item>
          <el-form-item :label="t('sign_up.phone')" prop="phone"><el-input v-model="profileForm.phone" clearable autocomplete="tel"><template #prefix><Icon name="lucide:phone" /></template></el-input></el-form-item>
        </div>
        <el-form-item :label="t('client_account.email')"><el-input :model-value="user?.email" disabled><template #prefix><Icon name="lucide:mail" /></template></el-input><p class="mt-1.5 text-xs text-slate-400">{{ t('client_account.email_help') }}</p></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="profileDialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" :loading="savingProfile" @click="saveProfile">{{ t('save') }}</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="passwordDialogVisible" :title="t('headers.change_password')" width="min(92vw, 460px)" align-center append-to-body @closed="resetPasswordForm">
      <el-form ref="passwordFormRef" :model="passwordForm" :rules="passwordRules" label-position="top" @submit.prevent="changePassword">
        <el-form-item :label="t('client_account.new_password')" prop="password">
          <el-input v-model="passwordForm.password" type="password" show-password autocomplete="new-password" />
        </el-form-item>
        <el-form-item :label="t('sign_up.confirm_password')" prop="confirmPassword">
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password autocomplete="new-password" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="passwordDialogVisible = false">{{ t('cancel') }}</el-button>
        <el-button type="primary" :loading="changingPassword" @click="changePassword">{{ t('client_account.update_password') }}</el-button>
      </template>
    </el-dialog>

    <main class="flex-1">
      <slot />
    </main>

    <footer class="mt-12 border-t border-slate-200 bg-slate-950 text-slate-300">
      <div class="mx-auto grid w-[90%] gap-10 py-12 sm:grid-cols-2 lg:grid-cols-4">
        <div>
          <NuxtLink to="/" class="inline-flex items-center gap-2 text-lg font-bold text-white">
            <Icon :name="t('app.icon')" size="34" />
            {{ t('app.title') }}
          </NuxtLink>
          <p class="mt-4 max-w-xs text-sm leading-6 text-slate-400">{{ t('footer.description') }}</p>
          <div class="mt-5 flex items-center gap-2">
            <button type="button" class="footer-icon-button" aria-label="Facebook"><Icon name="simple-icons:facebook" size="17" /></button>
            <button type="button" class="footer-icon-button" aria-label="Instagram"><Icon name="simple-icons:instagram" size="17" /></button>
            <button type="button" class="footer-icon-button" aria-label="Telegram"><Icon name="simple-icons:telegram" size="17" /></button>
          </div>
        </div>

        <div>
          <h2 class="text-sm font-semibold uppercase tracking-wider text-white">{{ t('footer.shop') }}</h2>
          <nav class="mt-4 flex flex-col items-start gap-3 text-sm">
            <NuxtLink to="/" class="footer-link">{{ t('footer.home') }}</NuxtLink>
            <NuxtLink to="/search" class="footer-link">{{ t('footer.all_products') }}</NuxtLink>
            <NuxtLink v-for="category in categories.slice(0, 4)" :key="category.id" :to="categoryPath(category)" class="footer-link">
              {{ categoryName(category) }}
            </NuxtLink>
          </nav>
        </div>

        <div>
          <h2 class="text-sm font-semibold uppercase tracking-wider text-white">{{ t('footer.account') }}</h2>
          <nav class="mt-4 flex flex-col items-start gap-3 text-sm">
            <button v-if="user" type="button" class="footer-link" @click="openProfileDialog">{{ t('headers.edit_profile') }}</button>
            <button v-if="user" type="button" class="footer-link" @click="handleAccountCommand('purchase-history')">{{ t('purchase_history.menu') }}</button>
            <NuxtLink v-else to="/auth/login" class="footer-link">{{ t('sign_up.sign_in') }}</NuxtLink>
            <NuxtLink v-if="!user" to="/auth/sign-up" class="footer-link">{{ t('sign_up.submit') }}</NuxtLink>
            <NuxtLink v-if="clientProfile?.role === 'admin'" to="/admin" class="footer-link">{{ t('menu.dashboard') }}</NuxtLink>
          </nav>
        </div>

        <div>
          <h2 class="text-sm font-semibold uppercase tracking-wider text-white">{{ t('footer.contact') }}</h2>
          <div class="mt-4 space-y-3 text-sm text-slate-400">
            <p class="flex items-start gap-2"><Icon name="lucide:map-pin" size="17" class="mt-0.5 shrink-0" />{{ t('footer.location') }}</p>
            <a href="mailto:support@fashionshop.com" class="footer-link flex items-center gap-2"><Icon name="lucide:mail" size="17" />support@fashionshop.com</a>
            <button type="button" class="footer-link flex items-center gap-2" @click="handleChangeLocalizaiton(locale === 'en' ? 'km' : 'en')">
              <Icon name="lucide:languages" size="17" />{{ locale === 'en' ? 'ខ្មែរ' : 'English' }}
            </button>
          </div>
        </div>
      </div>
      <div class="border-t border-slate-800">
        <div class="mx-auto flex w-[90%] flex-col gap-2 py-5 text-xs text-slate-500 sm:flex-row sm:items-center sm:justify-between">
          <p>© {{ currentYear }} {{ t('app.title') }}. {{ t('footer.rights') }}</p>
          <p>{{ t('footer.secure_payment') }}</p>
        </div>
      </div>
    </footer>
  </section>
</template>

<script setup lang="ts">
  import type { FormInstance, FormRules, UploadFile } from 'element-plus'
  import QRCode from 'qrcode'


  interface CategoryRow {
    id: number
    code: string
    name_en: string
    name_kh: string
    icon: string | null
    parent_id: number | null
  }

  interface Category extends CategoryRow {
    children: Category[]
  }

  interface CartProductRow {
    id: string; name_en: string; name_kh: string; unit_price: number; discount: number
    images: Array<{ image_path: string; is_active: boolean; sort_order: number }>
    stock: { stock_in: number; stock_out: number; stock_adjustment: number } | null
  }
  interface CartRow { id: number; quantity: number; product: CartProductRow }
  interface CartProduct { id: string; nameEn: string; nameKh: string; unitPrice: number; discount: number; available: number; thumbnailUrl: string | null }
  interface CartItem { id: number; quantity: number; product: CartProduct }
  interface CartPaymentMethod { id: number; name: string; logoUrl: string | null; bankAccount: string | null; currency: string | null; merchantCity: string; storeLabel: string | null }
  interface GeneratedKHQR { qr: string; md5: string; amount: number; billNumber: string; expiresAt: number }
  interface GenerateKHQRResponse { success: boolean; data: GeneratedKHQR }
  interface PaymentStatusResponse {
    success: boolean
    data: { paid: boolean; transaction: { toAccountId?: string; currency?: string; amount?: number | string } | null }
  }
  interface PurchaseProduct { id: string; name_en: string; name_kh: string; imageUrl: string | null }
  interface PurchaseProductRow { id: string; name_en: string; name_kh: string; images: Array<{ image_path: string; is_active: boolean; sort_order: number }> }
  interface PurchaseLine { id: number; quantity: number; unitPrice: number; discount: number; product: PurchaseProduct }
  interface PurchaseOrder { id: number; code: string; saleDate: string; status: 'draft' | 'completed'; paymentMethod: { id: number; name: string } | null; items: PurchaseLine[] }
  interface PurchaseOrderRow {
    id: number; code: string; sale_date: string; status: 'draft' | 'completed'
    payment_method: { id: number; name: string } | null
    items: Array<{ id: number; quantity: number; unit_price: number; discount: number; product: PurchaseProductRow }>
  }
  interface ClientProfile { id: number; userId: string; fullName: string; role: 'customer' | 'admin'; profile: string | null }

  const i18n = useI18n()
  const { locale, setLocale } = i18n
  const t = (key: string, params?: Record<string, string | number>) => params
    ? i18n.t(key, params)
    : i18n.t(key)
  const route = useRoute()
  const router = useRouter()
  const currentYear = new Date().getFullYear()
  const searchKeyword = ref(typeof route.query.q === 'string' ? route.query.q : '')
  const searchDialogVisible = ref(false)
  const handleChangeLocalizaiton = (e: any) => {
    setLocale(e);
  }

  const activeCategoryId = ref<number | null>(null)
  const categoryDrawerVisible = ref(false)
  const expandedMobileCategoryIds = ref<number[]>([])
  const defaultCategoryIcon = 'solar:tag-outline'
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const isGoogleUser = computed(() => {
    const provider = user.value?.app_metadata?.provider
    const providers = user.value?.app_metadata?.providers

    return provider === 'google'
      || (Array.isArray(providers) && providers.includes('google'))
  })
  const cartRefresh = useCartRefresh()
  const cartDrawerVisible = ref(false)
  const cartLoading = ref(false)
  const cartItems = ref<CartItem[]>([])
  const cartCount = ref(0)
  const removingCartItemId = ref<number | null>(null)
  const updatingCartItemId = ref<number | null>(null)
  const purchaseOrderDialogVisible = ref(false)
  const paymentQrUrl = ref('')
  const qrGenerationError = ref('')
  const qrSecondsRemaining = ref(0)
  const qrDurationSeconds = ref(1)
  let qrTimer: ReturnType<typeof setInterval> | null = null
  let paymentTimer: ReturnType<typeof setInterval> | null = null
  const checkingPayment = ref(false)
  const completingPayment = ref(false)
  const cartPaymentMethods = ref<CartPaymentMethod[]>([])
  const selectedPaymentMethodId = ref<number | null>(null)
  const imageBucket = 'fashion-images'
  const currentUserId = computed(() => {
    const authUser = user.value as { sub?: string; id?: string } | null
    return authUser?.sub || authUser?.id || null
  })
  const signingOut = ref(false)
  const profileDialogVisible = ref(false)
  const passwordDialogVisible = ref(false)
  const purchaseHistoryDialogVisible = ref(false)
  const purchaseHistoryLoading = ref(false)
  const purchaseHistory = ref<PurchaseOrder[]>([])
  const savingProfile = ref(false)
  const clientProfile = ref<ClientProfile | null>(null)
  const clientProfileLoading = ref(false)
  let clientProfileRequestId = 0
  const profileAvatarFile = ref<File | null>(null)
  const profileAvatarPreview = ref<string | null>(null)
  const removeStoredProfileAvatar = ref(false)
  const changingPassword = ref(false)
  const profileFormRef = ref<FormInstance>()
  const passwordFormRef = ref<FormInstance>()
  const profileForm = reactive({ fullName: '', phone: '' })
  const passwordForm = reactive({ password: '', confirmPassword: '' })
  const profileRules = computed<FormRules>(() => ({
    fullName: [
      { required: true, message: t('sign_up.full_name_required'), trigger: 'blur' },
      { min: 2, max: 100, message: t('sign_up.full_name_length'), trigger: 'blur' },
    ],
    phone: [{ pattern: /^\+?[0-9\s()-]{8,20}$/, message: t('sign_up.phone_invalid'), trigger: 'blur' }],
  }))
  const passwordRules = computed<FormRules>(() => ({
    password: [
      { required: true, message: t('sign_up.password_required'), trigger: 'blur' },
      { min: 8, message: t('sign_up.password_length'), trigger: 'blur' },
    ],
    confirmPassword: [
      { required: true, message: t('sign_up.confirm_password_required'), trigger: 'blur' },
      {
        validator: (_rule, value, callback) => {
          if (value !== passwordForm.password) callback(new Error(t('sign_up.password_mismatch')))
          else callback()
        },
        trigger: ['blur', 'change'],
      },
    ],
  }))
  const customerName = computed(() => {
    const fullName = clientProfile.value?.fullName
    return typeof fullName === 'string' && fullName.trim()
      ? fullName.trim()
      : t('client_account.account')
  })
  const customerInitials = computed(() => customerName.value.trim().split(/\s+/).slice(0, 2).map(part => part[0]?.toUpperCase()).join('') || '?')
  const profileFormInitials = computed(() => profileForm.fullName.trim().split(/\s+/).slice(0, 2).map(part => part[0]?.toUpperCase()).join('') || customerInitials.value)
  const resolveProfileAvatarUrl = (profile: string | null | undefined) => {
    const value = profile?.trim().replace(/^['"]|['"]$/g, '')
    if (!value) return ''

    const storageMarker = `/storage/v1/object/public/${imageBucket}/`
    const markerIndex = value.indexOf(storageMarker)
    if (markerIndex >= 0) {
      const objectPath = value.slice(markerIndex + storageMarker.length)
      return supabase.storage.from(imageBucket).getPublicUrl(objectPath).data.publicUrl
    }
    if (/^(https?:|data:|blob:)/i.test(value)) return value

    const storagePath = value.startsWith(`${imageBucket}/`)
      ? value.slice(imageBucket.length + 1)
      : value.replace(/^\/+/, '')
    return supabase.storage.from(imageBucket).getPublicUrl(storagePath).data.publicUrl
  }
  const profileAvatarUrl = computed(() => resolveProfileAvatarUrl(clientProfile.value?.profile))

  const loadClientProfile = async () => {
    const userId = currentUserId.value
    const requestId = ++clientProfileRequestId
    if (!userId) {
      clientProfile.value = null
      clientProfileLoading.value = false
      return
    }

    clientProfileLoading.value = true
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select('id, user_id, full_name, role, profile')
        .eq('user_id', userId)
        .maybeSingle()
      if (error) throw error
      if (requestId !== clientProfileRequestId || currentUserId.value !== userId) return
      clientProfile.value = data ? { id: data.id, userId: data.user_id, fullName: data.full_name, role: data.role, profile: data.profile } as ClientProfile : null
    } catch {
      if (requestId === clientProfileRequestId) clientProfile.value = null
    } finally {
      if (requestId === clientProfileRequestId) clientProfileLoading.value = false
    }
  }

  const handleAccountDropdownVisibility = (visible: boolean) => {
    if (visible && currentUserId.value) void loadClientProfile()
  }

  const purchaseProductName = (product: PurchaseProduct) => locale.value === 'km' ? product.name_kh : product.name_en
  const purchaseTotal = (order: PurchaseOrder) => order.items.reduce((total, line) => total + line.quantity * Math.max(0, line.unitPrice - line.discount), 0)
  const purchaseQuantity = (order: PurchaseOrder) => order.items.reduce((total, line) => total + line.quantity, 0)
  const formatPurchaseDate = (date: string) => new Intl.DateTimeFormat(locale.value === 'km' ? 'km-KH' : 'en-US', { dateStyle: 'medium' }).format(new Date(`${date}T00:00:00`))

  const loadPurchaseHistory = async () => {
    purchaseHistoryLoading.value = true
    try {
      const { data: authData, error: authError } = await supabase.auth.getUser()
      if (authError) throw authError
      if (!authData.user) throw new Error(t('cart.authentication_required'))

      const { data, error } = await supabase
        .from('sales')
        .select('id, code, sale_date, status, payment_method:payment_methods(id, name), items:sale_items(id, quantity, unit_price, discount, product:products(id, name_en, name_kh, images:product_images(image_path, is_active, sort_order)))')
        .eq('sale_to', authData.user.id)
        .order('sale_date', { ascending: false })
        .order('id', { ascending: false })
        .limit(50)
      if (error) throw error

      purchaseHistory.value = ((data ?? []) as unknown as PurchaseOrderRow[]).map(order => ({
        id: order.id,
        code: order.code,
        saleDate: order.sale_date,
        status: order.status,
        paymentMethod: order.payment_method,
        items: (order.items ?? []).map(line => {
          const image = [...(line.product.images ?? [])]
            .filter(entry => entry.is_active)
            .sort((a, b) => a.sort_order - b.sort_order)[0]
          return {
            id: line.id,
            quantity: Number(line.quantity),
            unitPrice: Number(line.unit_price),
            discount: Number(line.discount),
            product: {
              id: line.product.id,
              name_en: line.product.name_en,
              name_kh: line.product.name_kh,
              imageUrl: image ? supabase.storage.from(imageBucket).getPublicUrl(image.image_path).data.publicUrl : null,
            },
          }
        }),
      }))
    }
    catch (error: unknown) {
      purchaseHistory.value = []
      useNotification(error instanceof Error ? error.message : t('purchase_history.load_failed'), 'error')
    }
    finally {
      purchaseHistoryLoading.value = false
    }
  }

  const cartProductName = (product: CartProduct) => locale.value === 'km' ? product.nameKh : product.nameEn
  const formatCartPrice = (value: number) => new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD', minimumFractionDigits: 2,
  }).format(Math.max(0, value))
  const cartSubtotal = computed(() => cartItems.value.reduce(
    (total, item) => total + item.quantity * item.product.unitPrice, 0,
  ))
  const cartDiscount = computed(() => cartItems.value.reduce(
    (total, item) => total + item.quantity * item.product.discount, 0,
  ))
  const cartTotal = computed(() => Math.max(0, cartSubtotal.value - cartDiscount.value))
  const selectedCartPaymentMethod = computed(() => cartPaymentMethods.value.find(method => method.id === selectedPaymentMethodId.value) ?? null)
  const qrExpired = computed(() => qrSecondsRemaining.value <= 0)
  const qrTimePercentage = computed(() => Math.round((qrSecondsRemaining.value / qrDurationSeconds.value) * 100))
  const formattedQrTime = computed(() => {
    const minutes = Math.floor(qrSecondsRemaining.value / 60)
    const seconds = qrSecondsRemaining.value % 60
    return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
  })

  const loadCartPaymentMethods = async () => {
    const { data, error } = await supabase
      .from('payment_methods')
      .select('id, name, logo_path, bank_account, currency, merchant_city, store_label')
      .eq('is_active', true)
      .eq('is_cashed', false)
      .order('name')
    if (error) throw error
    cartPaymentMethods.value = (data ?? []).map(method => ({
      id: method.id,
      name: method.name,
      logoUrl: method.logo_path
        ? supabase.storage.from(imageBucket).getPublicUrl(method.logo_path).data.publicUrl
        : null,
      bankAccount: method.bank_account,
      currency: method.currency,
      merchantCity: method.merchant_city,
      storeLabel: method.store_label,
    }))
    if (!cartPaymentMethods.value.some(method => method.id === selectedPaymentMethodId.value)) {
      selectedPaymentMethodId.value = cartPaymentMethods.value[0]?.id ?? null
    }
  }

  const loadCart = async () => {
    const { data: authData, error: authError } = await supabase.auth.getUser()
    const userId = authData.user?.id
    if (authError || !userId) {
      cartItems.value = []
      cartCount.value = 0
      return
    }
    cartLoading.value = true
    try {
      const [cartResult] = await Promise.all([
        supabase.from('picked_products')
          .select('id, quantity, product:products!inner(id, name_en, name_kh, unit_price, discount, stock:stocks(stock_in, stock_out, stock_adjustment), images:product_images(image_path, is_active, sort_order))')
          .eq('picked_by_id', userId)
          .order('created_at', { ascending: false }),
        loadCartPaymentMethods(),
      ])
      const { data, error } = cartResult
      if (error) throw error
      cartItems.value = ((data ?? []) as unknown as CartRow[]).map(item => {
        const image = [...(item.product.images ?? [])].filter(entry => entry.is_active).sort((a, b) => a.sort_order - b.sort_order)[0]
        return {
          id: item.id,
          quantity: item.quantity,
          product: {
            id: item.product.id, nameEn: item.product.name_en, nameKh: item.product.name_kh,
            unitPrice: Number(item.product.unit_price), discount: Number(item.product.discount ?? 0),
            available: Math.max(0, Number(item.product.stock?.stock_in ?? 0) + Number(item.product.stock?.stock_adjustment ?? 0) - Number(item.product.stock?.stock_out ?? 0)),
            thumbnailUrl: image ? supabase.storage.from(imageBucket).getPublicUrl(image.image_path).data.publicUrl : null,
          },
        }
      })
      cartCount.value = cartItems.value.length
    } catch (error: unknown) {
      useNotification(error instanceof Error ? error.message : t('cart.load_failed'), 'error')
    } finally {
      cartLoading.value = false
    }
  }

  const openCart = async () => {
    if (!user.value) {
      await router.push({ path: '/auth/login', query: { redirect: route.fullPath } })
      return
    }
    cartDrawerVisible.value = true
  }

  const removeCartItem = async (item: CartItem) => {
    if (removingCartItemId.value !== null) return
    removingCartItemId.value = item.id
    try {
      const { data: authData, error: authError } = await supabase.auth.getUser()
      if (authError) throw authError
      if (!authData.user) throw new Error(t('cart.authentication_required'))
      const { error } = await supabase.from('picked_products').delete().eq('id', item.id).eq('picked_by_id', authData.user.id)
      if (error) throw error
      cartItems.value = cartItems.value.filter(entry => entry.id !== item.id)
      cartCount.value = cartItems.value.length
      cartRefresh.value += 1
      useNotification(t('cart.removed'))
    } catch (error: unknown) {
      useNotification(error instanceof Error ? error.message : t('cart.remove_failed'), 'error')
    } finally {
      removingCartItemId.value = null
    }
  }

  const changeCartQuantity = async (item: CartItem, amount: -1 | 1) => {
    const quantity = item.quantity + amount
    if (updatingCartItemId.value !== null || quantity < 1 || quantity > item.product.available) return
    updatingCartItemId.value = item.id
    try {
      const { data: authData, error: authError } = await supabase.auth.getUser()
      if (authError) throw authError
      if (!authData.user) throw new Error(t('cart.authentication_required'))
      const { error } = await supabase.from('picked_products').update({
        quantity,
        updated_at: new Date().toISOString(),
      }).eq('id', item.id).eq('picked_by_id', authData.user.id)
      if (error) throw error
      item.quantity = quantity
    } catch (error: unknown) {
      useNotification(error instanceof Error ? error.message : t('cart.quantity_update_failed'), 'error')
    } finally {
      updatingCartItemId.value = null
    }
  }

  const stopQrTimer = () => {
    if (qrTimer) clearInterval(qrTimer)
    qrTimer = null
  }

  const stopPaymentTimer = () => {
    if (paymentTimer) clearInterval(paymentTimer)
    paymentTimer = null
    checkingPayment.value = false
  }

  const savePaidSale = async (method: CartPaymentMethod) => {
    if (completingPayment.value) return
    completingPayment.value = true

    try {
      const now = new Date()
      const saleDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
      const { error } = await supabase.rpc('save_sale', {
        p_id: null,
        p_sale_date: saleDate,
        p_payment_method_id: method.id,
        p_description: 'Customer KHQR payment',
        p_status: 'completed',
        p_items: cartItems.value.map(item => ({ product_id: item.product.id, quantity: item.quantity })),
      })
      if (error) throw error

      const { data: authData } = await supabase.auth.getUser()
      if (authData.user) {
        await supabase.from('picked_products').delete().eq('picked_by_id', authData.user.id)
      }
      cartItems.value = []
      cartCount.value = 0
      cartRefresh.value += 1
      purchaseOrderDialogVisible.value = false
      void new Audio('/success-sound.mp3').play().catch(() => undefined)
      useNotification('Your payment is received')
    }
    catch (error: unknown) {
      useNotification(error instanceof Error ? error.message : 'Unable to save your paid order', 'error')
    }
    finally {
      completingPayment.value = false
    }
  }

  const checkPayment = async (md5: string, method: CartPaymentMethod, expectedAmount: number) => {
    if (checkingPayment.value || completingPayment.value || qrExpired.value) return
    checkingPayment.value = true
    try {
      const response = await $fetch<PaymentStatusResponse>('/api/khqr/payment-status', {
        method: 'POST',
        body: { md5 },
      })
      const transaction = response.data.transaction
      if (!response.data.paid || !transaction) return

      const paidAmount = Number(transaction.amount)
      const expectedCurrency = (method.currency || 'USD').trim().toUpperCase()
      const paidCurrency = transaction.currency?.trim().toUpperCase()
      const paidAccount = transaction.toAccountId?.trim().toLowerCase()
      const expectedAccount = method.bankAccount?.trim().toLowerCase()
      if (Math.abs(paidAmount - expectedAmount) > 0.001 || paidCurrency !== expectedCurrency || paidAccount !== expectedAccount) {
        stopPaymentTimer()
        useNotification('The received payment does not match this order', 'error')
        return
      }

      await savePaidSale(method)
    }
    catch (error: unknown) {
      stopPaymentTimer()
      useNotification(khqrErrorMessage(error), 'error')
    }
    finally {
      checkingPayment.value = false
    }
  }

  const startPaymentPolling = (md5: string, method: CartPaymentMethod, expectedAmount: number) => {
    stopPaymentTimer()
    void checkPayment(md5, method, expectedAmount)
    paymentTimer = setInterval(() => void checkPayment(md5, method, expectedAmount), 3000)
  }

  const startQrTimer = (expiresAt: number) => {
    stopQrTimer()
    const updateRemainingTime = () => {
      qrSecondsRemaining.value = Math.max(0, Math.ceil((expiresAt - Date.now()) / 1000))
      if (qrSecondsRemaining.value === 0) {
        stopQrTimer()
        stopPaymentTimer()
      }
    }
    qrDurationSeconds.value = Math.max(1, Math.ceil((expiresAt - Date.now()) / 1000))
    updateRemainingTime()
    if (qrSecondsRemaining.value > 0) qrTimer = setInterval(updateRemainingTime, 1000)
  }

  const khqrErrorMessage = (error: unknown) => {
    if (error && typeof error === 'object') {
      const fetchError = error as { data?: { statusMessage?: unknown; message?: unknown }; message?: unknown }
      const message = fetchError.data?.statusMessage ?? fetchError.data?.message ?? fetchError.message
      if (typeof message === 'string' && message) return message
    }
    return t('cart.qr_generate_failed')
  }

  const placeOrder = async () => {
    if (!selectedPaymentMethodId.value || !cartItems.value.length) return
    const method = selectedCartPaymentMethod.value
    if (!method) return
    stopQrTimer()
    qrSecondsRemaining.value = 0
    qrDurationSeconds.value = 1
    paymentQrUrl.value = ''
    qrGenerationError.value = ''
    cartDrawerVisible.value = false
    purchaseOrderDialogVisible.value = true
    try {
      const response = await $fetch<GenerateKHQRResponse>('/api/khqr/generate', {
        method: 'POST',
        body: {
          amount: Number(cartTotal.value.toFixed(2)),
          billNumber: `SAL-${Date.now()}`,
          paymentMethodId: method.id,
        },
      })
      if (!response.success || !response.data?.qr) throw new Error(t('cart.qr_generate_failed'))

      paymentQrUrl.value = await QRCode.toDataURL(response.data.qr, {
        width: 640,
        margin: 2,
        errorCorrectionLevel: 'M',
      })
      startQrTimer(response.data.expiresAt)
      startPaymentPolling(response.data.md5, method, Number(cartTotal.value.toFixed(2)))
    } catch (error: unknown) {
      qrGenerationError.value = khqrErrorMessage(error)
      stopQrTimer()
    }
  }

  watch(purchaseOrderDialogVisible, visible => {
    if (!visible) {
      stopQrTimer()
      stopPaymentTimer()
    }
  })
  onBeforeUnmount(() => {
    stopQrTimer()
    stopPaymentTimer()
    if (profileAvatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(profileAvatarPreview.value)
  })

  const resetProfileEditor = () => {
    profileFormRef.value?.clearValidate()
    if (profileAvatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(profileAvatarPreview.value)
    profileAvatarFile.value = null
    profileAvatarPreview.value = null
    removeStoredProfileAvatar.value = false
  }

  const selectProfileAvatar = (upload: UploadFile) => {
    const file = upload.raw
    if (!file) return
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) { useNotification(t('user_profile.invalid_profile'), 'error'); return }
    if (file.size > 2 * 1024 * 1024) { useNotification(t('user_profile.profile_too_large'), 'error'); return }
    if (profileAvatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(profileAvatarPreview.value)
    profileAvatarFile.value = file
    profileAvatarPreview.value = URL.createObjectURL(file)
    removeStoredProfileAvatar.value = false
  }

  const removeProfileAvatar = () => {
    if (profileAvatarPreview.value?.startsWith('blob:')) URL.revokeObjectURL(profileAvatarPreview.value)
    profileAvatarFile.value = null
    profileAvatarPreview.value = null
    removeStoredProfileAvatar.value = true
  }

  const uploadProfileAvatar = async (file: File, userId: string) => {
    const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
    const path = `user-profiles/${userId}/${crypto.randomUUID()}.${extension}`
    const { error } = await supabase.storage.from(imageBucket).upload(path, file, { contentType: file.type, cacheControl: '3600' })
    if (error) throw error
    return path
  }

  const openProfileDialog = async () => {
    if (!currentUserId.value) return
    await loadClientProfile()
    profileForm.fullName = clientProfile.value?.fullName || ''
    profileForm.phone = typeof user.value?.user_metadata?.phone === 'string'
      ? user.value.user_metadata.phone
      : ''
    profileAvatarPreview.value = profileAvatarUrl.value || null
    profileAvatarFile.value = null
    removeStoredProfileAvatar.value = false
    profileDialogVisible.value = true
    await nextTick()
    profileFormRef.value?.clearValidate()
  }

  const handleAccountCommand = async (command: string) => {
    if (command === 'sign-in') {
      await router.push({ path: '/auth/login', query: { redirect: route.fullPath } })
      return
    }

    if (command === 'admin-dashboard') {
      if (clientProfile.value?.role === 'admin') await router.push('/admin')
      return
    }

    if (command === 'change-password') {
      passwordDialogVisible.value = true
      return
    }

    if (command === 'purchase-history') {
      purchaseHistoryDialogVisible.value = true
      await loadPurchaseHistory()
      return
    }

    if (command !== 'sign-out' || signingOut.value) return

    signingOut.value = true
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      useNotification(t('client_account.signed_out'))
      await router.replace('/')
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : t('client_account.sign_out_failed')
      useNotification(message, 'error')
    } finally {
      signingOut.value = false
    }
  }

  const saveProfile = async () => {
    const valid = await profileFormRef.value?.validate().catch(() => false)
    if (!valid || savingProfile.value) return

    savingProfile.value = true
    let uploadedProfilePath: string | null = null
    let authProfileUpdated = false
    const oldProfilePath = clientProfile.value?.profile ?? null
    try {
      const userId = currentUserId.value
      if (!userId) throw new Error(t('cart.authentication_required'))
      if (profileAvatarFile.value) uploadedProfilePath = await uploadProfileAvatar(profileAvatarFile.value, userId)
      const nextProfilePath = uploadedProfilePath ?? (removeStoredProfileAvatar.value ? null : oldProfilePath)
      const { error } = await supabase.auth.updateUser({
        data: {
          ...user.value?.user_metadata,
          full_name: profileForm.fullName.trim(),
          phone: profileForm.phone.trim() || null,
          profile: nextProfilePath,
        },
      })
      if (error) throw error
      authProfileUpdated = true
      const { error: profileError } = await supabase.from('user_profiles').update({
        full_name: profileForm.fullName.trim(),
        profile: nextProfilePath,
        updated_at: new Date().toISOString(),
      }).eq('user_id', userId)
      if (profileError) throw profileError
      if (oldProfilePath && oldProfilePath !== nextProfilePath) await supabase.storage.from(imageBucket).remove([oldProfilePath])
      await loadClientProfile()
      useNotification(t('client_account.profile_updated'))
      profileDialogVisible.value = false
    } catch (error: unknown) {
      if (uploadedProfilePath && !authProfileUpdated) await supabase.storage.from(imageBucket).remove([uploadedProfilePath])
      const message = error instanceof Error ? error.message : t('client_account.profile_update_failed')
      useNotification(message, 'error')
    } finally {
      savingProfile.value = false
    }
  }

  const resetPasswordForm = () => {
    passwordForm.password = ''
    passwordForm.confirmPassword = ''
    passwordFormRef.value?.clearValidate()
  }

  const changePassword = async () => {
    const valid = await passwordFormRef.value?.validate().catch(() => false)
    if (!valid || changingPassword.value) return

    changingPassword.value = true
    try {
      const { error } = await supabase.auth.updateUser({ password: passwordForm.password })
      if (error) throw error
      useNotification(t('client_account.password_updated'))
      passwordDialogVisible.value = false
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : t('client_account.password_update_failed')
      useNotification(message, 'error')
    } finally {
      changingPassword.value = false
    }
  }

  watch(() => route.query.q, value => {
    searchKeyword.value = typeof value === 'string' ? value : ''
  })

  watch([currentUserId, cartRefresh], () => loadCart(), { immediate: true })
  watch(currentUserId, () => loadClientProfile(), { immediate: true })

  const submitSearch = () => {
    const keyword = searchKeyword.value.trim()
    closeDropdown()
    router.push({ path: '/search', query: keyword ? { q: keyword } : {} })
  }

  const submitMobileSearch = async () => {
    searchDialogVisible.value = false
    await nextTick()
    submitSearch()
  }

  const { data: categoryRows } = await useAsyncData('client-categories', async () => {
    const { data, error } = await supabase
      .from('categories')
      .select('id, code, name_en, name_kh, icon, parent_id')
      .eq('is_active', true)
      .order('name_en')

    // Navigation categories are optional. Keep public pages renderable when
    // Supabase is temporarily unavailable instead of failing SSR with 500.
    if (error) return []
    return (data ?? []) as CategoryRow[]
  }, { default: () => [] })

  const categories = computed<Category[]>(() => {
    const nodes = new Map<number, Category>()
    for (const row of categoryRows.value) nodes.set(row.id, { ...row, children: [] })

    const roots: Category[] = []
    for (const category of nodes.values()) {
      const parent = category.parent_id === null ? null : nodes.get(category.parent_id)
      if (parent) parent.children.push(category)
      else roots.push(category)
    }
    return roots
  })

  const categoryName = (category: Category) => {
    return locale.value === 'km' ? category.name_kh : category.name_en;
  };

  const categoryPath = (category: Category) => ({
    path: '/category',
    query: { 'category-code': category.code },
  });

  const openDropdown = (categoryId: number) => {
    activeCategoryId.value = categoryId;
  };

  const closeDropdown = () => {
    activeCategoryId.value = null;
  };

  const toggleDropdown = (categoryId: number) => {
    activeCategoryId.value = activeCategoryId.value === categoryId
      ? null
      : categoryId;
  };

  const toggleMobileCategory = (categoryId: number) => {
    expandedMobileCategoryIds.value = expandedMobileCategoryIds.value.includes(categoryId)
      ? expandedMobileCategoryIds.value.filter(id => id !== categoryId)
      : [categoryId]
  }
</script>

<style scoped>
  .category-trigger {
    display: flex;
    height: 100%;
    align-items: center;
    gap: 0.25rem;
    border-bottom: 2px solid transparent;
    color: #374151;
    font-size: 0.875rem;
    transition: color 150ms ease, border-color 150ms ease;
  }

  .category-trigger:hover,
  .category-trigger--active {
    border-bottom-color: #111827;
    color: #111827;
  }

  .category-dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    width: 100%;
    min-height: 250px;
    border-top: 1px solid #f3f4f6;
    background: #fff;
    box-shadow: 0 12px 24px rgb(0 0 0 / 8%);
  }

  .category-thumbnail {
    display: flex;
    width: 2.25rem;
    height: 2.25rem;
    flex: 0 0 2.25rem;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    border-radius: 9999px;
    background: #f3f4f6;
  }

  .category-menu-enter-active,
  .category-menu-leave-active {
    transition: opacity 150ms ease, transform 150ms ease;
    transform-origin: top;
  }

  .category-menu-enter-from,
  .category-menu-leave-to {
    opacity: 0;
    transform: translateY(-4px);
  }

  .mobile-category-collapse-enter-active,
  .mobile-category-collapse-leave-active {
    transition: opacity 180ms ease, transform 180ms ease;
    transform-origin: top;
  }

  .mobile-category-collapse-enter-from,
  .mobile-category-collapse-leave-to {
    opacity: 0;
    transform: translateY(-6px);
  }

  .footer-link {
    color: rgb(148 163 184);
    transition: color 150ms ease;
  }

  .footer-link:hover {
    color: #fff;
  }

  .footer-icon-button {
    display: inline-flex;
    width: 2.25rem;
    height: 2.25rem;
    align-items: center;
    justify-content: center;
    border: 1px solid rgb(51 65 85);
    border-radius: 9999px;
    color: rgb(148 163 184);
    transition: border-color 150ms ease, color 150ms ease, background-color 150ms ease;
  }

  .footer-icon-button:hover {
    border-color: rgb(100 116 139);
    background: rgb(30 41 59);
    color: #fff;
  }

  :global(.purchase-order-dialog) {
    scrollbar-width: none;
    -ms-overflow-style: none;
  }

  :global(.purchase-order-dialog::-webkit-scrollbar) {
    display: none;
  }
</style>
