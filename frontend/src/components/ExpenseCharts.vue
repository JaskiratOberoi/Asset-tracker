<script setup lang="ts">
import { computed } from 'vue'
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

ChartJS.register(CategoryScale, LinearScale, BarElement, ArcElement, Title, Tooltip, Legend)

interface AssetLike {
  id: string
  details: any
  company_id: string
  location_id: string | null
  locations?: { name: string } | null
}

const props = defineProps<{
  assets: AssetLike[]
  locations: Array<{ id: string; name: string; company_id: string }>
  companies: Array<{ id: string; name: string }>
  loading: boolean
}>()

const PALETTE = [
  'rgba(99, 102, 241, 0.85)',   // indigo
  'rgba(16, 185, 129, 0.85)',   // emerald
  'rgba(59, 130, 246, 0.85)',   // blue
  'rgba(245, 158, 11, 0.85)',   // amber
  'rgba(236, 72, 153, 0.85)',   // pink
  'rgba(139, 92, 246, 0.85)',   // violet
  'rgba(20, 184, 166, 0.85)',   // teal
  'rgba(249, 115, 22, 0.85)',   // orange
  'rgba(100, 116, 139, 0.85)',  // slate
  'rgba(217, 70, 239, 0.85)',   // fuchsia
  'rgba(34, 197, 94, 0.85)',    // green
  'rgba(6, 182, 212, 0.85)'     // cyan
]
const colors = (n: number) => Array.from({ length: n }, (_, i) => PALETTE[i % PALETTE.length])

const assetCost = (a: AssetLike): number =>
  typeof a.details?.cost === 'number' && !Number.isNaN(a.details.cost) ? a.details.cost : 0

const inrFull = (n: number) =>
  '₹' + n.toLocaleString('en-IN', { maximumFractionDigits: 0 })
const inrCompact = (n: number) =>
  '₹' + n.toLocaleString('en-IN', { notation: 'compact', maximumFractionDigits: 1 })

// Aggregate assets per location NAME. The API joins each asset to its location row and
// returns the name, so grouping by name stays correct even if the locations table has
// duplicate rows for the same site (a known seed-migration quirk).
const byLocation = computed(() => {
  const agg = new Map<string, { name: string; count: number; spend: number }>()
  for (const a of props.assets) {
    const name = a.locations?.name ?? 'No location'
    const entry = agg.get(name) ?? { name, count: 0, spend: 0 }
    entry.count += 1
    entry.spend += assetCost(a)
    agg.set(name, entry)
  }
  return [...agg.values()].sort((x, y) => y.spend - x.spend)
})

const byCompany = computed(() => {
  const compName = new Map(props.companies.map((c) => [c.id, c.name]))
  const agg = new Map<string, { name: string; count: number }>()
  for (const a of props.assets) {
    const name = compName.get(a.company_id) ?? 'Unknown'
    const entry = agg.get(a.company_id) ?? { name, count: 0 }
    entry.count += 1
    agg.set(a.company_id, entry)
  }
  return [...agg.values()].sort((x, y) => y.count - x.count)
})

const spendByLocationData = computed(() => ({
  labels: byLocation.value.map((l) => l.name),
  datasets: [
    {
      label: 'Spend',
      backgroundColor: colors(byLocation.value.length),
      borderRadius: 6,
      data: byLocation.value.map((l) => l.spend)
    }
  ]
}))

const countByLocationData = computed(() => ({
  labels: byLocation.value.map((l) => l.name),
  datasets: [
    {
      label: 'Assets',
      backgroundColor: colors(byLocation.value.length),
      borderRadius: 6,
      data: byLocation.value.map((l) => l.count)
    }
  ]
}))

const companyDoughnutData = computed(() => ({
  labels: byCompany.value.map((c) => c.name),
  datasets: [
    {
      backgroundColor: colors(byCompany.value.length),
      borderWidth: 2,
      borderColor: '#ffffff',
      data: byCompany.value.map((c) => c.count)
    }
  ]
}))

const baseTicks = { font: { size: 11, weight: '500' as const }, color: '#64748b' }

const spendChartOptions: any = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      padding: 12,
      cornerRadius: 8,
      callbacks: {
        label: (ctx: { raw: unknown }) => ` ${inrFull(Number(ctx.raw))}`
      }
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(148, 163, 184, 0.1)' },
      ticks: {
        ...baseTicks,
        callback: (value: number | string) => (typeof value === 'number' ? inrCompact(value) : value)
      }
    },
    x: { grid: { display: false }, ticks: baseTicks }
  }
}

const countChartOptions: any = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      padding: 12,
      cornerRadius: 8,
      callbacks: {
        label: (ctx: { raw: unknown }) => ` ${ctx.raw} asset${Number(ctx.raw) === 1 ? '' : 's'}`
      }
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(148, 163, 184, 0.1)' },
      ticks: { ...baseTicks, precision: 0 }
    },
    x: { grid: { display: false }, ticks: baseTicks }
  }
}

const doughnutOptions: any = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '62%',
  plugins: {
    legend: {
      position: 'bottom' as const,
      labels: {
        padding: 12,
        font: { size: 11, weight: '600' as const },
        color: '#475569',
        usePointStyle: true,
        pointStyle: 'circle'
      }
    },
    tooltip: {
      backgroundColor: 'rgba(15, 23, 42, 0.95)',
      padding: 12,
      cornerRadius: 8,
      callbacks: {
        label: (ctx: { label: string; raw: unknown }) =>
          ` ${ctx.label}: ${ctx.raw} asset${Number(ctx.raw) === 1 ? '' : 's'}`
      }
    }
  }
}

const totalSpend = computed(() => props.assets.reduce((s, a) => s + assetCost(a), 0))
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 h-full">
    <!-- Spend by Location (hero, full width) -->
    <div class="md:col-span-2 bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="flex items-baseline justify-between mb-3">
        <div>
          <h3 class="text-base font-semibold text-slate-900 mb-0.5">Spend by Location</h3>
          <p class="text-xs text-slate-500">Total asset value per site</p>
        </div>
        <p v-if="!loading" class="text-sm font-semibold text-slate-700">{{ inrFull(totalSpend) }} total</p>
      </div>
      <div v-if="loading" class="h-56 flex items-center justify-center text-sm text-slate-400">Loading chart data…</div>
      <div v-else-if="!byLocation.length" class="h-56 flex items-center justify-center text-sm text-slate-400">No data available</div>
      <div v-else class="h-56">
        <Bar :data="spendByLocationData" :options="spendChartOptions" />
      </div>
    </div>

    <!-- Assets by Location -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="mb-3">
        <h3 class="text-base font-semibold text-slate-900 mb-0.5">Assets by Location</h3>
        <p class="text-xs text-slate-500">Asset count per site</p>
      </div>
      <div v-if="loading" class="h-48 flex items-center justify-center text-sm text-slate-400">Loading…</div>
      <div v-else-if="!byLocation.length" class="h-48 flex items-center justify-center text-sm text-slate-400">No data available</div>
      <div v-else class="h-48">
        <Bar :data="countByLocationData" :options="countChartOptions" />
      </div>
    </div>

    <!-- Assets by Company -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5">
      <div class="mb-3">
        <h3 class="text-base font-semibold text-slate-900 mb-0.5">Assets by Company</h3>
        <p class="text-xs text-slate-500">Share of register per company</p>
      </div>
      <div v-if="loading" class="h-48 flex items-center justify-center text-sm text-slate-400">Loading…</div>
      <div v-else-if="!byCompany.length" class="h-48 flex items-center justify-center text-sm text-slate-400">No data available</div>
      <div v-else class="h-48">
        <Doughnut :data="companyDoughnutData" :options="doughnutOptions" />
      </div>
    </div>
  </div>
</template>
