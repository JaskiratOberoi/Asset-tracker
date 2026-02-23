<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getAssets, getFileViewUrl, acknowledgeAsset, deleteAsset, updateAsset, getCompanies, getLocations } from '../lib/api'
import { gsap } from 'gsap'

interface Asset {
  id: string
  name: string
  details: any
  serial_number: string | null
  company_id: string
  location_id: string | null
  bill_url: string | null
  created_at: string
  acknowledged_at: string | null
  companies?: { name: string }
  locations?: { name: string }
}

const assets = ref<Asset[]>([])
const isLoading = ref(true)
const error = ref<string | null>(null)
const tableContainer = ref<HTMLElement | null>(null)
const deleteTarget = ref<Asset | null>(null)
const selectedAsset = ref<Asset | null>(null)
const isDeleting = ref(false)
const isAcknowledging = ref<string | null>(null)
const isAcknowledgingAll = ref(false)
const isEditingInModal = ref(false)
const editName = ref('')
const editDescription = ref('')
const editSerialNumber = ref('')
const editCompanyId = ref('')
const editLocationId = ref('')
const editAcknowledged = ref(false)
const isSavingAsset = ref(false)
const modalError = ref<string | null>(null)

const companies = ref<Array<{ id: string; name: string }>>([])
const locations = ref<Array<{ id: string; name: string; company_id: string }>>([])

const locationsForSelectedCompany = computed(() => {
  const companyId = isEditingInModal.value ? editCompanyId.value : selectedAsset.value?.company_id
  if (!companyId) return []
  return locations.value.filter((l) => l.company_id === companyId)
})

const syncEditFromAsset = () => {
  if (!selectedAsset.value) return
  editName.value = selectedAsset.value.name
  editDescription.value = selectedAsset.value.details?.description ?? ''
  editSerialNumber.value = selectedAsset.value.serial_number ?? ''
  editCompanyId.value = selectedAsset.value.company_id
  editLocationId.value = selectedAsset.value.location_id ?? ''
  editAcknowledged.value = !!selectedAsset.value.acknowledged_at
}

const openDetailModal = (asset: Asset) => {
  selectedAsset.value = asset
  isEditingInModal.value = false
  syncEditFromAsset()
  modalError.value = null
}

const closeDetailModal = () => {
  selectedAsset.value = null
  isEditingInModal.value = false
  modalError.value = null
}

const startEditInModal = () => {
  if (!selectedAsset.value) return
  syncEditFromAsset()
  modalError.value = null
  isEditingInModal.value = true
}

const cancelEditInModal = () => {
  isEditingInModal.value = false
  modalError.value = null
}

const onEditCompanyChange = () => {
  const locs = locationsForSelectedCompany.value
  const stillValid = locs.some((l) => l.id === editLocationId.value)
  if (!stillValid) editLocationId.value = locs[0]?.id ?? ''
}

const saveAssetEdits = async () => {
  if (!selectedAsset.value) return
  if (!editName.value.trim()) {
    modalError.value = 'Asset name is required'
    return
  }
  modalError.value = null
  isSavingAsset.value = true
  try {
    const updated = await updateAsset(selectedAsset.value.id, {
      name: editName.value.trim(),
      description: editDescription.value.trim(),
      serial_number: editSerialNumber.value.trim() || null,
      company_id: editCompanyId.value || undefined,
      location_id: editLocationId.value || null,
      acknowledged: editAcknowledged.value
    })
    const a = assets.value.find((x) => x.id === selectedAsset.value!.id)
    if (a) {
      a.name = updated.name
      a.details = updated.details
      a.serial_number = updated.serial_number
      a.company_id = updated.company_id
      a.location_id = updated.location_id
      a.acknowledged_at = updated.acknowledged_at
      const company = companies.value.find((c) => c.id === updated.company_id)
      const loc = locations.value.find((l) => l.id === updated.location_id)
      a.companies = company ? { name: company.name } : undefined
      a.locations = loc ? { name: loc.name } : undefined
    }
    selectedAsset.value.name = updated.name
    selectedAsset.value.details = updated.details
    selectedAsset.value.serial_number = updated.serial_number
    selectedAsset.value.company_id = updated.company_id
    selectedAsset.value.location_id = updated.location_id
    selectedAsset.value.acknowledged_at = updated.acknowledged_at
    const company = companies.value.find((c) => c.id === updated.company_id)
    const loc = locations.value.find((l) => l.id === updated.location_id)
    selectedAsset.value.companies = company ? { name: company.name } : undefined
    selectedAsset.value.locations = loc ? { name: loc.name } : undefined
    isEditingInModal.value = false
  } catch (err: unknown) {
    modalError.value = (err instanceof Error ? err.message : null) || 'Failed to update asset'
  } finally {
    isSavingAsset.value = false
  }
}

const pendingAssets = computed(() => assets.value.filter((a) => !a.acknowledged_at))
const hasPending = computed(() => pendingAssets.value.length > 0)

const handleViewBill = async (fileId: string) => {
  try {
    const url = await getFileViewUrl(fileId)
    window.open(url, '_blank')
  } catch (err: unknown) {
    console.error('Failed to load file:', err)
  }
}

const confirmDelete = (asset: Asset) => {
  deleteTarget.value = asset
}

const cancelDelete = () => {
  deleteTarget.value = null
}

const doDelete = async () => {
  if (!deleteTarget.value) return
  try {
    isDeleting.value = true
    await deleteAsset(deleteTarget.value.id)
    assets.value = assets.value.filter((a) => a.id !== deleteTarget.value!.id)
    deleteTarget.value = null
  } catch (err: unknown) {
    error.value = (err instanceof Error ? err.message : null) || 'Failed to delete asset'
  } finally {
    isDeleting.value = false
  }
}

const handleAcknowledge = async (asset: Asset) => {
  try {
    isAcknowledging.value = asset.id
    await acknowledgeAsset(asset.id)
    const a = assets.value.find((x) => x.id === asset.id)
    if (a) a.acknowledged_at = new Date().toISOString()
  } catch (err: unknown) {
    error.value = (err instanceof Error ? err.message : null) || 'Failed to acknowledge'
  } finally {
    isAcknowledging.value = null
  }
}

const handleAcknowledgeAll = async () => {
  if (!hasPending.value) return
  try {
    isAcknowledgingAll.value = true
    error.value = null
    const now = new Date().toISOString()
    for (const asset of pendingAssets.value) {
      await acknowledgeAsset(asset.id)
      const a = assets.value.find((x) => x.id === asset.id)
      if (a) a.acknowledged_at = now
    }
  } catch (err: unknown) {
    error.value = (err instanceof Error ? err.message : null) || 'Failed to acknowledge all'
  } finally {
    isAcknowledgingAll.value = false
  }
}

const loadAssets = async () => {
  try {
    isLoading.value = true
    error.value = null
    const data = await getAssets()
    assets.value = data || []
  } catch (err: unknown) {
    error.value = (err instanceof Error ? err.message : null) || 'Failed to load assets'
  } finally {
    isLoading.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadAssets(), getCompanies().then((r) => { companies.value = r }), getLocations().then((r) => { locations.value = r })])
  if (tableContainer.value) {
    gsap.from(tableContainer.value.querySelectorAll('tr'), {
      opacity: 0,
      x: -20,
      duration: 0.4,
      stagger: 0.05,
      ease: 'power2.out'
    })
  }
})
</script>

<template>
  <div ref="tableContainer" class="table-container">
    <div v-if="isLoading" class="text-center py-12">
      <div class="inline-flex items-center space-x-2 text-slate-600">
        <svg class="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="font-medium">Loading assets...</span>
      </div>
    </div>

    <div v-else-if="error" class="text-center py-12">
      <div class="inline-flex items-center space-x-2 text-red-600">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
        </svg>
        <span class="font-medium">{{ error }}</span>
      </div>
    </div>

    <div v-else>
      <div class="flex justify-end mb-4">
        <button
          v-if="hasPending"
          @click="handleAcknowledgeAll"
          :disabled="isAcknowledgingAll"
          class="inline-flex items-center px-4 py-2 text-sm font-semibold text-green-700 bg-green-50 rounded-lg hover:bg-green-100 disabled:opacity-50"
        >
          {{ isAcknowledgingAll ? 'Acknowledging…' : `Acknowledge all (${pendingAssets.length})` }}
        </button>
      </div>
      <div class="overflow-x-auto custom-scrollbar">
      <table class="min-w-full divide-y divide-slate-200">
        <thead>
          <tr class="bg-slate-50/80">
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Asset Name
            </th>
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Company
            </th>
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Location
            </th>
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Created
            </th>
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Bill
            </th>
            <th class="px-3 py-2.5 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-slate-100">
          <tr
            v-for="asset in assets"
            :key="asset.id"
            @click="openDetailModal(asset)"
            class="group hover:bg-gradient-to-r hover:from-indigo-50/50 hover:to-purple-50/50 transition-all duration-200 cursor-pointer border-l-4 border-transparent hover:border-indigo-400"
          >
            <td class="px-3 py-2.5">
              <div class="text-sm font-semibold text-slate-900 group-hover:text-indigo-900 transition-colors">
                {{ asset.name }}
              </div>
            </td>
            <td class="px-3 py-2.5 whitespace-nowrap">
              <span class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-semibold bg-indigo-100 text-indigo-800">
                {{ (asset.companies as any)?.name || '-' }}
              </span>
            </td>
            <td class="px-3 py-2.5 whitespace-nowrap text-sm text-slate-600">
              {{ (asset.locations as any)?.name || '—' }}
            </td>
            <td class="px-3 py-2.5 whitespace-nowrap text-sm text-slate-600">
              {{ new Date(asset.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) }}
            </td>
            <td class="px-3 py-2.5 whitespace-nowrap">
              <button
                v-if="asset.bill_url"
                @click.stop="handleViewBill(asset.bill_url!)"
                class="inline-flex items-center px-2 py-1.5 text-xs font-semibold text-indigo-700 bg-indigo-50 rounded-md hover:bg-indigo-100 hover:text-indigo-900 transition-all duration-200"
              >
                <svg class="w-3.5 h-3.5 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                View Bill
              </button>
              <span v-else class="text-xs text-slate-400">—</span>
            </td>
            <td class="px-3 py-2.5 whitespace-nowrap">
              <div class="flex items-center gap-2">
                <button
                  v-if="!asset.acknowledged_at"
                  @click.stop="handleAcknowledge(asset)"
                  :disabled="isAcknowledging === asset.id"
                  class="inline-flex items-center px-2 py-1 text-xs font-semibold text-green-700 bg-green-50 rounded-md hover:bg-green-100 disabled:opacity-50"
                >
                  {{ isAcknowledging === asset.id ? '…' : 'Acknowledge' }}
                </button>
                <button
                  @click.stop="confirmDelete(asset)"
                  class="inline-flex items-center px-2 py-1 text-xs font-semibold text-red-700 bg-red-50 rounded-md hover:bg-red-100"
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="assets.length === 0">
            <td colspan="6" class="px-8 py-16">
              <div class="flex flex-col items-center justify-center">
                <svg class="w-32 h-32 text-slate-300 mb-6" fill="none" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                  <defs>
                    <linearGradient id="emptyGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" style="stop-color:#cbd5e1;stop-opacity:0.4" />
                      <stop offset="100%" style="stop-color:#94a3b8;stop-opacity:0.6" />
                    </linearGradient>
                  </defs>
                  <rect x="60" y="50" width="80" height="80" rx="8" fill="url(#emptyGradient)" stroke="#cbd5e1" stroke-width="2"/>
                  <rect x="70" y="60" width="60" height="50" rx="4" fill="#f1f5f9" stroke="#cbd5e1" stroke-width="1.5"/>
                  <line x1="75" y1="75" x2="125" y2="75" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
                  <line x1="75" y1="90" x2="110" y2="90" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round"/>
                  <circle cx="100" cy="150" r="20" fill="#e2e8f0" stroke="#cbd5e1" stroke-width="2"/>
                  <line x1="100" y1="140" x2="100" y2="160" stroke="#94a3b8" stroke-width="2.5" stroke-linecap="round"/>
                  <line x1="90" y1="150" x2="110" y2="150" stroke="#94a3b8" stroke-width="2.5" stroke-linecap="round"/>
                </svg>
                <h3 class="text-lg font-semibold text-slate-900 mb-2">No assets found</h3>
                <p class="text-sm text-slate-500 mb-8 max-w-sm text-center">
                  Get started by adding your first asset to the system.
                </p>
                <a
                  href="/onboarding"
                  class="inline-flex items-center px-6 py-3 bg-indigo-600 text-white text-sm font-semibold rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors shadow-sm hover:shadow-md"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                  </svg>
                  Add Asset
                </a>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      </div>
    </div>

    <!-- Asset detail modal (teleported to body for full-page overlay) -->
    <Teleport to="body">
    <div
      v-if="selectedAsset"
      class="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="detail-modal-title"
      @click.self="closeDetailModal"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-lg w-full p-6 max-h-[90vh] overflow-y-auto">
        <div class="flex justify-between items-start mb-6">
          <div>
            <h2 id="detail-modal-title" class="text-lg font-semibold text-slate-900">
              {{ isEditingInModal ? editName : selectedAsset.name }}
            </h2>
            <p v-if="isEditingInModal" class="text-xs text-indigo-600 font-medium mt-1">Editing all fields</p>
          </div>
          <button
            type="button"
            @click="closeDetailModal"
            class="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
            aria-label="Close"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div v-if="modalError" class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-800">
          {{ modalError }}
        </div>
        <dl class="space-y-4">
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Asset name</dt>
            <dd v-if="!isEditingInModal" class="text-sm text-slate-700 min-h-[2.5rem] py-1">{{ selectedAsset.name }}</dd>
            <dd v-else>
              <input
                v-model="editName"
                type="text"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Asset name"
              />
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Description</dt>
            <dd v-if="!isEditingInModal" class="text-sm text-slate-700 min-h-[2.5rem] py-1">
              {{ selectedAsset.details?.description || '—' }}
            </dd>
            <dd v-else>
              <textarea
                v-model="editDescription"
                rows="3"
                spellcheck="false"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Asset description"
              />
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Serial number</dt>
            <dd v-if="!isEditingInModal" class="text-sm text-slate-700 min-h-[2.5rem] py-1">
              {{ selectedAsset.serial_number || '—' }}
            </dd>
            <dd v-else>
              <input
                v-model="editSerialNumber"
                type="text"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="Serial number"
              />
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Company</dt>
            <dd v-if="!isEditingInModal" class="text-sm text-slate-700 min-h-[2.5rem] py-1">
              {{ (selectedAsset.companies as any)?.name || '—' }}
            </dd>
            <dd v-else>
              <select
                v-model="editCompanyId"
                @change="onEditCompanyChange"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="">Select company</option>
                <option v-for="c in companies" :key="c.id" :value="c.id">{{ c.name }}</option>
              </select>
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Location</dt>
            <dd v-if="!isEditingInModal" class="text-sm text-slate-700 min-h-[2.5rem] py-1">
              {{ (selectedAsset.locations as any)?.name || '—' }}
            </dd>
            <dd v-else>
              <select
                v-model="editLocationId"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="">Select location</option>
                <option v-for="l in locationsForSelectedCompany" :key="l.id" :value="l.id">{{ l.name }}</option>
              </select>
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Status</dt>
            <dd v-if="!isEditingInModal">
              <span
                v-if="selectedAsset.acknowledged_at"
                class="inline-flex items-center px-3 py-1 rounded-lg text-sm font-semibold bg-green-100 text-green-800"
              >Acknowledged</span>
              <span v-else class="inline-flex items-center px-3 py-1 rounded-lg text-sm font-semibold bg-amber-100 text-amber-800">Pending</span>
            </dd>
            <dd v-else>
              <select
                v-model="editAcknowledged"
                class="w-full px-3 py-2 text-sm bg-white border border-slate-300 rounded-lg text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option :value="false">Pending</option>
                <option :value="true">Acknowledged</option>
              </select>
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Created</dt>
            <dd class="text-sm text-slate-700 py-1">
              {{ new Date(selectedAsset.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) }}
            </dd>
          </div>
          <div>
            <dt class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Bill</dt>
            <dd class="text-sm py-1">
              <button
                v-if="selectedAsset.bill_url"
                type="button"
                @click.stop="handleViewBill(selectedAsset.bill_url!)"
                class="inline-flex items-center px-2 py-1 text-xs font-semibold text-indigo-700 bg-indigo-50 rounded-md hover:bg-indigo-100"
              >
                View Bill
              </button>
              <span v-else class="text-slate-500">—</span>
            </dd>
          </div>
        </dl>
        <div class="mt-6 pt-4 border-t border-slate-200 flex flex-col gap-2">
          <template v-if="isEditingInModal">
            <div class="flex gap-2">
              <button
                type="button"
                @click="saveAssetEdits"
                :disabled="isSavingAsset"
                class="flex-1 py-2.5 text-sm font-medium text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition"
              >
                {{ isSavingAsset ? 'Saving…' : 'Save' }}
              </button>
              <button
                type="button"
                @click="cancelEditInModal"
                :disabled="isSavingAsset"
                class="flex-1 py-2.5 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 disabled:opacity-50 transition"
              >
                Cancel
              </button>
            </div>
          </template>
          <template v-else>
            <button
              type="button"
              @click="startEditInModal"
              class="w-full py-2.5 text-sm font-medium text-indigo-700 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition"
            >
              Edit asset
            </button>
          </template>
        </div>
      </div>
    </div>
    </Teleport>

    <!-- Delete confirmation modal (teleported to body for full-page overlay) -->
    <Teleport to="body">
    <div
      v-if="deleteTarget"
      class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="delete-modal-title"
    >
      <div class="bg-white rounded-xl shadow-xl max-w-md w-full p-6" @click.stop>
        <h2 id="delete-modal-title" class="text-lg font-semibold text-slate-900 mb-2">Delete asset?</h2>
        <p class="text-sm text-slate-600 mb-6">
          Are you sure you want to delete <strong>{{ deleteTarget.name }}</strong>? This cannot be undone.
        </p>
        <div class="flex justify-end gap-3">
          <button
            @click="cancelDelete"
            :disabled="isDeleting"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            @click="doDelete"
            :disabled="isDeleting"
            class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50"
          >
            {{ isDeleting ? 'Deleting…' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
    </Teleport>
  </div>
</template>
