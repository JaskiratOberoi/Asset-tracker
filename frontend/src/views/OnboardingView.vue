<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { z } from 'zod'
import { gsap } from 'gsap'
import { getCompanies, getLocations, createAsset, createLocation } from '../lib/api'
import { inr } from '../lib/useRegister'

// --- validation (unchanged contract) ---------------------------------------
const assetSchema = z.object({
  name: z.string().min(1, 'Asset name is required').max(255, 'Asset name is too long'),
  description: z.string().optional(),
  cost: z
    .union([z.literal(''), z.coerce.number().nonnegative('Cost must be zero or positive')])
    .optional()
    .transform(v => (v === '' || v === undefined ? undefined : Number(v))),
  serialNumber: z.string().max(100, 'Serial number is too long').optional().or(z.literal('')),
  companyId: z.string().uuid('Please select a valid company'),
  locationId: z.string().uuid('Please select a valid location').optional(),
  billFile: z.union([z.instanceof(File), z.undefined(), z.null()]).optional(),
})

// --- form state -------------------------------------------------------------
const currentStep = ref(1)
const totalSteps = 3
const stepLabels = ['Basic Info', 'Company & Site', 'Bill & Review']

const name = ref('')
const description = ref('')
const cost = ref<string>('')
const serialNumber = ref('')
const companyId = ref<string | undefined>(undefined)
const locationId = ref<string | undefined>(undefined)
const billFile = ref<File | null>(null)
const selectedFileName = ref('')
const selectedFileSize = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)

const errors = ref<Record<string, string>>({})
const isSubmitting = ref(false)
const submitError = ref('')
const submitSuccess = ref(false)

// --- reference data ---------------------------------------------------------
const companies = ref<Array<{ id: string; name: string }>>([])
const locations = ref<Array<{ id: string; name: string; company_id: string }>>([])
const isLoadingCompanies = ref(true)
const companiesError = ref('')

onMounted(async () => {
  try {
    companies.value = await getCompanies()
    if (companies.value.length === 0) {
      companiesError.value = 'No companies found. Please contact an administrator.'
    }
  } catch (e) {
    companiesError.value = e instanceof Error ? e.message : 'Failed to load companies'
  } finally {
    isLoadingCompanies.value = false
  }
  try {
    locations.value = await getLocations()
  } catch {
    /* locations are optional; the select stays empty */
  }
  if (formCard.value) {
    gsap.fromTo(formCard.value, { opacity: 0, y: 16 }, { opacity: 1, y: 0, duration: 0.45, ease: 'power3.out' })
  }
})

const filteredLocations = computed(() =>
  companyId.value ? locations.value.filter(l => l.company_id === companyId.value) : []
)

function onCompanyChange() {
  locationId.value = undefined
  addingLocation.value = false
}

const selectedCompanyName = computed(
  () => companies.value.find(c => c.id === companyId.value)?.name ?? '—'
)
const selectedLocationName = computed(
  () => locations.value.find(l => l.id === locationId.value)?.name ?? '—'
)

// --- inline "new site" (surfaces POST /api/locations) -----------------------
const addingLocation = ref(false)
const newLocationName = ref('')
const isSavingLocation = ref(false)
const locationError = ref('')

async function saveNewLocation() {
  if (!companyId.value) return
  const trimmed = newLocationName.value.trim()
  if (!trimmed) {
    locationError.value = 'Enter a site name'
    return
  }
  isSavingLocation.value = true
  locationError.value = ''
  try {
    const loc = await createLocation(trimmed, companyId.value)
    locations.value = [...locations.value, loc]
    locationId.value = loc.id
    addingLocation.value = false
    newLocationName.value = ''
  } catch (e) {
    locationError.value = e instanceof Error ? e.message : 'Failed to create site'
  } finally {
    isSavingLocation.value = false
  }
}

// --- file handling ----------------------------------------------------------
const ALLOWED_MIME = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'image/webp']
const MAX_FILE_SIZE = 50 * 1024 * 1024

function validateAndSetFile(file: File) {
  if (!ALLOWED_MIME.includes(file.type)) {
    errors.value.billFile = 'Please upload a PDF or image file (JPEG, PNG, WEBP)'
    return
  }
  if (file.size > MAX_FILE_SIZE) {
    errors.value.billFile = 'File size must be less than 50MB'
    return
  }
  delete errors.value.billFile
  billFile.value = file
  selectedFileName.value = file.name
  selectedFileSize.value =
    file.size >= 1024 * 1024
      ? `${(file.size / (1024 * 1024)).toFixed(1)} MB`
      : `${Math.max(1, Math.round(file.size / 1024))} KB`
}

function onFileChange(e: Event) {
  const files = (e.target as HTMLInputElement).files
  if (files && files[0]) validateAndSetFile(files[0])
}

function onDrop(e: DragEvent) {
  isDragging.value = false
  const files = e.dataTransfer?.files
  if (files && files[0]) validateAndSetFile(files[0])
}

function removeFile() {
  billFile.value = null
  selectedFileName.value = ''
  selectedFileSize.value = ''
  if (fileInput.value) fileInput.value.value = ''
}

// --- step navigation --------------------------------------------------------
const formCard = ref<HTMLElement | null>(null)
const stepPanel = ref<HTMLElement | null>(null)

function validateCurrentStep(): boolean {
  errors.value = {}
  if (currentStep.value === 1) {
    const r = z.object({ name: z.string().min(1, 'Asset name is required') }).safeParse({ name: name.value })
    if (!r.success) {
      errors.value.name = r.error.issues[0]?.message ?? 'Asset name is required'
      return false
    }
  }
  if (currentStep.value === 2) {
    const r = z.object({ companyId: z.string().uuid('Please select a company') }).safeParse({ companyId: companyId.value })
    if (!r.success) {
      errors.value.companyId = 'Please select a company'
      return false
    }
  }
  return true
}

async function animateStep(dir: 'next' | 'prev') {
  if (!stepPanel.value) return
  const offset = dir === 'next' ? 24 : -24
  gsap.fromTo(
    stepPanel.value,
    { opacity: 0, x: offset },
    { opacity: 1, x: 0, duration: 0.28, ease: 'power2.out' }
  )
}

async function nextStep() {
  if (!validateCurrentStep()) return
  if (currentStep.value < totalSteps) {
    currentStep.value++
    await nextTick()
    animateStep('next')
  } else {
    await submitForm()
  }
}

async function prevStep() {
  if (currentStep.value > 1) {
    currentStep.value--
    await nextTick()
    animateStep('prev')
  }
}

async function goToStep(step: number) {
  if (step < currentStep.value) {
    currentStep.value = step
    await nextTick()
    animateStep('prev')
  }
}

// --- submit -----------------------------------------------------------------
async function submitForm() {
  submitError.value = ''
  errors.value = {}
  try {
    const parsed = assetSchema.parse({
      name: name.value,
      description: description.value,
      cost: cost.value,
      serialNumber: serialNumber.value,
      companyId: companyId.value,
      locationId: locationId.value,
      billFile: billFile.value,
    })
    isSubmitting.value = true
    const fd = new FormData()
    fd.append('name', parsed.name)
    fd.append('companyId', parsed.companyId)
    if (parsed.description) fd.append('description', parsed.description)
    if (parsed.cost !== undefined && !Number.isNaN(parsed.cost)) fd.append('cost', String(parsed.cost))
    if (parsed.serialNumber && parsed.serialNumber.trim()) fd.append('serialNumber', parsed.serialNumber.trim())
    if (parsed.locationId) fd.append('locationId', parsed.locationId)
    if (billFile.value) fd.append('billFile', billFile.value)
    await createAsset(fd)
    submitSuccess.value = true
  } catch (e) {
    if (e instanceof z.ZodError) {
      for (const issue of e.issues) {
        const key = issue.path[0]
        if (typeof key === 'string' && !errors.value[key]) errors.value[key] = issue.message
      }
      submitError.value = 'Please check the form for errors'
    } else {
      submitError.value = e instanceof Error ? e.message : 'Failed to register the asset'
    }
  } finally {
    isSubmitting.value = false
  }
}

function resetForm() {
  name.value = ''
  description.value = ''
  cost.value = ''
  serialNumber.value = ''
  companyId.value = undefined
  locationId.value = undefined
  removeFile()
  errors.value = {}
  submitError.value = ''
  submitSuccess.value = false
  currentStep.value = 1
}

// --- live record label ------------------------------------------------------
const costNumber = computed(() => {
  if (cost.value === '' || cost.value === null) return undefined
  const n = Number(cost.value)
  return Number.isFinite(n) ? n : undefined
})

const recordRows = computed(() => [
  { label: 'Asset', value: name.value.trim() || null },
  { label: 'Cost', value: costNumber.value !== undefined ? inr(costNumber.value) : null },
  { label: 'Serial', value: serialNumber.value.trim() || null },
  { label: 'Company', value: companyId.value ? selectedCompanyName.value : null },
  { label: 'Site', value: locationId.value ? selectedLocationName.value : null },
  { label: 'Bill', value: selectedFileName.value || null },
])

const STEP_KEY_COLOR = ['key-red', 'key-orange', 'key-yellow']
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <header class="border-b border-seam bg-panel sticky top-0 z-40">
      <div class="max-w-6xl mx-auto px-5 sm:px-8 py-4 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <span class="font-plate text-lg text-paper tracking-wide">AR-9</span>
          <span class="hidden sm:block h-4 w-px bg-seamlight"></span>
          <span class="hidden sm:block silk-label">Asset Register · Intake</span>
        </div>
        <a href="/login" class="panel-btn-secondary py-2">Admin</a>
      </div>
    </header>

    <main class="flex-1 w-full max-w-6xl mx-auto px-5 sm:px-8 py-8 sm:py-12">
      <div class="mb-8 sm:mb-10">
        <h1 class="font-display text-4xl sm:text-6xl leading-none uppercase text-paper">
          Write it into<br />the register.
        </h1>
        <p class="mt-4 max-w-xl text-[13px] leading-relaxed text-silkdim">
          Every purchase becomes a numbered record: what it is, what it cost,
          which company owns it, where it sits, and the bill that proves it.
          Three sections, then write.
        </p>
      </div>

      <div ref="formCard" class="grid lg:grid-cols-3 gap-5 items-start">
        <!-- ================= form console ================= -->
        <div class="lg:col-span-2 panel-module overflow-hidden">
          <!-- success state replaces the console -->
          <div v-if="submitSuccess" class="p-8 sm:p-12 text-center">
            <div class="inline-flex items-center gap-2.5 mb-6">
              <span class="led led-green"></span>
              <span class="silk-label-bright text-ledgreen">Record written</span>
            </div>
            <h2 class="font-display text-3xl sm:text-4xl uppercase text-paper mb-3">Asset registered</h2>
            <p class="text-[13px] text-silkdim leading-relaxed max-w-md mx-auto">
              <span class="text-paper font-semibold">{{ name }}</span> is in the register,
              pending admin acknowledgement.
              {{ selectedFileName ? 'Bill attached: ' + selectedFileName : 'No bill attached — it can be added later by an admin.' }}
            </p>
            <button class="panel-btn-primary mt-8" @click="resetForm">Register another asset</button>
          </div>

          <template v-else>
            <!-- stepper: three bank keys -->
            <div class="module-head">
              <h2 class="silk-label-bright">Intake · Section {{ currentStep }} of {{ totalSteps }}</h2>
              <span class="silk-label text-silkfaint">FORM AR-9/A</span>
            </div>
            <div class="px-5 sm:px-6 pt-5">
              <div class="grid grid-cols-3 gap-2">
                <button
                  v-for="(label, i) in stepLabels"
                  :key="label"
                  type="button"
                  class="step-key h-11"
                  :class="[
                    STEP_KEY_COLOR[i],
                    i + 1 > currentStep ? 'key-unlit' : '',
                    i + 1 === currentStep ? 'ring-2 ring-stepred' : '',
                  ]"
                  :disabled="i + 1 >= currentStep"
                  :aria-current="i + 1 === currentStep ? 'step' : undefined"
                  :title="i + 1 < currentStep ? 'Back to ' + label : label"
                  @click="goToStep(i + 1)"
                >
                  <span class="key-window" :class="{ 'key-window-lit': i + 1 <= currentStep }"></span>
                </button>
              </div>
              <div class="grid grid-cols-3 gap-2 mt-1.5">
                <span
                  v-for="(label, i) in stepLabels"
                  :key="label"
                  class="text-center font-mono text-[10px] tracking-silk uppercase"
                  :class="i + 1 === currentStep ? 'text-paper font-semibold' : 'text-silkfaint'"
                >{{ label }}</span>
              </div>
            </div>

            <form class="p-5 sm:p-6" @submit.prevent="nextStep">
              <div
                v-if="submitError"
                role="alert"
                class="panel-well flex items-start gap-2.5 px-3.5 py-3 mb-5"
              >
                <span class="led led-red led-blink mt-1 shrink-0"></span>
                <p class="text-[13px] leading-snug text-stepred">{{ submitError }}</p>
              </div>

              <div ref="stepPanel">
                <!-- ============ section 1: basic info ============ -->
                <div v-if="currentStep === 1" class="space-y-5">
                  <p class="text-[13px] text-silkdim">What is the asset, and what did it cost?</p>

                  <div>
                    <label for="ob-name" class="silk-label block mb-1.5">Asset name *</label>
                    <input
                      id="ob-name"
                      v-model="name"
                      type="text"
                      class="panel-input"
                      :class="errors.name ? 'border-stepred' : ''"
                      placeholder="e.g. Centrifuge R-8C"
                    />
                    <p v-if="errors.name" class="mt-1.5 text-[12px] text-stepred">{{ errors.name }}</p>
                  </div>

                  <div>
                    <label for="ob-desc" class="silk-label block mb-1.5">Description (optional)</label>
                    <textarea
                      id="ob-desc"
                      v-model="description"
                      rows="3"
                      class="panel-input resize-y"
                      placeholder="Vendor, invoice number, purchase date — anything useful for the register"
                    ></textarea>
                  </div>

                  <div class="grid sm:grid-cols-2 gap-5">
                    <div>
                      <label for="ob-cost" class="silk-label block mb-1.5">Cost in INR (optional)</label>
                      <div class="relative">
                        <span class="absolute left-3 top-1/2 -translate-y-1/2 text-silkfaint text-[13px]">₹</span>
                        <input
                          id="ob-cost"
                          v-model="cost"
                          type="number"
                          min="0"
                          step="0.01"
                          class="panel-input pl-7 tabular-nums"
                          :class="errors.cost ? 'border-stepred' : ''"
                          placeholder="0"
                        />
                      </div>
                      <p v-if="errors.cost" class="mt-1.5 text-[12px] text-stepred">{{ errors.cost }}</p>
                    </div>
                    <div>
                      <label for="ob-serial" class="silk-label block mb-1.5">Serial number (optional)</label>
                      <input
                        id="ob-serial"
                        v-model="serialNumber"
                        type="text"
                        class="panel-input"
                        :class="errors.serialNumber ? 'border-stepred' : ''"
                        placeholder="SN-000000"
                      />
                      <p v-if="errors.serialNumber" class="mt-1.5 text-[12px] text-stepred">{{ errors.serialNumber }}</p>
                    </div>
                  </div>
                </div>

                <!-- ============ section 2: company & site ============ -->
                <div v-else-if="currentStep === 2" class="space-y-5">
                  <p class="text-[13px] text-silkdim">Which company owns it, and where is it placed?</p>

                  <div>
                    <label for="ob-company" class="silk-label block mb-1.5">Company *</label>
                    <div class="relative">
                      <select
                        id="ob-company"
                        v-model="companyId"
                        class="panel-input appearance-none pr-9"
                        :class="errors.companyId ? 'border-stepred' : ''"
                        :disabled="isLoadingCompanies"
                        @change="onCompanyChange"
                      >
                        <option :value="undefined" disabled>
                          {{ isLoadingCompanies ? 'Loading companies…' : 'Select a company' }}
                        </option>
                        <option v-for="c in companies" :key="c.id" :value="c.id">{{ c.name }}</option>
                      </select>
                      <svg class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-silkfaint" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                      </svg>
                    </div>
                    <p v-if="errors.companyId" class="mt-1.5 text-[12px] text-stepred">{{ errors.companyId }}</p>
                    <p v-if="companiesError" class="mt-1.5 text-[12px] text-ledamber">{{ companiesError }}</p>
                  </div>

                  <div>
                    <div class="flex items-center justify-between mb-1.5">
                      <label for="ob-location" class="silk-label">Site (optional)</label>
                      <button
                        v-if="companyId && !addingLocation"
                        type="button"
                        class="silk-label text-silk hover:text-paper transition-colors"
                        @click="addingLocation = true"
                      >+ New site</button>
                    </div>

                    <template v-if="!addingLocation">
                      <div class="relative">
                        <select
                          id="ob-location"
                          v-model="locationId"
                          class="panel-input appearance-none pr-9"
                          :disabled="!companyId || filteredLocations.length === 0"
                        >
                          <option :value="undefined">
                            {{ !companyId ? 'Select a company first'
                              : filteredLocations.length === 0 ? 'No sites for this company'
                              : 'Select a site' }}
                          </option>
                          <option v-for="l in filteredLocations" :key="l.id" :value="l.id">{{ l.name }}</option>
                        </select>
                        <svg class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-silkfaint" width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
                        </svg>
                      </div>
                      <p v-if="companyId && filteredLocations.length === 0" class="mt-1.5 text-[12px] text-silkfaint">
                        No sites recorded for this company yet — add one with “New site”.
                      </p>
                    </template>

                    <div v-else class="flex gap-2">
                      <input
                        v-model="newLocationName"
                        type="text"
                        class="panel-input flex-1"
                        placeholder="Site name, e.g. Jaipur"
                        @keydown.enter.prevent="saveNewLocation"
                      />
                      <button
                        type="button"
                        class="panel-btn-primary"
                        :disabled="isSavingLocation"
                        @click="saveNewLocation"
                      >{{ isSavingLocation ? 'Saving' : 'Save' }}</button>
                      <button
                        type="button"
                        class="panel-btn-secondary"
                        @click="addingLocation = false; newLocationName = ''; locationError = ''"
                      >Cancel</button>
                    </div>
                    <p v-if="locationError" class="mt-1.5 text-[12px] text-stepred">{{ locationError }}</p>
                  </div>
                </div>

                <!-- ============ section 3: bill & review ============ -->
                <div v-else class="space-y-5">
                  <p class="text-[13px] text-silkdim">Attach the bill and confirm the record.</p>

                  <div>
                    <span class="silk-label block mb-1.5">Bill document (optional)</span>
                    <label
                      class="panel-well flex flex-col items-center justify-center gap-2 px-4 py-8 cursor-pointer border-dashed transition-colors"
                      :class="isDragging ? 'border-stepred' : 'hover:border-seamlight'"
                      @dragover.prevent="isDragging = true"
                      @dragleave.prevent="isDragging = false"
                      @drop.prevent="onDrop"
                    >
                      <input
                        ref="fileInput"
                        type="file"
                        class="sr-only"
                        accept=".pdf,.jpg,.jpeg,.png,.webp"
                        @change="onFileChange"
                      />
                      <svg class="w-6 h-6 text-silkfaint" width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" />
                      </svg>
                      <span class="text-[13px] text-silk">Tap to upload, or drag and drop</span>
                      <span class="text-[11px] text-silkfaint">PDF, PNG, JPG or WEBP — up to 50 MB</span>
                    </label>
                    <p v-if="errors.billFile" class="mt-1.5 text-[12px] text-stepred">{{ errors.billFile }}</p>

                    <div v-if="selectedFileName" class="mt-2.5 panel-well flex items-center gap-3 px-3.5 py-2.5">
                      <span class="led led-green shrink-0"></span>
                      <span class="text-[13px] text-paper truncate flex-1" :title="selectedFileName">{{ selectedFileName }}</span>
                      <span class="text-[11px] text-silkfaint shrink-0">{{ selectedFileSize }}</span>
                      <button
                        type="button"
                        class="p-1 text-silkfaint hover:text-stepred transition-colors shrink-0"
                        aria-label="Remove file"
                        @click="removeFile"
                      >
                        <svg class="w-4 h-4" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  </div>

                  <div>
                    <span class="silk-label block mb-1.5">Review</span>
                    <dl class="panel-well divide-y divide-seam/70">
                      <div v-for="row in recordRows" :key="row.label" class="flex items-center justify-between gap-4 px-3.5 py-2.5">
                        <dt class="silk-label">{{ row.label }}</dt>
                        <dd class="text-[13px] text-right truncate" :class="row.value ? 'text-paper' : 'text-silkfaint'">
                          {{ row.value ?? '—' }}
                        </dd>
                      </div>
                    </dl>
                  </div>
                </div>
              </div>

              <!-- navigation -->
              <div class="mt-7 flex items-center justify-between gap-3">
                <button
                  v-if="currentStep > 1"
                  type="button"
                  class="panel-btn-secondary"
                  :disabled="isSubmitting"
                  @click="prevStep"
                >← Previous</button>
                <span v-else></span>
                <button type="submit" class="panel-btn-primary min-w-[10rem]" :disabled="isSubmitting">
                  <svg v-if="isSubmitting" class="w-3.5 h-3.5 animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.25" />
                    <path d="M12 2a10 10 0 019.95 9" stroke="currentColor" stroke-width="3" stroke-linecap="round" />
                  </svg>
                  {{ isSubmitting ? 'Writing' : currentStep === totalSteps ? 'Write record' : 'Next →' }}
                </button>
              </div>
            </form>
          </template>
        </div>

        <!-- ================= live record label ================= -->
        <aside class="panel-module overflow-hidden lg:sticky lg:top-24">
          <div class="module-head">
            <h2 class="silk-label-bright">Record preview</h2>
            <span
              class="flex items-center gap-1.5"
            >
              <span class="led" :class="submitSuccess ? 'led-green' : 'led-amber led-blink'"></span>
              <span class="silk-label" :class="submitSuccess ? 'text-ledgreen' : 'text-ledamber'">
                {{ submitSuccess ? 'Written' : 'Unwritten' }}
              </span>
            </span>
          </div>
          <dl class="p-4 space-y-1">
            <div
              v-for="row in recordRows"
              :key="row.label"
              class="flex items-center gap-3 px-2 py-2 rounded border border-transparent"
            >
              <span class="led shrink-0" :class="row.value ? 'led-green' : ''"></span>
              <dt class="silk-label w-16 shrink-0">{{ row.label }}</dt>
              <dd
                class="text-[13px] truncate text-right flex-1"
                :class="row.value ? 'text-paper' : 'text-silkfaint'"
                :title="row.value ?? undefined"
              >{{ row.value ?? 'not set' }}</dd>
            </div>
          </dl>
          <div class="border-t border-seam px-4 py-3">
            <p class="text-[11px] leading-relaxed text-silkfaint">
              Records land as <span class="text-ledamber">pending</span> until an admin
              acknowledges them in the console.
            </p>
          </div>
        </aside>
      </div>
    </main>

    <footer class="border-t border-seam">
      <div class="max-w-6xl mx-auto px-5 sm:px-8 py-4 flex items-center justify-between">
        <span class="silk-label text-silkfaint">AR-9 · Computer controlled asset register</span>
        <span class="silk-label text-silkfaint">Qugen Pathlabs group</span>
      </div>
    </footer>
  </div>
</template>
