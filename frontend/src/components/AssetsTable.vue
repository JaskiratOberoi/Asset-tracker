<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { gsap } from 'gsap'
import {
  acknowledgeAsset,
  updateAsset,
  deleteAsset,
  getFileViewUrl,
  uploadAssetBill,
  deleteAssetBill,
} from '../lib/api'
import type { AssetRecord } from '../lib/useRegister'
import { useRegister, inr, formatDate } from '../lib/useRegister'

const props = defineProps<{
  monthFilter: { year: number; month: number } | null
}>()

const { assets, companies, locations, isLoading, load, patchAsset, removeAsset } = useRegister()

const root = ref<HTMLElement | null>(null)

onMounted(async () => {
  await load()
  if (root.value) {
    gsap.fromTo(root.value, { opacity: 0, y: 12 }, { opacity: 1, y: 0, duration: 0.35, ease: 'power2.out' })
  }
})

// ---------------- filters ----------------
const search = ref('')
const siteFilter = ref<string>('all') // location NAME, not id: duplicate location
// rows historically share a name, so name is the stable key (do not switch to id)
const statusFilter = ref<'all' | 'pending' | 'acknowledged'>('all')

const siteNames = computed(() =>
  [...new Set(locations.value.map(l => l.name))].sort((a, b) => a.localeCompare(b))
)

const hasActiveFilters = computed(
  () => search.value !== '' || siteFilter.value !== 'all' || statusFilter.value !== 'all'
)

function clearFilters() {
  search.value = ''
  siteFilter.value = 'all'
  statusFilter.value = 'all'
}

const filteredAssets = computed(() => {
  let list = assets.value
  if (props.monthFilter) {
    const { year, month } = props.monthFilter
    list = list.filter(a => {
      const d = new Date(a.created_at)
      return d.getFullYear() === year && d.getMonth() === month
    })
  }
  if (statusFilter.value !== 'all') {
    list = list.filter(a =>
      statusFilter.value === 'pending' ? a.acknowledged_at === null : a.acknowledged_at !== null
    )
  }
  if (siteFilter.value !== 'all') {
    list = list.filter(a => a.locations?.name === siteFilter.value)
  }
  const q = search.value.trim().toLowerCase()
  if (q) {
    list = list.filter(a =>
      a.name.toLowerCase().includes(q)
      || (a.serial_number ?? '').toLowerCase().includes(q)
      || (a.details?.description ?? '').toLowerCase().includes(q)
      || (a.locations?.name ?? '').toLowerCase().includes(q)
    )
  }
  return list
})

const filteredValue = computed(() =>
  filteredAssets.value.reduce((s, a) => {
    const c = a.details?.cost
    return typeof c === 'number' && Number.isFinite(c) ? s + c : s
  }, 0)
)

const pendingAssets = computed(() => assets.value.filter(a => a.acknowledged_at === null))

// ---------------- acknowledge ----------------
const ackInFlight = ref<Set<string>>(new Set())
const bulkAckRunning = ref(false)
const tableError = ref('')

async function acknowledge(asset: AssetRecord) {
  if (ackInFlight.value.has(asset.id)) return
  ackInFlight.value.add(asset.id)
  tableError.value = ''
  try {
    const updated = await acknowledgeAsset(asset.id)
    patchAsset(asset.id, { acknowledged_at: updated.acknowledged_at ?? new Date().toISOString() })
    if (selectedAsset.value?.id === asset.id) {
      selectedAsset.value = { ...selectedAsset.value, acknowledged_at: updated.acknowledged_at ?? new Date().toISOString() }
    }
  } catch (e) {
    tableError.value = e instanceof Error ? e.message : 'Failed to acknowledge'
  } finally {
    ackInFlight.value.delete(asset.id)
  }
}

async function acknowledgeAll() {
  if (bulkAckRunning.value) return
  bulkAckRunning.value = true
  tableError.value = ''
  try {
    for (const a of pendingAssets.value) {
      const updated = await acknowledgeAsset(a.id)
      patchAsset(a.id, { acknowledged_at: updated.acknowledged_at ?? new Date().toISOString() })
    }
  } catch (e) {
    tableError.value = e instanceof Error ? e.message : 'Bulk acknowledge stopped partway'
  } finally {
    bulkAckRunning.value = false
  }
}

// ---------------- view bill ----------------
const billLoading = ref<Set<string>>(new Set())

async function viewBill(asset: AssetRecord) {
  if (!asset.bill_url || billLoading.value.has(asset.id)) return
  billLoading.value.add(asset.id)
  tableError.value = ''
  try {
    const url = await getFileViewUrl(asset.bill_url)
    window.open(url, '_blank')
    setTimeout(() => URL.revokeObjectURL(url), 60_000)
  } catch (e) {
    tableError.value = e instanceof Error ? e.message : 'Failed to open the bill'
  } finally {
    billLoading.value.delete(asset.id)
  }
}

// ---------------- detail / edit modal ----------------
const selectedAsset = ref<AssetRecord | null>(null)
const isEditing = ref(false)
const isSaving = ref(false)
const modalError = ref('')

const editName = ref('')
const editDescription = ref('')
const editCost = ref('')
const editSerial = ref('')
const editCompanyId = ref('')
const editLocationId = ref('')
const editAcknowledged = ref(false)

function openAsset(asset: AssetRecord) {
  selectedAsset.value = asset
  isEditing.value = false
  modalError.value = ''
  billArmedRemove.value = false
}

function closeModal() {
  selectedAsset.value = null
  isEditing.value = false
  modalError.value = ''
}

function startEdit() {
  const a = selectedAsset.value
  if (!a) return
  editName.value = a.name
  editDescription.value = a.details?.description ?? ''
  editCost.value = a.details?.cost != null ? String(a.details.cost) : ''
  editSerial.value = a.serial_number ?? ''
  editCompanyId.value = a.company_id
  editLocationId.value = a.location_id ?? ''
  editAcknowledged.value = a.acknowledged_at !== null
  isEditing.value = true
  modalError.value = ''
}

const locationsForSelectedCompany = computed(() =>
  locations.value.filter(l => l.company_id === editCompanyId.value)
)

function onEditCompanyChange() {
  const valid = locationsForSelectedCompany.value.some(l => l.id === editLocationId.value)
  if (!valid) editLocationId.value = locationsForSelectedCompany.value[0]?.id ?? ''
}

async function saveAssetEdits() {
  const a = selectedAsset.value
  if (!a) return
  modalError.value = ''
  const trimmedName = editName.value.trim()
  if (!trimmedName) {
    modalError.value = 'Asset name is required'
    return
  }
  let costValue: number | null = null
  if (editCost.value !== '') {
    const n = Number(editCost.value)
    if (!Number.isFinite(n) || n < 0) {
      modalError.value = 'Cost must be a non-negative number'
      return
    }
    costValue = n
  }
  isSaving.value = true
  try {
    await updateAsset(a.id, {
      name: trimmedName,
      description: editDescription.value,
      cost: costValue,
      serial_number: editSerial.value.trim() === '' ? null : editSerial.value.trim(),
      company_id: editCompanyId.value,
      location_id: editLocationId.value === '' ? null : editLocationId.value,
      acknowledged: editAcknowledged.value,
    })
    const companyName = companies.value.find(c => c.id === editCompanyId.value)?.name
    const locationName = locations.value.find(l => l.id === editLocationId.value)?.name
    const patch: Partial<AssetRecord> = {
      name: trimmedName,
      details: { description: editDescription.value || undefined, cost: costValue ?? undefined },
      serial_number: editSerial.value.trim() === '' ? null : editSerial.value.trim(),
      company_id: editCompanyId.value,
      location_id: editLocationId.value === '' ? null : editLocationId.value,
      acknowledged_at: editAcknowledged.value ? (a.acknowledged_at ?? new Date().toISOString()) : null,
      companies: companyName ? { name: companyName } : null,
      locations: locationName ? { name: locationName } : null,
    }
    patchAsset(a.id, patch)
    selectedAsset.value = { ...a, ...patch }
    isEditing.value = false
  } catch (e) {
    modalError.value = e instanceof Error ? e.message : 'Failed to save changes'
  } finally {
    isSaving.value = false
  }
}

// ---------------- bill management in the modal ----------------
const billFileInput = ref<HTMLInputElement | null>(null)
const billBusy = ref(false)
const billArmedRemove = ref(false)

function pickBillFile() {
  billFileInput.value?.click()
}

async function onBillFileChange(e: Event) {
  const a = selectedAsset.value
  const files = (e.target as HTMLInputElement).files
  if (!a || !files || !files[0]) return
  billBusy.value = true
  modalError.value = ''
  try {
    const updated = await uploadAssetBill(a.id, files[0])
    patchAsset(a.id, { bill_url: updated.bill_url })
    selectedAsset.value = { ...a, bill_url: updated.bill_url }
  } catch (err) {
    modalError.value = err instanceof Error ? err.message : 'Failed to upload the bill'
  } finally {
    billBusy.value = false
    if (billFileInput.value) billFileInput.value.value = ''
  }
}

async function removeBill() {
  const a = selectedAsset.value
  if (!a) return
  if (!billArmedRemove.value) {
    billArmedRemove.value = true
    return
  }
  billBusy.value = true
  modalError.value = ''
  try {
    await deleteAssetBill(a.id)
    patchAsset(a.id, { bill_url: null })
    selectedAsset.value = { ...a, bill_url: null }
  } catch (err) {
    modalError.value = err instanceof Error ? err.message : 'Failed to remove the bill'
  } finally {
    billBusy.value = false
    billArmedRemove.value = false
  }
}

watch(selectedAsset, () => { billArmedRemove.value = false })

// ---------------- delete ----------------
const deleteTarget = ref<AssetRecord | null>(null)
const isDeleting = ref(false)
const deleteError = ref('')

function confirmDelete(asset: AssetRecord) {
  deleteTarget.value = asset
  deleteError.value = ''
}

async function doDelete() {
  const a = deleteTarget.value
  if (!a) return
  isDeleting.value = true
  deleteError.value = ''
  try {
    await deleteAsset(a.id)
    removeAsset(a.id)
    if (selectedAsset.value?.id === a.id) closeModal()
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e instanceof Error ? e.message : 'Failed to delete'
  } finally {
    isDeleting.value = false
  }
}
</script>

<template>
  <div ref="root">
    <!-- ============ toolbar ============ -->
    <div class="px-4 sm:px-5 pt-4 space-y-3">
      <div
        v-if="tableError"
        role="alert"
        class="panel-well flex items-start gap-2.5 px-3.5 py-2.5"
      >
        <span class="led led-red led-blink mt-1 shrink-0"></span>
        <p class="text-[13px] text-stepred">{{ tableError }}</p>
      </div>

      <div class="flex flex-col lg:flex-row lg:items-center gap-3">
        <!-- search -->
        <div class="relative flex-1 min-w-0">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-silkfaint" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            v-model="search"
            type="text"
            class="panel-input pl-9"
            placeholder="Search name, serial, description, site…"
            aria-label="Search the register"
          />
        </div>

        <!-- status keys -->
        <div class="flex gap-1.5" role="group" aria-label="Filter by status">
          <button
            v-for="s in (['all', 'pending', 'acknowledged'] as const)"
            :key="s"
            type="button"
            class="panel-btn py-2 border"
            :class="statusFilter === s
              ? 'bg-stepred text-black border-stepred'
              : 'bg-transparent text-silkdim border-seam hover:text-paper hover:border-seamlight'"
            :aria-pressed="statusFilter === s"
            @click="statusFilter = s"
          >{{ s === 'all' ? 'All' : s === 'pending' ? 'Pending' : 'Ack’d' }}</button>
        </div>

        <div class="flex items-center gap-2">
          <button v-if="hasActiveFilters" class="panel-btn-ghost py-2" @click="clearFilters">Clear</button>
          <button
            v-if="pendingAssets.length > 0"
            class="panel-btn-secondary py-2 whitespace-nowrap"
            :disabled="bulkAckRunning"
            @click="acknowledgeAll"
          >
            <span class="led shrink-0" :class="bulkAckRunning ? 'led-amber led-blink' : 'led-amber'"></span>
            {{ bulkAckRunning ? 'Acknowledging…' : `Acknowledge all (${pendingAssets.length})` }}
          </button>
        </div>
      </div>

      <!-- site keys: one label per site, LED lit when armed -->
      <div class="flex items-center gap-1.5 overflow-x-auto pb-1" role="group" aria-label="Filter by site">
        <button
          type="button"
          class="shrink-0 flex items-center gap-2 px-3 py-1.5 rounded-[4px] border font-mono text-[11px] uppercase tracking-silk transition-colors"
          :class="siteFilter === 'all'
            ? 'border-stepred text-paper bg-well'
            : 'border-seam text-silkdim hover:text-paper hover:border-seamlight'"
          :aria-pressed="siteFilter === 'all'"
          @click="siteFilter = 'all'"
        >
          <span class="led" :class="siteFilter === 'all' ? 'led-red' : ''"></span>
          All sites
        </button>
        <button
          v-for="name in siteNames"
          :key="name"
          type="button"
          class="shrink-0 flex items-center gap-2 px-3 py-1.5 rounded-[4px] border font-mono text-[11px] uppercase tracking-silk transition-colors"
          :class="siteFilter === name
            ? 'border-stepred text-paper bg-well'
            : 'border-seam text-silkdim hover:text-paper hover:border-seamlight'"
          :aria-pressed="siteFilter === name"
          @click="siteFilter = siteFilter === name ? 'all' : name"
        >
          <span class="led" :class="siteFilter === name ? 'led-red' : ''"></span>
          {{ name }}
        </button>
      </div>
    </div>

    <!-- ============ loading ============ -->
    <div v-if="isLoading" class="px-5 py-10 text-center text-[13px] text-silkfaint">
      Reading register…
    </div>

    <!-- ============ true empty ============ -->
    <div v-else-if="assets.length === 0" class="px-5 py-12 text-center">
      <div class="inline-grid grid-cols-4 gap-1.5 mb-5" aria-hidden="true">
        <span v-for="i in 4" :key="i" class="step-key key-unlit w-8 h-10" :class="['key-red', 'key-orange', 'key-yellow', 'key-white'][i - 1]">
          <span class="key-window"></span>
        </span>
      </div>
      <p class="text-[15px] text-paper font-medium mb-1.5">The register is empty</p>
      <p class="text-[13px] text-silkfaint mb-6">Write the first asset in and its key lights up here.</p>
      <a href="/onboarding" class="panel-btn-primary">
        <svg class="w-3.5 h-3.5" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Register an asset
      </a>
    </div>

    <!-- ============ filtered to zero ============ -->
    <div v-else-if="filteredAssets.length === 0" class="px-5 py-10 text-center">
      <p class="text-[14px] text-paper mb-1.5">No records match</p>
      <p class="text-[13px] text-silkfaint mb-4">
        {{ monthFilter ? 'Nothing was registered under these filters in the selected month.' : 'Nothing on the register matches the current filters.' }}
      </p>
      <button v-if="hasActiveFilters" class="panel-btn-secondary" @click="clearFilters">Clear filters</button>
    </div>

    <template v-else>
      <!-- ============ desktop table ============ -->
      <div class="hidden md:block overflow-x-auto mt-2">
        <table class="w-full text-left">
          <thead>
            <tr class="border-y border-seam">
              <th class="silk-label px-5 py-2.5 font-medium">Asset</th>
              <th class="silk-label px-3 py-2.5 font-medium">Company</th>
              <th class="silk-label px-3 py-2.5 font-medium">Site</th>
              <th class="silk-label px-3 py-2.5 font-medium text-right">Cost</th>
              <th class="silk-label px-3 py-2.5 font-medium">Status</th>
              <th class="silk-label px-3 py-2.5 font-medium">Created</th>
              <th class="silk-label px-3 py-2.5 font-medium">Bill</th>
              <th class="silk-label px-5 py-2.5 font-medium text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="a in filteredAssets"
              :key="a.id"
              class="border-b border-seam/60 cursor-pointer transition-colors hover:bg-module"
              @click="openAsset(a)"
            >
              <td class="px-5 py-3 max-w-[16rem]">
                <p class="text-[13px] text-paper font-medium truncate" :title="a.name">{{ a.name }}</p>
                <p v-if="a.serial_number" class="text-[11px] text-silkfaint truncate">{{ a.serial_number }}</p>
              </td>
              <td class="px-3 py-3 text-[13px] text-silk whitespace-nowrap">{{ a.companies?.name ?? '—' }}</td>
              <td class="px-3 py-3 text-[13px] text-silk whitespace-nowrap">{{ a.locations?.name ?? '—' }}</td>
              <td class="px-3 py-3 text-[13px] text-paper text-right tabular-nums whitespace-nowrap">
                {{ a.details?.cost != null ? inr(a.details.cost) : '—' }}
              </td>
              <td class="px-3 py-3 whitespace-nowrap">
                <span class="inline-flex items-center gap-2">
                  <span class="led" :class="a.acknowledged_at === null ? 'led-amber led-blink' : 'led-green'"></span>
                  <span class="font-mono text-[11px] uppercase tracking-silk" :class="a.acknowledged_at === null ? 'text-ledamber' : 'text-ledgreen'">
                    {{ a.acknowledged_at === null ? 'Pending' : 'Ack’d' }}
                  </span>
                </span>
              </td>
              <td class="px-3 py-3 text-[12px] text-silkdim whitespace-nowrap">{{ formatDate(a.created_at) }}</td>
              <td class="px-3 py-3 whitespace-nowrap">
                <button
                  v-if="a.bill_url"
                  class="font-mono text-[11px] uppercase tracking-silk text-silk hover:text-paper underline underline-offset-4 decoration-seamlight transition-colors"
                  :disabled="billLoading.has(a.id)"
                  @click.stop="viewBill(a)"
                >{{ billLoading.has(a.id) ? 'Opening…' : 'View bill' }}</button>
                <span v-else class="text-[12px] text-silkfaint">—</span>
              </td>
              <td class="px-5 py-3 text-right whitespace-nowrap">
                <button
                  v-if="a.acknowledged_at === null"
                  class="panel-btn-secondary px-2.5 py-1.5 mr-1.5"
                  :disabled="ackInFlight.has(a.id) || bulkAckRunning"
                  @click.stop="acknowledge(a)"
                >{{ ackInFlight.has(a.id) ? '…' : 'Acknowledge' }}</button>
                <button
                  class="panel-btn-ghost px-2.5 py-1.5 hover:!text-stepred"
                  @click.stop="confirmDelete(a)"
                >Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ============ mobile cards ============ -->
      <ul class="md:hidden mt-2 divide-y divide-seam/60 border-t border-seam">
        <li
          v-for="a in filteredAssets"
          :key="a.id"
          class="px-4 py-3.5 active:bg-module"
          @click="openAsset(a)"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-[13px] text-paper font-medium truncate">{{ a.name }}</p>
              <p v-if="a.serial_number" class="text-[11px] text-silkfaint break-all">{{ a.serial_number }}</p>
            </div>
            <span class="text-[13px] text-paper tabular-nums shrink-0">
              {{ a.details?.cost != null ? inr(a.details.cost) : '—' }}
            </span>
          </div>
          <div class="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1.5">
            <span class="text-[11px] text-silkdim">{{ a.locations?.name ?? 'No site' }}</span>
            <span class="inline-flex items-center gap-1.5">
              <span class="led" :class="a.acknowledged_at === null ? 'led-amber led-blink' : 'led-green'"></span>
              <span class="font-mono text-[10px] uppercase tracking-silk" :class="a.acknowledged_at === null ? 'text-ledamber' : 'text-ledgreen'">
                {{ a.acknowledged_at === null ? 'Pending' : 'Ack’d' }}
              </span>
            </span>
            <span class="text-[11px] text-silkfaint">{{ formatDate(a.created_at) }}</span>
          </div>
          <div class="mt-2.5 flex gap-1.5" @click.stop>
            <button v-if="a.bill_url" class="panel-btn-secondary px-2.5 py-1.5" :disabled="billLoading.has(a.id)" @click="viewBill(a)">
              {{ billLoading.has(a.id) ? 'Opening…' : 'View bill' }}
            </button>
            <button
              v-if="a.acknowledged_at === null"
              class="panel-btn-secondary px-2.5 py-1.5"
              :disabled="ackInFlight.has(a.id) || bulkAckRunning"
              @click="acknowledge(a)"
            >Acknowledge</button>
            <button class="panel-btn-ghost px-2.5 py-1.5 hover:!text-stepred" @click="confirmDelete(a)">Delete</button>
          </div>
        </li>
      </ul>

      <!-- ============ summary footer ============ -->
      <div class="border-t border-seam px-4 sm:px-5 py-3 flex flex-wrap items-center justify-between gap-2">
        <span class="text-[12px] text-silkdim">
          Showing <span class="text-paper font-semibold">{{ filteredAssets.length }}</span>
          of <span class="text-paper font-semibold">{{ assets.length }}</span> records
        </span>
        <span class="text-[12px] text-silkdim">
          Value shown: <span class="text-paper font-semibold tabular-nums">{{ inr(filteredValue) }}</span>
        </span>
      </div>
    </template>

    <!-- ============ detail / edit modal ============ -->
    <Teleport to="body">
      <div
        v-if="selectedAsset"
        class="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-black/60 p-0 sm:p-6"
        @click.self="closeModal"
      >
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="asset-modal-title"
          class="panel-module w-full sm:max-w-lg max-h-[92vh] overflow-y-auto rounded-b-none sm:rounded-b-md"
        >
          <div class="module-head sticky top-0 bg-module z-10">
            <h3 id="asset-modal-title" class="silk-label-bright truncate pr-3">
              {{ isEditing ? 'Edit record' : 'Asset record' }}
            </h3>
            <div class="flex items-center gap-2 shrink-0">
              <span class="inline-flex items-center gap-1.5">
                <span class="led" :class="selectedAsset.acknowledged_at === null ? 'led-amber led-blink' : 'led-green'"></span>
                <span class="font-mono text-[10px] uppercase tracking-silk" :class="selectedAsset.acknowledged_at === null ? 'text-ledamber' : 'text-ledgreen'">
                  {{ selectedAsset.acknowledged_at === null ? 'Pending' : 'Ack’d' }}
                </span>
              </span>
              <button class="p-1.5 text-silkfaint hover:text-paper transition-colors" aria-label="Close" @click="closeModal">
                <svg class="w-4 h-4" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          <div class="p-5">
            <div v-if="modalError" role="alert" class="panel-well flex items-start gap-2.5 px-3.5 py-2.5 mb-4">
              <span class="led led-red led-blink mt-1 shrink-0"></span>
              <p class="text-[13px] text-stepred">{{ modalError }}</p>
            </div>

            <!-- read view -->
            <dl v-if="!isEditing" class="space-y-0 divide-y divide-seam/60">
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Asset</dt>
                <dd class="text-[13px] text-paper text-right">{{ selectedAsset.name }}</dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Description</dt>
                <dd class="text-[13px] text-right whitespace-pre-wrap" :class="selectedAsset.details?.description ? 'text-paper' : 'text-silkfaint'">
                  {{ selectedAsset.details?.description || '—' }}
                </dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Cost</dt>
                <dd class="text-[13px] text-paper text-right tabular-nums">
                  {{ selectedAsset.details?.cost != null ? inr(selectedAsset.details.cost) : '—' }}
                </dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Serial</dt>
                <dd class="text-[13px] text-right break-all" :class="selectedAsset.serial_number ? 'text-paper' : 'text-silkfaint'">
                  {{ selectedAsset.serial_number ?? '—' }}
                </dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Company</dt>
                <dd class="text-[13px] text-paper text-right">{{ selectedAsset.companies?.name ?? '—' }}</dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Site</dt>
                <dd class="text-[13px] text-right" :class="selectedAsset.locations?.name ? 'text-paper' : 'text-silkfaint'">
                  {{ selectedAsset.locations?.name ?? '—' }}
                </dd>
              </div>
              <div class="py-2.5 flex items-start justify-between gap-4">
                <dt class="silk-label pt-0.5">Created</dt>
                <dd class="text-[13px] text-paper text-right">{{ formatDate(selectedAsset.created_at) }}</dd>
              </div>
              <div class="py-2.5">
                <div class="flex items-center justify-between gap-4">
                  <dt class="silk-label">Bill</dt>
                  <dd class="flex items-center gap-1.5 flex-wrap justify-end">
                    <template v-if="selectedAsset.bill_url">
                      <button class="panel-btn-secondary px-2.5 py-1.5" :disabled="billLoading.has(selectedAsset.id)" @click="viewBill(selectedAsset)">
                        {{ billLoading.has(selectedAsset.id) ? 'Opening…' : 'View' }}
                      </button>
                      <button class="panel-btn-secondary px-2.5 py-1.5" :disabled="billBusy" @click="pickBillFile">
                        {{ billBusy ? 'Working…' : 'Replace' }}
                      </button>
                      <button
                        class="panel-btn-ghost px-2.5 py-1.5"
                        :class="billArmedRemove ? '!text-stepred' : 'hover:!text-stepred'"
                        :disabled="billBusy"
                        @click="removeBill"
                      >{{ billArmedRemove ? 'Confirm remove?' : 'Remove' }}</button>
                    </template>
                    <template v-else>
                      <span class="text-[12px] text-silkfaint mr-1">none attached</span>
                      <button class="panel-btn-secondary px-2.5 py-1.5" :disabled="billBusy" @click="pickBillFile">
                        {{ billBusy ? 'Uploading…' : 'Attach bill' }}
                      </button>
                    </template>
                  </dd>
                </div>
                <input
                  ref="billFileInput"
                  type="file"
                  class="sr-only"
                  accept=".pdf,.jpg,.jpeg,.png,.webp"
                  @change="onBillFileChange"
                />
              </div>
            </dl>

            <!-- edit view -->
            <div v-else class="space-y-4">
              <div>
                <label class="silk-label block mb-1.5" for="edit-name">Asset name *</label>
                <input id="edit-name" v-model="editName" type="text" class="panel-input" />
              </div>
              <div>
                <label class="silk-label block mb-1.5" for="edit-desc">Description</label>
                <textarea id="edit-desc" v-model="editDescription" rows="3" spellcheck="false" class="panel-input resize-y"></textarea>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="silk-label block mb-1.5" for="edit-cost">Cost (INR)</label>
                  <div class="relative">
                    <span class="absolute left-3 top-1/2 -translate-y-1/2 text-silkfaint text-[13px]">₹</span>
                    <input id="edit-cost" v-model="editCost" type="number" min="0" step="0.01" class="panel-input pl-7 tabular-nums" />
                  </div>
                </div>
                <div>
                  <label class="silk-label block mb-1.5" for="edit-serial">Serial</label>
                  <input id="edit-serial" v-model="editSerial" type="text" class="panel-input" />
                </div>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="silk-label block mb-1.5" for="edit-company">Company</label>
                  <select id="edit-company" v-model="editCompanyId" class="panel-input appearance-none" @change="onEditCompanyChange">
                    <option v-for="c in companies" :key="c.id" :value="c.id">{{ c.name }}</option>
                  </select>
                </div>
                <div>
                  <label class="silk-label block mb-1.5" for="edit-location">Site</label>
                  <select id="edit-location" v-model="editLocationId" class="panel-input appearance-none">
                    <option value="">No site</option>
                    <option v-for="l in locationsForSelectedCompany" :key="l.id" :value="l.id">{{ l.name }}</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="silk-label block mb-1.5" for="edit-status">Status</label>
                <select id="edit-status" v-model="editAcknowledged" class="panel-input appearance-none">
                  <option :value="false">Pending</option>
                  <option :value="true">Acknowledged</option>
                </select>
              </div>
            </div>
          </div>

          <div class="border-t border-seam px-5 py-3.5 flex items-center justify-between gap-2 sticky bottom-0 bg-module">
            <template v-if="!isEditing">
              <button class="panel-btn-ghost hover:!text-stepred" @click="confirmDelete(selectedAsset)">Delete</button>
              <div class="flex gap-2">
                <button
                  v-if="selectedAsset.acknowledged_at === null"
                  class="panel-btn-secondary"
                  :disabled="ackInFlight.has(selectedAsset.id)"
                  @click="acknowledge(selectedAsset)"
                >{{ ackInFlight.has(selectedAsset.id) ? 'Working…' : 'Acknowledge' }}</button>
                <button class="panel-btn-primary" @click="startEdit">Edit record</button>
              </div>
            </template>
            <template v-else>
              <span></span>
              <div class="flex gap-2">
                <button class="panel-btn-secondary" :disabled="isSaving" @click="isEditing = false; modalError = ''">Cancel</button>
                <button class="panel-btn-primary" :disabled="isSaving" @click="saveAssetEdits">
                  {{ isSaving ? 'Saving…' : 'Save' }}
                </button>
              </div>
            </template>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ============ delete confirm ============ -->
    <Teleport to="body">
      <div
        v-if="deleteTarget"
        class="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 p-6"
        @click.self="deleteTarget = null"
      >
        <div role="dialog" aria-modal="true" aria-labelledby="delete-modal-title" class="panel-module w-full max-w-sm">
          <div class="module-head">
            <h3 id="delete-modal-title" class="silk-label-bright text-stepred">Delete record?</h3>
            <span class="led led-red led-blink"></span>
          </div>
          <div class="p-5">
            <p class="text-[13px] text-silk leading-relaxed">
              This erases <span class="text-paper font-semibold">{{ deleteTarget.name }}</span>
              from the register, bill included. It cannot be undone.
            </p>
            <p v-if="deleteError" class="mt-3 text-[13px] text-stepred">{{ deleteError }}</p>
          </div>
          <div class="border-t border-seam px-5 py-3.5 flex justify-end gap-2">
            <button class="panel-btn-secondary" :disabled="isDeleting" @click="deleteTarget = null">Cancel</button>
            <button class="panel-btn-primary" :disabled="isDeleting" @click="doDelete">
              {{ isDeleting ? 'Deleting…' : 'Delete' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
