<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { gsap } from 'gsap'
import { getMe, logout as apiLogout } from '../lib/api'
import { useRegister, inr, segDigits, formatDate } from '../lib/useRegister'
import SegmentDisplay from '../components/SegmentDisplay.vue'
import StepRow from '../components/StepRow.vue'
import ExpenseCharts from '../components/ExpenseCharts.vue'
import AssetsTable from '../components/AssetsTable.vue'

const router = useRouter()
const { assets, companies, locations, isLoading: dataLoading, loadError, load } = useRegister()

const isAuthLoading = ref(true)
const user = ref<{ id: string; email: string } | null>(null)

onMounted(async () => {
  try {
    const me = await getMe()
    if (!me || !me.user) {
      router.push({ path: '/login', query: { reason: 'session_invalid' } })
      return
    }
    user.value = me.user
  } catch {
    router.push({ path: '/login', query: { reason: 'session_invalid' } })
    return
  }
  isAuthLoading.value = false
  await load()
  // one entrance: modules rise together, then stay put
  gsap.fromTo(
    '.bento-card',
    { opacity: 0, y: 20 },
    { opacity: 1, y: 0, duration: 0.4, ease: 'power3.out', stagger: 0.05, clearProps: 'all' }
  )
})

function handleLogout() {
  apiLogout()
  router.push('/login')
}

// ---------------- stats ----------------
const statsLoading = computed(() => dataLoading.value)

const totalValue = computed(() =>
  assets.value.reduce((sum, a) => {
    const c = a.details?.cost
    return typeof c === 'number' && Number.isFinite(c) ? sum + c : sum
  }, 0)
)
const withBills = computed(() => assets.value.filter(a => a.bill_url).length)
const pendingCount = computed(() => assets.value.filter(a => a.acknowledged_at === null).length)
const activeSites = computed(
  () => new Set(assets.value.map(a => a.location_id).filter(Boolean)).size
)

// ---------------- register timeline ----------------
const MONTH_LABELS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']

const yearsInData = computed(() => {
  const ys = new Set<number>(assets.value.map(a => new Date(a.created_at).getFullYear()))
  ys.add(new Date().getFullYear())
  return [...ys].sort((a, b) => a - b)
})

const timelineYear = ref(new Date().getFullYear())
const selectedMonth = ref<number | null>(null)

const monthsData = computed(() =>
  MONTH_LABELS.map((label, i) => {
    const inMonth = assets.value.filter(a => {
      const d = new Date(a.created_at)
      return d.getFullYear() === timelineYear.value && d.getMonth() === i
    })
    return {
      label,
      count: inMonth.length,
      spend: inMonth.reduce((s, a) => {
        const c = a.details?.cost
        return typeof c === 'number' && Number.isFinite(c) ? s + c : s
      }, 0),
    }
  })
)

const yearSpend = computed(() => monthsData.value.reduce((s, m) => s + m.spend, 0))
const yearCount = computed(() => monthsData.value.reduce((s, m) => s + m.count, 0))

function shiftYear(delta: number) {
  const ys = yearsInData.value
  const idx = ys.indexOf(timelineYear.value)
  const next = ys[idx + delta]
  if (next !== undefined) {
    timelineYear.value = next
    selectedMonth.value = null
  }
}

const monthFilter = computed(() =>
  selectedMonth.value === null ? null : { year: timelineYear.value, month: selectedMonth.value }
)

// ---------------- recent additions ----------------
const recentAssets = computed(() =>
  [...assets.value]
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 6)
)
</script>

<template>
  <!-- auth splash -->
  <div v-if="isAuthLoading" class="min-h-screen flex items-center justify-center">
    <div class="flex items-center gap-3">
      <span class="led led-red led-blink"></span>
      <span class="silk-label-bright">Verifying operator…</span>
    </div>
  </div>

  <div v-else class="min-h-screen flex flex-col">
    <!-- faceplate header -->
    <header class="border-b border-seam bg-panel sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 py-3.5 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3 min-w-0">
          <span class="font-plate text-lg text-paper tracking-wide shrink-0">AR-9</span>
          <span class="hidden md:block h-4 w-px bg-seamlight"></span>
          <div class="hidden md:block min-w-0">
            <p class="silk-label">Asset Register · Console</p>
            <p class="text-[11px] text-silkfaint truncate">Operator: {{ user?.email }}</p>
          </div>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <a href="/onboarding" class="panel-btn-primary py-2">
            <svg class="w-3.5 h-3.5" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Register asset
          </a>
          <button class="panel-btn-secondary py-2" @click="handleLogout">Log out</button>
        </div>
      </div>
    </header>

    <main class="flex-1 w-full max-w-7xl mx-auto px-5 sm:px-8 py-6 sm:py-8">
      <div
        v-if="loadError"
        role="alert"
        class="panel-module flex items-start gap-2.5 px-4 py-3 mb-5"
      >
        <span class="led led-red led-blink mt-1 shrink-0"></span>
        <p class="text-[13px] text-stepred">{{ loadError }}</p>
      </div>

      <!-- ============ readout row ============ -->
      <div class="grid grid-cols-2 lg:grid-cols-12 gap-4">
        <section class="bento-card panel-module col-span-2 lg:col-span-4">
          <div class="module-head">
            <h2 class="silk-label-bright">Register value</h2>
            <span class="silk-label text-silkfaint">₹ INR</span>
          </div>
          <div class="px-4 py-4">
            <div class="seg-window">
              <SegmentDisplay
                :value="statsLoading ? '-----' : segDigits(totalValue)"
                :height="40"
              />
            </div>
            <p class="mt-2.5 text-[11px] text-silkdim">
              {{ statsLoading ? 'reading…' : inr(totalValue) + ' across ' + activeSites + ' site' + (activeSites === 1 ? '' : 's') }}
            </p>
          </div>
        </section>

        <section class="bento-card panel-module lg:col-span-3">
          <div class="module-head">
            <h2 class="silk-label-bright">Assets</h2>
            <span class="led" :class="assets.length > 0 ? 'led-green' : ''"></span>
          </div>
          <div class="px-4 py-4">
            <div class="seg-window">
              <SegmentDisplay
                :value="statsLoading ? '--' : String(assets.length)"
                :height="40"
                :min-cells="2"
              />
            </div>
            <p class="mt-2.5 text-[11px] text-silkdim">
              {{ statsLoading ? 'reading…' : withBills + ' with bills attached' }}
            </p>
          </div>
        </section>

        <section class="bento-card panel-module lg:col-span-2">
          <div class="module-head">
            <h2 class="silk-label-bright">Pending</h2>
            <span class="led" :class="pendingCount > 0 ? 'led-amber led-blink' : 'led-green'"></span>
          </div>
          <div class="px-4 py-4">
            <div class="seg-window">
              <SegmentDisplay
                :value="statsLoading ? '--' : String(pendingCount)"
                :height="40"
                :min-cells="2"
                color="#ffb020"
              />
            </div>
            <p class="mt-2.5 text-[11px] text-silkdim">
              {{ statsLoading ? 'reading…' : pendingCount > 0 ? 'awaiting acknowledgement' : 'register is clear' }}
            </p>
          </div>
        </section>

        <section class="bento-card panel-module lg:col-span-3">
          <div class="module-head">
            <h2 class="silk-label-bright">Sites</h2>
            <span class="silk-label text-silkfaint">Active</span>
          </div>
          <div class="px-4 py-4">
            <div class="seg-window">
              <SegmentDisplay
                :value="statsLoading ? '--' : String(activeSites)"
                :height="40"
                :min-cells="2"
              />
            </div>
            <p class="mt-2.5 text-[11px] text-silkdim">
              {{ statsLoading ? 'reading…' : 'of ' + locations.length + ' recorded sites hold assets' }}
            </p>
          </div>
        </section>
      </div>

      <!-- ============ register timeline ============ -->
      <section class="bento-card panel-module mt-4">
        <div class="module-head">
          <div class="flex items-baseline gap-3">
            <h2 class="silk-label-bright">Register timeline</h2>
            <span class="silk-label text-silkfaint hidden sm:inline">
              {{ yearCount }} record{{ yearCount === 1 ? '' : 's' }} · {{ inr(yearSpend) }} in {{ timelineYear }}
            </span>
          </div>
          <div class="flex items-center gap-1.5">
            <button
              class="panel-btn-ghost px-2 py-1"
              :disabled="yearsInData.indexOf(timelineYear) <= 0"
              aria-label="Previous year"
              @click="shiftYear(-1)"
            >
              <svg class="w-3.5 h-3.5" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
              </svg>
            </button>
            <span class="font-display text-2xl leading-none text-paper tabular-nums w-16 text-center">{{ timelineYear }}</span>
            <button
              class="panel-btn-ghost px-2 py-1"
              :disabled="yearsInData.indexOf(timelineYear) >= yearsInData.length - 1"
              aria-label="Next year"
              @click="shiftYear(1)"
            >
              <svg class="w-3.5 h-3.5" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
              </svg>
            </button>
          </div>
        </div>
        <div class="px-4 sm:px-5 py-4">
          <StepRow
            :months="monthsData"
            :selected="selectedMonth"
            :year="timelineYear"
            @select="selectedMonth = $event"
          />
          <p class="mt-3 text-[11px] text-silkdim">
            {{ selectedMonth === null
              ? 'Press a month key to filter the register below to that month.'
              : 'Register filtered to ' + MONTH_LABELS[selectedMonth] + ' ' + timelineYear + ' — press the key again to release.' }}
          </p>
        </div>
      </section>

      <!-- ============ charts ============ -->
      <ExpenseCharts
        class="mt-4"
        :assets="assets"
        :locations="locations"
        :companies="companies"
        :loading="statsLoading"
      />

      <!-- ============ latest entries strip ============ -->
      <section class="bento-card panel-module mt-4">
        <div class="module-head">
          <h2 class="silk-label-bright">Latest entries</h2>
          <span class="silk-label text-silkfaint">Newest first</span>
        </div>
        <div v-if="statsLoading" class="px-4 py-6 text-[13px] text-silkfaint">Reading register…</div>
        <div v-else-if="recentAssets.length === 0" class="px-4 py-6 text-[13px] text-silkfaint">
          Nothing in the register yet.
        </div>
        <div v-else class="grid sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="(a, i) in recentAssets"
            :key="a.id"
            class="px-4 py-3.5 flex items-start gap-3 border-seam/60 border-t first:border-t-0 sm:[&:nth-child(2)]:border-t-0 lg:[&:nth-child(3)]:border-t-0"
            :class="[i % 2 === 1 ? 'sm:border-l' : '', i % 3 !== 0 ? 'lg:border-l' : 'lg:border-l-0']"
          >
            <span class="led mt-1 shrink-0" :class="a.acknowledged_at === null ? 'led-amber led-blink' : 'led-green'"></span>
            <div class="min-w-0 flex-1">
              <p class="text-[13px] text-paper font-medium truncate" :title="a.name">{{ a.name }}</p>
              <p class="text-[11px] text-silkfaint truncate">
                {{ a.locations?.name ?? 'No site' }} · {{ formatDate(a.created_at) }}
              </p>
            </div>
            <span class="text-[13px] text-silk tabular-nums shrink-0">{{ a.details?.cost != null ? inr(a.details.cost) : '—' }}</span>
          </div>
        </div>
      </section>

      <!-- ============ full register ============ -->
      <section class="bento-card panel-module mt-4">
        <div class="module-head">
          <h2 class="silk-label-bright">The register</h2>
          <span class="silk-label text-silkfaint hidden sm:inline">Search · filter · press a row for the record</span>
        </div>
        <AssetsTable :month-filter="monthFilter" />
      </section>
    </main>

    <footer class="border-t border-seam">
      <div class="max-w-7xl mx-auto px-5 sm:px-8 py-4 flex items-center justify-between">
        <span class="silk-label text-silkfaint">AR-9 · Computer controlled asset register</span>
        <span class="silk-label text-silkfaint">Qugen Pathlabs group</span>
      </div>
    </footer>
  </div>
</template>
