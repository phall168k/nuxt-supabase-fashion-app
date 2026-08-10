<template>
  <div v-loading="loading" class="min-h-[calc(100vh-104px)] space-y-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-bold text-slate-900">{{ t('dashboard.overview') }}</h2>
        <p class="mt-1 text-sm text-slate-500">{{ t('dashboard.description') }}</p>
      </div>
      <el-button :loading="loading" @click="loadDashboard">
        <Icon name="lucide:refresh-cw" size="16" class="mr-1.5" />
        {{ t('dashboard.refresh') }}
      </el-button>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <article v-for="card in summaryCards" :key="card.label" class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <span class="flex h-11 w-11 items-center justify-center rounded-lg" :class="card.iconClass">
            <Icon :name="card.icon" size="22" />
          </span>
          <span class="text-xs font-medium text-slate-400">{{ t('dashboard.all_time') }}</span>
        </div>
        <p class="mt-4 text-sm font-medium text-slate-500">{{ card.label }}</p>
        <p class="mt-1 text-2xl font-bold tracking-tight text-slate-900">{{ card.value }}</p>
      </article>
    </div>

    <div class="grid gap-5 xl:grid-cols-[minmax(0,2fr)_minmax(300px,1fr)]">
      <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="mb-5">
          <h3 class="font-semibold text-slate-900">{{ t('dashboard.revenue_chart') }}</h3>
          <p class="mt-1 text-xs text-slate-500">{{ t('dashboard.last_seven_days') }}</p>
        </div>
        <div class="relative h-72"><canvas ref="revenueCanvas" /></div>
      </section>

      <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="mb-5">
          <h3 class="font-semibold text-slate-900">{{ t('dashboard.payment_chart') }}</h3>
          <p class="mt-1 text-xs text-slate-500">{{ t('dashboard.completed_orders') }}</p>
        </div>
        <div class="relative h-72"><canvas ref="paymentCanvas" /></div>
      </section>
    </div>

    <div class="grid gap-5 xl:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)]">
      <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="mb-5">
          <h3 class="font-semibold text-slate-900">{{ t('dashboard.top_products') }}</h3>
          <p class="mt-1 text-xs text-slate-500">{{ t('dashboard.by_quantity_sold') }}</p>
        </div>
        <div class="relative h-72"><canvas ref="productsCanvas" /></div>
      </section>

      <section class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-200 px-5 py-4">
          <h3 class="font-semibold text-slate-900">{{ t('dashboard.stock_attention') }}</h3>
          <p class="mt-1 text-xs text-slate-500">{{ t('dashboard.low_stock_description') }}</p>
        </div>
        <div v-if="lowStockProducts.length" class="divide-y divide-slate-100 px-5">
          <div v-for="item in lowStockProducts" :key="item.id" class="flex items-center justify-between gap-4 py-3">
            <div class="min-w-0">
              <p class="truncate text-sm font-medium text-slate-800">{{ localizedProductName(item) }}</p>
              <p class="mt-0.5 text-xs text-slate-400">{{ item.code }}</p>
            </div>
            <el-tag :type="item.available <= 0 ? 'danger' : 'warning'" effect="light">
              {{ t('dashboard.units_left', { count: item.available }) }}
            </el-tag>
          </div>
        </div>
        <div v-else class="flex h-56 flex-col items-center justify-center text-slate-400">
          <Icon name="lucide:circle-check-big" size="34" />
          <p class="mt-2 text-sm">{{ t('dashboard.stock_healthy') }}</p>
        </div>
      </section>
    </div>

    <section class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="border-b border-slate-200 px-5 py-4">
        <h3 class="font-semibold text-slate-900">{{ t('dashboard.recent_orders') }}</h3>
      </div>
      <el-table :data="recentOrders" class="w-full" empty-text="No orders">
        <el-table-column prop="code" :label="t('dashboard.order')" min-width="145" />
        <el-table-column :label="t('dashboard.date')" min-width="135">
          <template #default="{ row }">{{ formatDate(row.saleDate) }}</template>
        </el-table-column>
        <el-table-column :label="t('dashboard.payment_method')" min-width="160">
          <template #default="{ row }">{{ row.paymentMethod }}</template>
        </el-table-column>
        <el-table-column :label="t('dashboard.items')" width="100" align="center">
          <template #default="{ row }">{{ row.quantity }}</template>
        </el-table-column>
        <el-table-column :label="t('dashboard.total')" min-width="130" align="right">
          <template #default="{ row }"><strong>{{ formatCurrency(row.total) }}</strong></template>
        </el-table-column>
        <el-table-column :label="t('dashboard.status')" width="120" align="center">
          <template #default><el-tag type="success" effect="light">{{ t('dashboard.completed') }}</el-tag></template>
        </el-table-column>
      </el-table>
    </section>
  </div>
</template>

<script setup lang="ts">
import Chart from 'chart.js/auto'

interface SaleRow {
  id: number
  code: string
  sale_date: string
  sale_to: string
  payment_method: { name: string } | null
  items: Array<{ quantity: number; unit_price: number; discount: number; product: { id: number; name_en: string; name_kh: string } }>
}

interface StockRow {
  id: number
  stock_in: number
  stock_out: number
  stock_adjustment: number
  product: { id: number; code: string; name_en: string; name_kh: string }
}

interface LowStockProduct { id: number; code: string; nameEn: string; nameKh: string; available: number }
interface RecentOrder { id: number; code: string; saleDate: string; paymentMethod: string; quantity: number; total: number }

definePageMeta({ layout: 'default' })
useHead({ title: 'Dashboard | Fashion Shop' })

const { t, locale } = useI18n()
const supabase = useSupabaseClient()
const breadcrumbStore = useBreadcrumbStore()
const loading = ref(false)
const revenue = ref(0)
const orderCount = ref(0)
const customerCount = ref(0)
const productCount = ref(0)
const lowStockProducts = ref<LowStockProduct[]>([])
const recentOrders = ref<RecentOrder[]>([])
const sales = ref<SaleRow[]>([])
const revenueCanvas = ref<HTMLCanvasElement>()
const paymentCanvas = ref<HTMLCanvasElement>()
const productsCanvas = ref<HTMLCanvasElement>()
let revenueChart: Chart | null = null
let paymentChart: Chart | null = null
let productsChart: Chart | null = null

watchEffect(() => {
  breadcrumbStore.setPageTitle(t('dashboard.title'))
  breadcrumbStore.setBreadcrumbs([t('dashboard.title')])
})

const formatCurrency = (value: number) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
const formatNumber = (value: number) => new Intl.NumberFormat(locale.value === 'km' ? 'km-KH' : 'en-US').format(value)
const formatDate = (date: string) => new Intl.DateTimeFormat(locale.value === 'km' ? 'km-KH' : 'en-US', { dateStyle: 'medium' }).format(new Date(`${date}T00:00:00`))
const localizedProductName = (item: LowStockProduct) => locale.value === 'km' ? item.nameKh : item.nameEn
const saleTotal = (sale: SaleRow) => sale.items.reduce((sum, item) => sum + Number(item.quantity) * Math.max(0, Number(item.unit_price) - Number(item.discount)), 0)
const saleQuantity = (sale: SaleRow) => sale.items.reduce((sum, item) => sum + Number(item.quantity), 0)

const summaryCards = computed(() => [
  { label: t('dashboard.total_revenue'), value: formatCurrency(revenue.value), icon: 'solar:dollar-minimalistic-linear', iconClass: 'bg-emerald-50 text-emerald-600' },
  { label: t('dashboard.total_orders'), value: formatNumber(orderCount.value), icon: 'solar:bag-check-outline', iconClass: 'bg-blue-50 text-blue-600' },
  { label: t('dashboard.customers'), value: formatNumber(customerCount.value), icon: 'solar:users-group-rounded-outline', iconClass: 'bg-violet-50 text-violet-600' },
  { label: t('dashboard.products'), value: formatNumber(productCount.value), icon: 'solar:t-shirt-outline', iconClass: 'bg-amber-50 text-amber-600' },
])

const chartTextColor = '#64748b'
const destroyCharts = () => {
  revenueChart?.destroy(); paymentChart?.destroy(); productsChart?.destroy()
  revenueChart = null; paymentChart = null; productsChart = null
}

const renderCharts = async () => {
  if (!import.meta.client) return
  await nextTick()
  destroyCharts()

  const days = Array.from({ length: 7 }, (_, offset) => {
    const date = new Date(); date.setHours(0, 0, 0, 0); date.setDate(date.getDate() - (6 - offset)); return date
  })
  const revenueByDay = days.map(day => sales.value.filter(sale => sale.sale_date === day.toISOString().slice(0, 10)).reduce((sum, sale) => sum + saleTotal(sale), 0))
  if (revenueCanvas.value) revenueChart = new Chart(revenueCanvas.value, {
    type: 'line',
    data: { labels: days.map(day => new Intl.DateTimeFormat(locale.value === 'km' ? 'km-KH' : 'en-US', { month: 'short', day: 'numeric' }).format(day)), datasets: [{ label: t('dashboard.revenue'), data: revenueByDay, borderColor: '#2563eb', backgroundColor: 'rgba(37,99,235,.12)', fill: true, tension: 0.35, pointRadius: 3 }] },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { grid: { display: false }, ticks: { color: chartTextColor } }, y: { beginAtZero: true, ticks: { color: chartTextColor, callback: value => `$${Number(value).toLocaleString()}` } } } },
  })

  const payments = new Map<string, number>()
  for (const sale of sales.value) payments.set(sale.payment_method?.name || t('dashboard.unknown'), (payments.get(sale.payment_method?.name || t('dashboard.unknown')) || 0) + 1)
  if (paymentCanvas.value) paymentChart = new Chart(paymentCanvas.value, {
    type: 'doughnut',
    data: { labels: [...payments.keys()], datasets: [{ data: [...payments.values()], backgroundColor: ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444'], borderWidth: 0 }] },
    options: { responsive: true, maintainAspectRatio: false, cutout: '68%', plugins: { legend: { position: 'bottom', labels: { color: chartTextColor, usePointStyle: true, padding: 16 } } } },
  })

  const sold = new Map<number, { nameEn: string; nameKh: string; quantity: number }>()
  for (const sale of sales.value) for (const item of sale.items) {
    const current = sold.get(item.product.id) || { nameEn: item.product.name_en, nameKh: item.product.name_kh, quantity: 0 }
    current.quantity += Number(item.quantity); sold.set(item.product.id, current)
  }
  const top = [...sold.values()].sort((a, b) => b.quantity - a.quantity).slice(0, 5)
  if (productsCanvas.value) productsChart = new Chart(productsCanvas.value, {
    type: 'bar',
    data: { labels: top.map(item => locale.value === 'km' ? item.nameKh : item.nameEn), datasets: [{ label: t('dashboard.units_sold'), data: top.map(item => item.quantity), backgroundColor: '#8b5cf6', borderRadius: 6 }] },
    options: { responsive: true, maintainAspectRatio: false, indexAxis: 'y', plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true, ticks: { color: chartTextColor, precision: 0 } }, y: { grid: { display: false }, ticks: { color: chartTextColor } } } },
  })
}

const loadDashboard = async () => {
  if (loading.value) return
  loading.value = true
  try {
    const [salesResult, stocksResult, productsResult] = await Promise.all([
      supabase.from('sales').select('id, code, sale_date, sale_to, payment_method:payment_methods(name), items:sale_items(quantity, unit_price, discount, product:products(id, name_en, name_kh))').eq('status', 'completed').order('sale_date', { ascending: false }).order('id', { ascending: false }),
      supabase.from('stocks').select('id, stock_in, stock_out, stock_adjustment, product:products!inner(id, code, name_en, name_kh)'),
      supabase.from('products').select('id', { count: 'exact', head: true }),
    ])
    if (salesResult.error) throw salesResult.error
    if (stocksResult.error) throw stocksResult.error
    if (productsResult.error) throw productsResult.error

    sales.value = (salesResult.data ?? []) as unknown as SaleRow[]
    productCount.value = productsResult.count ?? 0
    orderCount.value = sales.value.length
    customerCount.value = new Set(sales.value.map(sale => sale.sale_to)).size
    revenue.value = sales.value.reduce((sum, sale) => sum + saleTotal(sale), 0)
    recentOrders.value = sales.value.slice(0, 8).map(sale => ({ id: sale.id, code: sale.code, saleDate: sale.sale_date, paymentMethod: sale.payment_method?.name || '—', quantity: saleQuantity(sale), total: saleTotal(sale) }))
    lowStockProducts.value = ((stocksResult.data ?? []) as unknown as StockRow[]).map(row => ({ id: row.product.id, code: row.product.code, nameEn: row.product.name_en, nameKh: row.product.name_kh, available: Number(row.stock_in) + Number(row.stock_adjustment) - Number(row.stock_out) })).filter(item => item.available <= 5).sort((a, b) => a.available - b.available).slice(0, 6)
    await renderCharts()
  }
  catch (error: unknown) {
    useNotification(error instanceof Error ? error.message : t('dashboard.load_failed'), 'error')
  }
  finally { loading.value = false }
}

watch(locale, renderCharts)
onMounted(loadDashboard)
onBeforeUnmount(destroyCharts)
</script>
