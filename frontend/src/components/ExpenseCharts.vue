<script setup lang="ts">
import { computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { Bar } from 'vue-chartjs'
import type { AssetRecord, Company, LocationRow } from '../lib/useRegister'
import { inr } from '../lib/useRegister'

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)
ChartJS.defaults.font.family = '"Spline Sans Mono", ui-monospace, monospace'
ChartJS.defaults.font.size = 10

const props = defineProps<{
  assets: AssetRecord[]
  locations: LocationRow[]
  companies: Company[]
  loading: boolean
}>()

// step-key quartet, cycled
const KEYS = ['#ff3b30', '#ff9a00', '#ffe100', '#f2f2f2']

// ---- spend + count per site (grouped by location NAME on purpose: historical
// duplicate location rows share a name; see AssetsTable) ----
const bySite = computed(() => {
  const map = new Map<string, { spend: number; count: number }>()
  for (const a of props.assets) {
    const key = a.locations?.name ?? 'No site'
    const entry = map.get(key) ?? { spend: 0, count: 0 }
    const c = a.details?.cost
    if (typeof c === 'number' && Number.isFinite(c)) entry.spend += c
    entry.count += 1
    map.set(key, entry)
  }
  return [...map.entries()]
    .map(([name, v]) => ({ name, ...v }))
    .sort((a, b) => b.spend - a.spend)
})

const totalSpend = computed(() => bySite.value.reduce((s, r) => s + r.spend, 0))

const spendChartData = computed(() => ({
  labels: bySite.value.map(r => r.name),
  datasets: [
    {
      data: bySite.value.map(r => r.spend),
      backgroundColor: bySite.value.map((_, i) => KEYS[i % KEYS.length] + 'd9'),
      hoverBackgroundColor: bySite.value.map((_, i) => KEYS[i % KEYS.length]),
      borderRadius: 2,
      maxBarThickness: 42,
    },
  ],
}))

const spendChartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(10, 10, 12, 0.95)',
      borderColor: '#33333b',
      borderWidth: 1,
      titleColor: '#f2f2f2',
      bodyColor: '#bdbdbd',
      cornerRadius: 4,
      padding: 10,
      callbacks: {
        label: (ctx: { dataIndex: number }) => {
          const row = bySite.value[ctx.dataIndex]
          if (!row) return ''
          return `${inr(row.spend)} · ${row.count} asset${row.count === 1 ? '' : 's'}`
        },
      },
    },
  },
  scales: {
    x: {
      grid: { display: false },
      ticks: { color: '#8a8a92' },
      border: { color: '#26262c' },
    },
    y: {
      grid: { color: 'rgba(255, 255, 255, 0.05)' },
      border: { display: false },
      ticks: {
        color: '#8a8a92',
        callback: (v: string | number) =>
          '₹' + Number(v).toLocaleString('en-IN', { notation: 'compact' }),
      },
    },
  },
}))

// ---- register share per company (count + spend meters) ----
const byCompany = computed(() => {
  const map = new Map<string, { count: number; spend: number }>()
  for (const a of props.assets) {
    const key = a.company_id
    const entry = map.get(key) ?? { count: 0, spend: 0 }
    entry.count += 1
    const c = a.details?.cost
    if (typeof c === 'number' && Number.isFinite(c)) entry.spend += c
    map.set(key, entry)
  }
  const total = props.assets.length || 1
  return [...map.entries()]
    .map(([id, v]) => ({
      id,
      name: props.companies.find(c => c.id === id)?.name ?? 'Unknown',
      ...v,
      share: v.count / total,
    }))
    .sort((a, b) => b.count - a.count)
})

const METER_SEGMENTS = 24

// instrument row: one station per site, LED lit when the site holds assets
const siteRow = computed(() =>
  bySite.value.map(r => ({
    code: r.name === 'No site' ? 'N/S' : r.name.slice(0, 3).toUpperCase(),
    name: r.name,
    count: r.count,
  }))
)
</script>

<template>
  <div class="grid lg:grid-cols-12 gap-4">
    <!-- spend by site -->
    <section class="bento-card panel-module lg:col-span-7">
      <div class="module-head">
        <h2 class="silk-label-bright">Spend by site</h2>
        <span class="silk-label text-silkfaint">{{ loading ? '—' : inr(totalSpend) + ' total' }}</span>
      </div>
      <div class="px-4 py-4 h-64">
        <div v-if="loading" class="h-full flex items-center justify-center text-[13px] text-silkfaint">
          Reading register…
        </div>
        <div v-else-if="bySite.length === 0" class="h-full flex items-center justify-center text-[13px] text-silkfaint">
          No data on the register yet.
        </div>
        <Bar v-else :data="spendChartData" :options="spendChartOptions" />
      </div>
    </section>

    <!-- register share by company -->
    <section class="bento-card panel-module lg:col-span-5">
      <div class="module-head">
        <h2 class="silk-label-bright">Register share by company</h2>
        <span class="silk-label text-silkfaint">By count</span>
      </div>
      <div class="px-4 py-4 min-h-[10rem]">
        <div v-if="loading" class="h-full flex items-center justify-center text-[13px] text-silkfaint">
          Reading register…
        </div>
        <div v-else-if="byCompany.length === 0" class="h-full flex items-center justify-center text-[13px] text-silkfaint">
          No data on the register yet.
        </div>
        <ul v-else class="space-y-4">
          <li v-for="(c, i) in byCompany" :key="c.id">
            <div class="flex items-baseline justify-between gap-3 mb-1.5">
              <span class="text-[13px] text-paper font-medium truncate" :title="c.name">{{ c.name }}</span>
              <span class="text-[11px] text-silkdim tabular-nums shrink-0">
                {{ c.count }} · {{ Math.round(c.share * 100) }}% · {{ inr(c.spend) }}
              </span>
            </div>
            <!-- output meter: lit segments proportional to register share -->
            <div
              class="flex gap-[3px]"
              role="img"
              :aria-label="`${c.name}: ${Math.round(c.share * 100)}% of the register`"
            >
              <span
                v-for="s in METER_SEGMENTS"
                :key="s"
                class="h-3 flex-1 rounded-[1px]"
                :style="s <= Math.max(1, Math.round(c.share * METER_SEGMENTS))
                  ? { backgroundColor: KEYS[i % KEYS.length], boxShadow: `0 0 4px ${KEYS[i % KEYS.length]}66` }
                  : { backgroundColor: '#26262c' }"
              ></span>
            </div>
          </li>
        </ul>
      </div>
      <div v-if="!loading && siteRow.length > 0" class="border-t border-seam px-4 py-3.5">
        <div class="flex items-start gap-4 overflow-x-auto pb-1">
          <div
            v-for="s in siteRow"
            :key="s.name"
            class="flex flex-col items-center gap-1.5 shrink-0"
            :title="`${s.name}: ${s.count} asset${s.count === 1 ? '' : 's'}`"
          >
            <span class="silk-label">{{ s.code }}</span>
            <span class="led" :class="s.count > 0 ? 'led-green' : ''"></span>
            <span class="font-mono text-[11px] text-silk tabular-nums">{{ s.count }}</span>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
