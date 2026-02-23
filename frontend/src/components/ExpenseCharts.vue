<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getAssetCountByCompany, getSpendsByCompany } from '../lib/api'
import { Bar, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import { gsap } from 'gsap'

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
)

interface CompanyData {
  id: string
  name: string
  assetCount: number
}

interface SpendData {
  id: string
  name: string
  totalSpend: number
}

const companies = ref<CompanyData[]>([])
const spendsByCompany = ref<SpendData[]>([])
const isLoading = ref(true)
const isLoadingSpends = ref(true)
const chartContainer = ref<HTMLElement | null>(null)

const barChartData = computed(() => {
  return {
    labels: companies.value.map(c => c.name),
    datasets: [
      {
        label: 'Number of Assets',
        backgroundColor: [
          'rgba(99, 102, 241, 0.8)',
          'rgba(139, 92, 246, 0.8)',
          'rgba(236, 72, 153, 0.8)'
        ],
        borderColor: [
          'rgba(99, 102, 241, 1)',
          'rgba(139, 92, 246, 1)',
          'rgba(236, 72, 153, 1)'
        ],
        borderWidth: 2,
        data: companies.value.map(c => c.assetCount)
      }
    ]
  }
})

const doughnutChartData = computed(() => {
  return {
    labels: companies.value.map(c => c.name),
    datasets: [
      {
        backgroundColor: [
          'rgba(99, 102, 241, 0.8)',
          'rgba(139, 92, 246, 0.8)',
          'rgba(236, 72, 153, 0.8)'
        ],
        borderColor: [
          'rgba(99, 102, 241, 1)',
          'rgba(139, 92, 246, 1)',
          'rgba(236, 72, 153, 1)'
        ],
        borderWidth: 2,
        data: companies.value.map(c => c.assetCount)
      }
    ]
  }
})

const spendsChartData = computed(() => {
  return {
    labels: spendsByCompany.value.map(s => s.name),
    datasets: [
      {
        label: 'Total Spend',
        backgroundColor: [
          'rgba(34, 197, 94, 0.8)',
          'rgba(59, 130, 246, 0.8)',
          'rgba(168, 85, 247, 0.8)',
          'rgba(236, 72, 153, 0.8)',
          'rgba(245, 158, 11, 0.8)'
        ],
        borderColor: [
          'rgba(34, 197, 94, 1)',
          'rgba(59, 130, 246, 1)',
          'rgba(168, 85, 247, 1)',
          'rgba(236, 72, 153, 1)',
          'rgba(245, 158, 11, 1)'
        ],
        borderWidth: 2,
        data: spendsByCompany.value.map(s => s.totalSpend)
      }
    ]
  }
})

const spendsChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom' as const,
      labels: {
        padding: 15,
        font: { size: 12, weight: '600' as const, family: 'system-ui, -apple-system, sans-serif' },
        color: '#475569',
        usePointStyle: true,
        pointStyle: 'circle'
      }
    },
    tooltip: {
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      padding: 12,
      callbacks: {
        label: (ctx: { raw: number }) => `$${Number(ctx.raw).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
      }
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(148, 163, 184, 0.1)' },
      ticks: {
        font: { size: 11, weight: '500' as const },
        color: '#64748b',
        callback: (value: number | string) => typeof value === 'number' ? `$${value.toLocaleString()}` : value
      }
    },
    x: {
      grid: { display: false },
      ticks: { font: { size: 11, weight: '500' as const }, color: '#64748b' }
    }
  }
}

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom' as const,
      labels: {
        padding: 15,
        font: {
          size: 12,
          weight: '600' as const,
          family: 'system-ui, -apple-system, sans-serif'
        },
        color: '#475569',
        usePointStyle: true,
        pointStyle: 'circle'
      }
    },
    tooltip: {
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      padding: 12,
      titleFont: {
        size: 13,
        weight: '600' as const
      },
      bodyFont: {
        size: 12,
        weight: '500' as const
      },
      borderColor: 'rgba(148, 163, 184, 0.2)',
      borderWidth: 1,
      cornerRadius: 8,
      displayColors: true
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: {
        color: 'rgba(148, 163, 184, 0.1)'
      },
      ticks: {
        font: {
          size: 11,
          weight: '500' as const
        },
        color: '#64748b'
      }
    },
    x: {
      grid: {
        display: false
      },
      ticks: {
        font: {
          size: 11,
          weight: '500' as const
        },
        color: '#64748b'
      }
    }
  }
}

const loadCompanyData = async () => {
  try {
    isLoading.value = true
    const data = await getAssetCountByCompany()
    companies.value = data || []
  } catch (error) {
    console.error('Error loading company data:', error)
  } finally {
    isLoading.value = false
  }
}

const loadSpendsData = async () => {
  try {
    isLoadingSpends.value = true
    const data = await getSpendsByCompany()
    spendsByCompany.value = data || []
  } catch (error) {
    console.error('Error loading spends data:', error)
  } finally {
    isLoadingSpends.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadCompanyData(), loadSpendsData()])
  
  if (chartContainer.value) {
    gsap.from(chartContainer.value.children, {
      opacity: 0,
      scale: 0.9,
      duration: 0.6,
      stagger: 0.2,
      ease: 'back.out(1.7)'
    })
  }
})
</script>

<template>
  <div ref="chartContainer" class="grid grid-cols-1 lg:grid-cols-2 gap-5">
    <!-- Bar Chart -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="mb-3">
        <h3 class="text-base font-semibold text-slate-900 mb-0.5">Assets Distribution</h3>
        <p class="text-xs text-slate-500">Visual breakdown by company</p>
      </div>
      <div v-if="isLoading" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="animate-spin h-8 w-8 text-slate-400 mx-auto mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-sm text-slate-500">Loading chart data...</p>
        </div>
      </div>
      <div v-else-if="companies.length === 0" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="w-12 h-12 text-slate-400 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
          <p class="text-sm text-slate-500">No data available</p>
        </div>
      </div>
      <div v-else class="h-52">
        <Bar :data="barChartData" :options="(chartOptions as any)" />
      </div>
    </div>

    <!-- Doughnut Chart -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="mb-3">
        <h3 class="text-base font-semibold text-slate-900 mb-0.5">Assets by Company</h3>
        <p class="text-xs text-slate-500">Percentage breakdown</p>
      </div>
      <div v-if="isLoading" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="animate-spin h-8 w-8 text-slate-400 mx-auto mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-sm text-slate-500">Loading chart data...</p>
        </div>
      </div>
      <div v-else-if="companies.length === 0" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="w-12 h-12 text-slate-400 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
          </svg>
          <p class="text-sm text-slate-500">No data available</p>
        </div>
      </div>
      <div v-else class="h-52">
        <Doughnut :data="doughnutChartData" :options="(chartOptions as any)" />
      </div>
    </div>

    <!-- Spends by Company (full width) -->
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="mb-3">
        <h3 class="text-base font-semibold text-slate-900 mb-0.5">Spends by Company</h3>
        <p class="text-xs text-slate-500">Total cost of assets per company</p>
      </div>
      <div v-if="isLoadingSpends" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="animate-spin h-8 w-8 text-slate-400 mx-auto mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-sm text-slate-500">Loading spends...</p>
        </div>
      </div>
      <div v-else-if="!spendsByCompany.length || spendsByCompany.every(s => s.totalSpend === 0)" class="h-52 flex items-center justify-center">
        <div class="text-center">
          <svg class="w-12 h-12 text-slate-400 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p class="text-sm text-slate-500">No spend data yet</p>
          <p class="text-xs text-slate-400 mt-1">Add price/cost when onboarding assets to see spends here</p>
        </div>
      </div>
      <div v-else class="h-52">
        <Bar :data="spendsChartData" :options="(spendsChartOptions as any)" />
      </div>
    </div>
  </div>
</template>
