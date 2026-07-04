<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { logout, getMe, getAssets, getCompanies, getLocations } from '../lib/api'
import { gsap } from 'gsap'
import AssetsTable from '../components/AssetsTable.vue'
import ExpenseCharts from '../components/ExpenseCharts.vue'

interface DashboardAsset {
  id: string
  name: string
  details: any
  serial_number: string | null
  company_id: string
  location_id: string | null
  bill_url: string | null
  created_at: string
  acknowledged_at: string | null
  companies?: { name: string } | null
  locations?: { name: string } | null
}

const router = useRouter()
const isLoading = ref(true)
const user = ref<{ id: string; email: string } | null>(null)
const dashboardContainer = ref<HTMLElement | null>(null)

const assets = ref<DashboardAsset[]>([])
const companies = ref<Array<{ id: string; name: string }>>([])
const locations = ref<Array<{ id: string; name: string; company_id: string }>>([])
const statsLoading = ref(true)

const assetCost = (a: DashboardAsset): number =>
  typeof a.details?.cost === 'number' && !Number.isNaN(a.details.cost) ? a.details.cost : 0

const inr = (n: number) => '₹' + Math.round(n).toLocaleString('en-IN')

const totalAssets = computed(() => assets.value.length)
const totalValue = computed(() => assets.value.reduce((s, a) => s + assetCost(a), 0))
const pendingCount = computed(() => assets.value.filter((a) => !a.acknowledged_at).length)
const activeLocations = computed(
  () => new Set(assets.value.map((a) => a.location_id).filter(Boolean)).size
)
const withBills = computed(() => assets.value.filter((a) => a.bill_url).length)

const recentAssets = computed(() =>
  [...assets.value]
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 6)
)

const handleLogout = () => {
  logout()
  router.push('/login')
}

const checkAuth = async () => {
  try {
    const me = await getMe()
    if (!me?.user) {
      router.push({ path: '/login', query: { reason: 'session_invalid' } })
      return
    }
    user.value = me.user
  } catch {
    router.push({ path: '/login', query: { reason: 'session_invalid' } })
    return
  } finally {
    isLoading.value = false
  }
}

const loadDashboardData = async () => {
  try {
    statsLoading.value = true
    const [assetsRes, companiesRes, locationsRes] = await Promise.all([
      getAssets(),
      getCompanies(),
      getLocations()
    ])
    assets.value = Array.isArray(assetsRes) ? assetsRes : []
    companies.value = companiesRes || []
    locations.value = locationsRes || []
  } catch (err) {
    console.error('Failed to load dashboard data:', err)
  } finally {
    statsLoading.value = false
  }
}

const formatDate = (iso: string) =>
  new Date(iso).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' })

onMounted(async () => {
  await checkAuth()
  if (user.value) loadDashboardData()

  if (dashboardContainer.value) {
    const cards = dashboardContainer.value.querySelectorAll('.bento-card')
    gsap.from(cards, {
      opacity: 0,
      y: 24,
      duration: 0.5,
      stagger: 0.06,
      ease: 'power3.out',
      clearProps: 'opacity,transform'
    })
  }
})
</script>

<template>
  <div v-if="isLoading" class="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
    <div class="text-slate-700 text-xl font-medium">Loading...</div>
  </div>

  <div v-else class="min-h-screen bg-slate-50">
    <div ref="dashboardContainer" class="relative z-10">
      <!-- Header -->
      <header class="sticky top-0 z-50 bg-white border-b border-slate-200 shadow-sm">
        <div class="max-w-7xl mx-auto px-6 lg:px-8 py-4">
          <div class="flex justify-between items-center gap-4">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-sm shrink-0">
                <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M11.25 3.03a.75.75 0 01.75 0l8.25 4.76a.75.75 0 010 1.3L12 13.85 3.75 9.09a.75.75 0 010-1.3l7.5-4.76z" opacity=".9"/>
                  <path d="M3 11.38l8.25 4.77v5.32L3.38 16.9A.75.75 0 013 16.25v-4.87zM21 11.38v4.87a.75.75 0 01-.38.65l-7.87 4.57v-5.32L21 11.38z"/>
                </svg>
              </div>
              <div>
                <h1 class="text-2xl font-semibold text-slate-900">Asset Tracker</h1>
                <p class="text-sm text-slate-500 mt-0.5">Welcome back, {{ user?.email }}</p>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <a
                href="/onboarding"
                class="inline-flex items-center px-4 py-2 text-sm font-semibold text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-all duration-200 shadow-sm"
              >
                <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Add Asset
              </a>
              <button
                @click="handleLogout"
                class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-all duration-200"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-7xl mx-auto px-6 lg:px-8 py-6">
        <!-- KPI Cards -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div class="bento-card bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Total Assets</p>
                <p class="text-3xl font-bold text-slate-900">{{ statsLoading ? '—' : totalAssets }}</p>
                <p class="text-xs text-slate-500 mt-1">{{ statsLoading ? '' : `${withBills} with bills attached` }}</p>
              </div>
              <div class="w-11 h-11 bg-indigo-100 rounded-lg flex items-center justify-center shrink-0">
                <svg class="w-6 h-6 text-indigo-600" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M3.375 3C2.339 3 1.5 3.84 1.5 4.875v.75c0 1.036.84 1.875 1.875 1.875h17.25c1.035 0 1.875-.84 1.875-1.875v-.75C22.5 3.839 21.66 3 20.625 3H3.375z" />
                  <path fill-rule="evenodd" d="M3.087 9l.54 9.176A3 3 0 006.62 21h10.757a3 3 0 002.995-2.824L20.913 9H3.087zm6.163 3.75A.75.75 0 0110 12h4a.75.75 0 010 1.5h-4a.75.75 0 01-.75-.75z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>

          <div class="bento-card bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Total Value</p>
                <p class="text-3xl font-bold text-slate-900">{{ statsLoading ? '—' : inr(totalValue) }}</p>
                <p class="text-xs text-slate-500 mt-1">across all locations</p>
              </div>
              <div class="w-11 h-11 bg-emerald-100 rounded-lg flex items-center justify-center shrink-0">
                <svg class="w-6 h-6 text-emerald-600" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 7.5a2.25 2.25 0 100 4.5 2.25 2.25 0 000-4.5z" />
                  <path fill-rule="evenodd" d="M1.5 4.875C1.5 3.839 2.34 3 3.375 3h17.25c1.035 0 1.875.84 1.875 1.875v9.75c0 1.036-.84 1.875-1.875 1.875H3.375A1.875 1.875 0 011.5 14.625v-9.75zM8.25 9.75a3.75 3.75 0 117.5 0 3.75 3.75 0 01-7.5 0zM18.75 9a.75.75 0 00-.75.75v.008c0 .414.336.75.75.75h.008a.75.75 0 00.75-.75V9.75a.75.75 0 00-.75-.75h-.008zM4.5 9.75A.75.75 0 015.25 9h.008a.75.75 0 01.75.75v.008a.75.75 0 01-.75.75H5.25a.75.75 0 01-.75-.75V9.75z" clip-rule="evenodd" />
                  <path d="M2.25 18a.75.75 0 000 1.5c5.4 0 10.63.722 15.6 2.075 1.19.324 2.4-.558 2.4-1.82V18.75a.75.75 0 00-.75-.75H2.25z" />
                </svg>
              </div>
            </div>
          </div>

          <div class="bento-card bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Pending Ack.</p>
                <p class="text-3xl font-bold" :class="pendingCount > 0 ? 'text-amber-600' : 'text-slate-900'">
                  {{ statsLoading ? '—' : pendingCount }}
                </p>
                <p class="text-xs text-slate-500 mt-1">awaiting acknowledgement</p>
              </div>
              <div class="w-11 h-11 bg-amber-100 rounded-lg flex items-center justify-center shrink-0">
                <svg class="w-6 h-6 text-amber-600" fill="currentColor" viewBox="0 0 24 24">
                  <path fill-rule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 6a.75.75 0 00-1.5 0v6c0 .414.336.75.75.75h4.5a.75.75 0 000-1.5h-3.75V6z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>

          <div class="bento-card bg-white rounded-xl shadow-sm border border-slate-200 p-5">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Locations</p>
                <p class="text-3xl font-bold text-slate-900">{{ statsLoading ? '—' : activeLocations }}</p>
                <p class="text-xs text-slate-500 mt-1">sites with assets</p>
              </div>
              <div class="w-11 h-11 bg-blue-100 rounded-lg flex items-center justify-center shrink-0">
                <svg class="w-6 h-6 text-blue-600" fill="currentColor" viewBox="0 0 24 24">
                  <path fill-rule="evenodd" d="M11.54 22.351l.07.04.028.016a.76.76 0 00.723 0l.028-.015.071-.041a16.975 16.975 0 001.144-.742 19.58 19.58 0 002.683-2.282c1.944-1.99 3.963-4.98 3.963-8.827a8.25 8.25 0 00-16.5 0c0 3.846 2.02 6.837 3.963 8.827a19.58 19.58 0 002.682 2.282 16.975 16.975 0 001.145.742zM12 13.5a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Charts + Recent -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-4 mb-6">
          <div class="lg:col-span-8 bento-card">
            <ExpenseCharts
              :assets="assets"
              :locations="locations"
              :companies="companies"
              :loading="statsLoading"
            />
          </div>

          <!-- Recent Additions -->
          <div class="lg:col-span-4 bento-card">
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5 h-full">
              <div class="mb-4">
                <h3 class="text-base font-semibold text-slate-900 mb-0.5">Recent Additions</h3>
                <p class="text-xs text-slate-500">Latest assets added to the register</p>
              </div>
              <div v-if="statsLoading" class="py-10 text-center text-sm text-slate-400">Loading…</div>
              <ul v-else-if="recentAssets.length" class="divide-y divide-slate-100">
                <li v-for="a in recentAssets" :key="a.id" class="py-2.5 flex items-start justify-between gap-3">
                  <div class="min-w-0">
                    <p class="text-sm font-medium text-slate-800 truncate" :title="a.name">{{ a.name }}</p>
                    <p class="text-xs text-slate-500 mt-0.5">
                      {{ a.locations?.name || 'No location' }} · {{ formatDate(a.created_at) }}
                    </p>
                  </div>
                  <div class="text-right shrink-0">
                    <p class="text-sm font-semibold text-slate-900">
                      {{ typeof a.details?.cost === 'number' ? inr(a.details.cost) : '—' }}
                    </p>
                    <span
                      v-if="!a.acknowledged_at"
                      class="inline-block mt-0.5 px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-100 text-amber-800"
                    >Pending</span>
                  </div>
                </li>
              </ul>
              <div v-else class="py-10 text-center text-sm text-slate-400">No assets yet</div>
            </div>
          </div>
        </div>

        <!-- Assets table -->
        <div class="bento-card">
          <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
            <div class="mb-5">
              <h2 class="text-xl font-semibold text-slate-900 mb-1">All Assets</h2>
              <p class="text-sm text-slate-500">Complete asset inventory — search, filter, click a row for details</p>
            </div>
            <AssetsTable />
          </div>
        </div>
      </main>
    </div>
  </div>
</template>
