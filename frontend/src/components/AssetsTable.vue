<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getAssets, getFileViewUrl } from '../lib/api'
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
  companies?: { name: string }
  locations?: { name: string }
}

const assets = ref<Asset[]>([])
const isLoading = ref(true)
const error = ref<string | null>(null)
const tableContainer = ref<HTMLElement | null>(null)

const handleViewBill = async (fileId: string) => {
  try {
    const url = await getFileViewUrl(fileId)
    window.open(url, '_blank')
  } catch (err: unknown) {
    console.error('Failed to load file:', err)
  }
}

const loadAssets = async () => {
  try {
    isLoading.value = true
    const data = await getAssets()
    assets.value = data || []
  } catch (err: any) {
    error.value = err.message || 'Failed to load assets'
  } finally {
    isLoading.value = false
  }
}

onMounted(async () => {
  await loadAssets()

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

    <div v-else class="overflow-x-auto custom-scrollbar">
      <table class="min-w-full divide-y divide-slate-200">
        <thead>
          <tr class="bg-slate-50/80">
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Asset Name
            </th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Serial Number
            </th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Company
            </th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Location
            </th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Created
            </th>
            <th class="px-6 py-4 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
              Bill
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-slate-100">
          <tr
            v-for="asset in assets"
            :key="asset.id"
            class="group hover:bg-gradient-to-r hover:from-indigo-50/50 hover:to-purple-50/50 transition-all duration-200 cursor-pointer border-l-4 border-transparent hover:border-indigo-400"
          >
            <td class="px-6 py-5">
              <div class="text-sm font-semibold text-slate-900 group-hover:text-indigo-900 transition-colors">
                {{ asset.name }}
              </div>
              <div v-if="asset.details?.description" class="text-sm text-slate-600 mt-1 font-normal">
                {{ asset.details.description }}
              </div>
            </td>
            <td class="px-6 py-5 whitespace-nowrap">
              <span class="text-sm text-slate-600 font-medium">
                {{ asset.serial_number || '-' }}
              </span>
            </td>
            <td class="px-6 py-5 whitespace-nowrap">
              <span class="inline-flex items-center px-3 py-1 rounded-lg text-sm font-semibold bg-indigo-100 text-indigo-800">
                {{ (asset.companies as any)?.name || '-' }}
              </span>
            </td>
            <td class="px-6 py-5 whitespace-nowrap">
              <span class="text-sm text-slate-600 font-medium">
                {{ (asset.locations as any)?.name || '-' }}
              </span>
            </td>
            <td class="px-6 py-5 whitespace-nowrap">
              <span class="text-sm text-slate-600 font-medium">
                {{ new Date(asset.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) }}
              </span>
            </td>
            <td class="px-6 py-5 whitespace-nowrap">
              <button
                v-if="asset.bill_url"
                @click="handleViewBill(asset.bill_url!)"
                class="inline-flex items-center px-4 py-2 text-sm font-semibold text-indigo-700 bg-indigo-50 rounded-lg hover:bg-indigo-100 hover:text-indigo-900 transition-all duration-200 shadow-sm hover:shadow-md"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                View Bill
              </button>
              <span v-else class="text-sm text-slate-400 font-medium">-</span>
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
</template>
