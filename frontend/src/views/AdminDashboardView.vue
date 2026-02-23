<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { logout, getMe } from '../lib/api'
import { gsap } from 'gsap'
import AssetsTable from '../components/AssetsTable.vue'
import ExpenseCharts from '../components/ExpenseCharts.vue'

const router = useRouter()
const isLoading = ref(true)
const user = ref<{ id: string; email: string } | null>(null)
const dashboardContainer = ref<HTMLElement | null>(null)

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

onMounted(async () => {
  await checkAuth()

  if (dashboardContainer.value) {
    const cards = dashboardContainer.value.querySelectorAll('.bento-card')
    gsap.from(cards, {
      opacity: 0,
      y: 30,
      scale: 0.95,
      duration: 0.6,
      stagger: 0.1,
      ease: 'power3.out'
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
        <div class="max-w-7xl mx-auto px-8 py-6">
          <div class="flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-semibold text-slate-900">Asset Tracker</h1>
              <p class="text-sm text-slate-500 mt-1">Welcome back, {{ user?.email }}</p>
            </div>
            <button
              @click="handleLogout"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-all duration-200"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      <!-- Main Content - Bento Box Layout -->
      <main class="max-w-7xl mx-auto px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <div class="lg:col-span-8 bento-card">
            <ExpenseCharts />
          </div>
          <div class="lg:col-span-4 bento-card">
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-8 h-full">
              <h3 class="text-lg font-semibold text-slate-900 mb-6">Quick Stats</h3>
              <div class="space-y-4">
                <div class="flex items-center justify-between p-6 bg-slate-50 rounded-lg border border-slate-200">
                  <div>
                    <p class="text-sm text-slate-500 mb-1">Total Assets</p>
                    <p class="text-2xl font-semibold text-slate-900">-</p>
                  </div>
                  <div class="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center">
                    <svg class="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                    </svg>
                  </div>
                </div>
                <div class="flex items-center justify-between p-6 bg-slate-50 rounded-lg border border-slate-200">
                  <div>
                    <p class="text-sm text-slate-500 mb-1">Companies</p>
                    <p class="text-2xl font-semibold text-slate-900">3</p>
                  </div>
                  <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="lg:col-span-12 bento-card">
            <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
              <div class="mb-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-1">All Assets</h2>
                <p class="text-sm text-slate-500">Complete asset inventory</p>
              </div>
              <AssetsTable />
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>
