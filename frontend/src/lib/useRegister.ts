import { ref, computed } from 'vue'
import { getAssets, getCompanies, getLocations } from './api'

export interface AssetRecord {
  id: string
  name: string
  details: { description?: string; cost?: number } | null
  serial_number: string | null
  company_id: string
  location_id: string | null
  bill_url: string | null
  created_at: string
  acknowledged_at: string | null
  companies: { name: string } | null
  locations: { name: string } | null
}

export interface Company {
  id: string
  name: string
}

export interface LocationRow {
  id: string
  name: string
  company_id: string
}

// Module-scope state: the dashboard and the table share one fetch.
const assets = ref<AssetRecord[]>([])
const companies = ref<Company[]>([])
const locations = ref<LocationRow[]>([])
const isLoading = ref(false)
const loadError = ref('')
let loadedOnce = false
let inflight: Promise<void> | null = null

async function load(force = false) {
  if (inflight) return inflight
  if (loadedOnce && !force) return
  isLoading.value = true
  loadError.value = ''
  inflight = (async () => {
    try {
      const [a, c, l] = await Promise.all([getAssets(), getCompanies(), getLocations()])
      assets.value = a
      companies.value = c
      locations.value = l
      loadedOnce = true
    } catch (e) {
      loadError.value = e instanceof Error ? e.message : 'Failed to load the register'
    } finally {
      isLoading.value = false
      inflight = null
    }
  })()
  return inflight
}

function patchAsset(id: string, patch: Partial<AssetRecord>) {
  const idx = assets.value.findIndex(a => a.id === id)
  const current = assets.value[idx]
  if (current) assets.value[idx] = { ...current, ...patch }
}

function removeAsset(id: string) {
  assets.value = assets.value.filter(a => a.id !== id)
}

function addLocation(loc: LocationRow) {
  locations.value = [...locations.value, loc]
}

const pendingAssets = computed(() => assets.value.filter(a => a.acknowledged_at === null))

export function useRegister() {
  return {
    assets,
    companies,
    locations,
    isLoading,
    loadError,
    pendingAssets,
    load,
    patchAsset,
    removeAsset,
    addLocation,
  }
}

/** ₹ formatting, en-IN grouping, no decimals (register-wide convention). */
export function inr(value: unknown): string {
  const n = typeof value === 'number' ? value : Number(value)
  if (!Number.isFinite(n)) return '—'
  return '₹' + n.toLocaleString('en-IN', { maximumFractionDigits: 0 })
}

/** Digits + en-IN group separators only, for segment displays (no ₹ glyph). */
export function segDigits(value: number): string {
  if (!Number.isFinite(value)) return '----'
  return Math.round(value).toLocaleString('en-IN')
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('en-IN', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}
