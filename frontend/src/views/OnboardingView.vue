<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { z } from 'zod'
import { getCompanies, getLocations, createAsset } from '../lib/api'
import { gsap } from 'gsap'

// Form validation schema
const assetSchema = z.object({
  name: z.string().min(1, 'Asset name is required').max(255, 'Asset name is too long'),
  description: z.string().optional(),
  cost: z.union([
    z.literal(''),
    z.coerce.number().nonnegative('Cost must be zero or positive')
  ]).optional().transform((v) => (v === '' || v === undefined ? undefined : Number(v))),
  serialNumber: z.string().max(100, 'Serial number is too long').optional().or(z.literal('')),
  companyId: z.string().uuid('Please select a valid company'),
  locationId: z.string().uuid('Please select a valid location').optional(),
  billFile: z.union([z.instanceof(File), z.undefined(), z.null()]).optional()
})

type AssetForm = z.infer<typeof assetSchema>

// Form state
const currentStep = ref(1)
const totalSteps = 3
const stepLabels = ['Basic Info', 'Company & Location', 'Bill & Review']
const formData = ref<Partial<AssetForm>>({
  name: '',
  description: '',
  cost: undefined,
  serialNumber: '',
  companyId: '',
  locationId: undefined,
  billFile: undefined
})

const errors = ref<Record<string, string>>({})
const isSubmitting = ref(false)
const uploadProgress = ref(0)
const submitSuccess = ref(false)
const submitError = ref<string | null>(null)

// Companies and locations
const companies = ref<Array<{ id: string; name: string }>>([])
const locations = ref<Array<{ id: string; name: string; company_id: string }>>([])
const filteredLocations = ref<Array<{ id: string; name: string }>>([])
const isLoadingCompanies = ref(false)
const companiesError = ref<string | null>(null)

// File upload
const fileInput = ref<HTMLInputElement | null>(null)
const selectedFileName = ref<string>('')
const selectedFileSize = ref<string>('')
const isDragging = ref(false)

// GSAP animations
const stepContainer = ref<HTMLElement | null>(null)

// Review summary helpers
const selectedCompanyName = computed(
  () => companies.value.find((c) => c.id === formData.value.companyId)?.name ?? '—'
)
const selectedLocationName = computed(
  () => filteredLocations.value.find((l) => l.id === formData.value.locationId)?.name ?? '—'
)
const formatINR = (n: unknown): string =>
  typeof n === 'number' && !Number.isNaN(n)
    ? '₹' + n.toLocaleString('en-IN', { maximumFractionDigits: 2 })
    : '—'

const animateStepTransition = (direction: 'next' | 'prev') => {
  if (!stepContainer.value) return

  const tl = gsap.timeline()
  const from = direction === 'next' ? -24 : 24

  tl.to(stepContainer.value, {
    opacity: 0,
    x: from,
    duration: 0.25,
    ease: 'power2.in'
  })
    .set(stepContainer.value, { x: -from })
    .to(stepContainer.value, {
      opacity: 1,
      x: 0,
      duration: 0.35,
      ease: 'power3.out',
      clearProps: 'opacity,transform'
    })
}

// Floating label helpers
const isFocused = ref<Record<string, boolean>>({})
const hasValue = (field: string): boolean => {
  const value = (formData.value as any)[field]
  return value !== undefined && value !== null && value !== ''
}

const handleFocus = (field: string) => {
  isFocused.value[field] = true
}

const handleBlur = (field: string) => {
  isFocused.value[field] = false
}

const nextStep = () => {
  if (validateCurrentStep()) {
    if (currentStep.value < totalSteps) {
      animateStepTransition('next')
      currentStep.value++
    } else {
      submitForm()
    }
  }
}

const prevStep = () => {
  if (currentStep.value > 1) {
    animateStepTransition('prev')
    currentStep.value--
  }
}

// Allow jumping back to an already-visited step via the stepper
const goToStep = (step: number) => {
  if (step < currentStep.value) {
    animateStepTransition('prev')
    currentStep.value = step
  }
}

const validateCurrentStep = (): boolean => {
  errors.value = {}

  try {
    if (currentStep.value === 1) {
      z.object({
        name: z.string().min(1, 'Asset name is required')
      }).parse({
        name: formData.value.name
      })
    } else if (currentStep.value === 2) {
      z.object({
        companyId: z.string().uuid('Please select a company')
      }).parse({
        companyId: formData.value.companyId
      })
    }
    return true
  } catch (error) {
    if (error instanceof z.ZodError) {
      error.issues.forEach((issue: z.ZodIssue) => {
        if (issue.path[0]) {
          errors.value[issue.path[0].toString()] = issue.message
        }
      })
    }
    return false
  }
}

const validateAndSetFile = (file: File) => {
  const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    errors.value.billFile = 'Please upload a PDF or image file (JPEG, PNG, WEBP)'
    return
  }
  const maxSize = 50 * 1024 * 1024
  if (file.size > maxSize) {
    errors.value.billFile = 'File size must be less than 50MB'
    return
  }
  formData.value.billFile = file
  selectedFileName.value = file.name
  selectedFileSize.value =
    file.size >= 1024 * 1024
      ? (file.size / (1024 * 1024)).toFixed(1) + ' MB'
      : Math.max(1, Math.round(file.size / 1024)) + ' KB'
  errors.value.billFile = ''
}

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    validateAndSetFile(target.files[0])
  }
}

const handleDrop = (event: DragEvent) => {
  isDragging.value = false
  const file = event.dataTransfer?.files?.[0]
  if (file) validateAndSetFile(file)
}

const removeFile = () => {
  formData.value.billFile = undefined
  selectedFileName.value = ''
  selectedFileSize.value = ''
  if (fileInput.value) fileInput.value.value = ''
}

const filterLocations = () => {
  if (formData.value.companyId) {
    filteredLocations.value = locations.value
      .filter(loc => loc.company_id === formData.value.companyId)
      .map(loc => ({ id: loc.id, name: loc.name }))
  } else {
    filteredLocations.value = []
  }
  formData.value.locationId = undefined
}

const resetForm = () => {
  formData.value = {
    name: '',
    description: '',
    cost: undefined,
    serialNumber: '',
    companyId: '',
    locationId: undefined,
    billFile: undefined
  }
  selectedFileName.value = ''
  selectedFileSize.value = ''
  if (fileInput.value) fileInput.value.value = ''
  currentStep.value = 1
  submitSuccess.value = false
  submitError.value = null
  uploadProgress.value = 0
  errors.value = {}
}

const submitForm = async () => {
  errors.value = {}
  isSubmitting.value = true
  uploadProgress.value = 0
  submitError.value = null

  try {
    const dataToValidate = {
      name: formData.value.name || '',
      description: formData.value.description || undefined,
      cost: formData.value.cost,
      serialNumber: formData.value.serialNumber || undefined,
      companyId: formData.value.companyId || '',
      locationId: formData.value.locationId || undefined,
      billFile: formData.value.billFile || undefined
    }

    const validatedData = assetSchema.parse(dataToValidate)

    const fd = new FormData()
    fd.append('name', validatedData.name)
    fd.append('companyId', validatedData.companyId)
    if (validatedData.description) fd.append('description', validatedData.description)
    if (validatedData.cost != null && !Number.isNaN(Number(validatedData.cost))) {
      fd.append('cost', String(validatedData.cost))
    }
    if (validatedData.serialNumber?.trim()) fd.append('serialNumber', validatedData.serialNumber.trim())
    if (validatedData.locationId) fd.append('locationId', validatedData.locationId)
    if (validatedData.billFile && validatedData.billFile instanceof File) {
      fd.append('billFile', validatedData.billFile)
    }

    await createAsset(fd)
    submitSuccess.value = true
  } catch (error: unknown) {
    console.error('Submit error:', error)

    if (error instanceof z.ZodError) {
      error.issues.forEach((issue: z.ZodIssue) => {
        if (issue.path[0]) {
          errors.value[issue.path[0].toString()] = issue.message
        }
      })
      submitError.value = 'Please check the form for errors'
    } else if (error instanceof Error && error.message) {
      submitError.value = error.message
    } else if (typeof error === 'string') {
      submitError.value = error
    } else {
      submitError.value = `An unexpected error occurred: ${JSON.stringify(error)}`
    }
  } finally {
    isSubmitting.value = false
  }
}

// Load companies and locations
const loadCompanies = async () => {
  isLoadingCompanies.value = true
  companiesError.value = null
  try {
    const data = await getCompanies()
    companies.value = data || []

    if (companies.value.length === 0) {
      companiesError.value = 'No companies found. Please contact an administrator.'
    }
  } catch (error: any) {
    console.error('Error loading companies:', error)
    companiesError.value = error?.message || 'Failed to load companies. Please refresh the page.'
  } finally {
    isLoadingCompanies.value = false
  }
}

const loadLocations = async () => {
  try {
    const data = await getLocations()
    locations.value = data || []
  } catch (error) {
    console.error('Error loading locations:', error)
  }
}

onMounted(async () => {
  await loadCompanies()
  await loadLocations()

  nextTick(() => {
    if (stepContainer.value) {
      gsap.from(stepContainer.value, {
        opacity: 0,
        y: 20,
        duration: 0.4,
        ease: 'power2.out',
        clearProps: 'opacity,transform'
      })
    }
  })
})
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <!-- Header - matches admin dashboard -->
    <header class="bg-white border-b border-slate-200 shadow-sm">
      <div class="max-w-7xl mx-auto px-6 lg:px-8 py-4">
        <div class="flex justify-between items-center gap-4">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-sm shrink-0">
              <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M11.25 3.03a.75.75 0 01.75 0l8.25 4.76a.75.75 0 010 1.3L12 13.85 3.75 9.09a.75.75 0 010-1.3l7.5-4.76z" opacity=".9"/>
                <path d="M3 11.38l8.25 4.77v5.32L3.38 16.9A.75.75 0 013 16.25v-4.87zM21 11.38v4.87a.75.75 0 01-.38.65l-7.87 4.57v-5.32L21 11.38z"/>
              </svg>
            </div>
            <div>
              <h1 class="text-xl font-semibold text-slate-900">Asset Tracker</h1>
              <p class="text-sm text-slate-500">Asset onboarding</p>
            </div>
          </div>
          <a
            href="/login"
            class="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-all duration-200"
          >
            Admin
          </a>
        </div>
      </div>
    </header>

    <!-- Content -->
    <div class="flex items-start justify-center p-4 sm:p-8">
      <div class="w-full max-w-2xl">
        <!-- Intro -->
        <div class="text-center my-6 sm:my-8">
          <h2 class="text-2xl sm:text-3xl font-semibold text-slate-900 mb-2">Register a new asset</h2>
          <p class="text-sm sm:text-base text-slate-500">
            Add equipment to the register with its bill — takes under a minute
          </p>
        </div>

        <!-- Form Card -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-5 sm:p-8">
          <!-- Success state -->
          <div v-if="submitSuccess" class="py-10 text-center">
            <div class="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mb-5">
              <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-1.5">Asset registered!</h3>
            <p class="text-sm text-slate-500 mb-1">
              <strong class="text-slate-700">{{ formData.name }}</strong> has been added to the register
              and is pending admin acknowledgement.
            </p>
            <p v-if="selectedFileName" class="text-xs text-slate-400 mb-6">Bill attached: {{ selectedFileName }}</p>
            <p v-else class="text-xs text-slate-400 mb-6">No bill attached — it can be added later by an admin.</p>
            <button
              @click="resetForm"
              class="inline-flex items-center px-5 py-2.5 bg-indigo-600 text-white text-sm font-semibold rounded-lg hover:bg-indigo-700 transition-colors shadow-sm"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add another asset
            </button>
          </div>

          <template v-else>
            <!-- Stepper -->
            <div class="mb-8">
              <div class="flex items-start">
                <template v-for="(label, i) in stepLabels" :key="label">
                  <div
                    class="flex flex-col items-center shrink-0"
                    :class="{ 'cursor-pointer': currentStep > i + 1 }"
                    @click="goToStep(i + 1)"
                  >
                    <div
                      class="w-9 h-9 rounded-full flex items-center justify-center text-sm font-semibold transition-all duration-200"
                      :class="
                        currentStep > i + 1
                          ? 'bg-indigo-600 text-white'
                          : currentStep === i + 1
                            ? 'bg-indigo-600 text-white ring-4 ring-indigo-100'
                            : 'bg-slate-100 text-slate-400'
                      "
                    >
                      <svg v-if="currentStep > i + 1" class="w-4.5 h-4.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                      <span v-else>{{ i + 1 }}</span>
                    </div>
                    <span
                      class="mt-1.5 text-[11px] sm:text-xs font-medium text-center max-w-[80px] sm:max-w-none leading-tight"
                      :class="currentStep >= i + 1 ? 'text-indigo-700' : 'text-slate-400'"
                    >
                      {{ label }}
                    </span>
                  </div>
                  <div
                    v-if="i < stepLabels.length - 1"
                    class="flex-1 h-0.5 mt-[17px] mx-2 sm:mx-3 rounded transition-colors duration-300"
                    :class="currentStep > i + 1 ? 'bg-indigo-600' : 'bg-slate-200'"
                  ></div>
                </template>
              </div>
            </div>

            <!-- Error Message -->
            <div v-if="submitError" class="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl">
              <div class="flex items-start">
                <svg class="w-5 h-5 text-red-600 mr-3 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                </svg>
                <div class="flex-1">
                  <p class="text-sm font-semibold text-slate-900">Error</p>
                  <p class="text-sm text-slate-500 mt-0.5">{{ submitError }}</p>
                </div>
              </div>
            </div>

            <!-- Form Steps -->
            <div ref="stepContainer">
              <!-- Step 1: Basic Information -->
              <div v-if="currentStep === 1" class="space-y-5">
                <div class="mb-6">
                  <h2 class="text-xl font-semibold text-slate-900 mb-1">Basic Information</h2>
                  <p class="text-sm text-slate-500">What is the asset, and what did it cost?</p>
                </div>

                <!-- Asset Name -->
                <div class="relative">
                  <div class="relative">
                    <input
                      v-model="formData.name"
                      type="text"
                      @focus="handleFocus('name')"
                      @blur="handleBlur('name')"
                      class="w-full px-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 text-base font-medium"
                      :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.name }"
                      placeholder="Asset Name"
                    />
                    <label
                      class="absolute left-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.name || hasValue('name') ? 'top-2 text-xs text-slate-500 font-medium' : 'top-4 text-sm text-slate-500'"
                    >
                      Asset Name <span class="text-red-500">*</span>
                    </label>
                  </div>
                  <p v-if="errors.name" class="mt-2 text-sm text-red-600 flex items-center">
                    <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    {{ errors.name }}
                  </p>
                </div>

                <!-- Description -->
                <div class="relative">
                  <div class="relative">
                    <textarea
                      v-model="formData.description"
                      @focus="handleFocus('description')"
                      @blur="handleBlur('description')"
                      rows="3"
                      class="w-full px-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 resize-none text-base font-medium"
                      placeholder="Description"
                    ></textarea>
                    <label
                      class="absolute left-4 top-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.description || hasValue('description') ? 'top-2 text-xs text-slate-500 font-medium' : 'text-sm text-slate-500'"
                    >
                      Description (optional)
                    </label>
                  </div>
                  <p class="mt-1.5 text-xs text-slate-400">Vendor, invoice number, purchase date — anything useful for the register</p>
                </div>

                <!-- Price / Cost (INR) -->
                <div class="relative">
                  <div class="relative">
                    <span
                      class="absolute left-4 bottom-2.5 text-base font-medium text-slate-500 pointer-events-none transition-opacity duration-200"
                      :class="isFocused.cost || hasValue('cost') ? 'opacity-100' : 'opacity-0'"
                    >₹</span>
                    <input
                      v-model="formData.cost"
                      type="number"
                      min="0"
                      step="0.01"
                      @focus="handleFocus('cost')"
                      @blur="handleBlur('cost')"
                      class="w-full pl-9 pr-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 text-base font-medium"
                      :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.cost }"
                      placeholder="0.00"
                    />
                    <label
                      class="absolute left-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.cost || hasValue('cost') ? 'top-2 text-xs text-slate-500 font-medium' : 'top-4 text-sm text-slate-500'"
                    >
                      Price / Cost in INR (optional)
                    </label>
                  </div>
                  <p v-if="errors.cost" class="mt-2 text-sm text-red-600 flex items-center">
                    <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    {{ errors.cost }}
                  </p>
                </div>

                <!-- Serial Number -->
                <div class="relative">
                  <div class="relative">
                    <input
                      v-model="formData.serialNumber"
                      type="text"
                      @focus="handleFocus('serialNumber')"
                      @blur="handleBlur('serialNumber')"
                      class="w-full px-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 placeholder-transparent focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 text-base font-medium"
                      :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.serialNumber }"
                      placeholder="Serial Number"
                    />
                    <label
                      class="absolute left-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.serialNumber || hasValue('serialNumber') ? 'top-2 text-xs text-slate-500 font-medium' : 'top-4 text-sm text-slate-500'"
                    >
                      Serial Number (optional)
                    </label>
                  </div>
                  <p v-if="errors.serialNumber" class="mt-2 text-sm text-red-600 flex items-center">
                    <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    {{ errors.serialNumber }}
                  </p>
                </div>
              </div>

              <!-- Step 2: Company & Location -->
              <div v-if="currentStep === 2" class="space-y-5">
                <div class="mb-6">
                  <h2 class="text-xl font-semibold text-slate-900 mb-1">Company & Location</h2>
                  <p class="text-sm text-slate-500">Which company owns it, and where is it placed?</p>
                </div>

                <!-- Company Select -->
                <div class="relative">
                  <div class="relative">
                    <select
                      v-model="formData.companyId"
                      @change="filterLocations"
                      @focus="handleFocus('companyId')"
                      @blur="handleBlur('companyId')"
                      :disabled="isLoadingCompanies"
                      class="w-full px-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed appearance-none text-base font-medium"
                      :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.companyId || companiesError }"
                    >
                      <option value="">{{ isLoadingCompanies ? 'Loading companies...' : 'Select a company' }}</option>
                      <option v-for="company in companies" :key="company.id" :value="company.id">
                        {{ company.name }}
                      </option>
                    </select>
                    <label
                      class="absolute left-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.companyId || hasValue('companyId') ? 'top-2 text-xs text-slate-500 font-medium' : 'top-4 text-sm text-slate-500'"
                    >
                      Company <span class="text-red-500">*</span>
                    </label>
                    <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                      <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </div>
                  <p v-if="errors.companyId" class="mt-2 text-sm text-red-600 flex items-center">
                    <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    {{ errors.companyId }}
                  </p>
                  <p v-if="companiesError" class="mt-2 text-sm text-red-600">{{ companiesError }}</p>
                </div>

                <!-- Location Select -->
                <div class="relative">
                  <div class="relative">
                    <select
                      v-model="formData.locationId"
                      @focus="handleFocus('locationId')"
                      @blur="handleBlur('locationId')"
                      :disabled="!formData.companyId || filteredLocations.length === 0"
                      class="w-full px-4 pt-6 pb-2 bg-white border border-slate-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed appearance-none text-base font-medium"
                      :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.locationId }"
                    >
                      <option value="">Select a location (optional)</option>
                      <option v-for="location in filteredLocations" :key="location.id" :value="location.id">
                        {{ location.name }}
                      </option>
                    </select>
                    <label
                      class="absolute left-4 transition-all duration-200 pointer-events-none"
                      :class="isFocused.locationId || hasValue('locationId') ? 'top-2 text-xs text-slate-500 font-medium' : 'top-4 text-sm text-slate-500'"
                    >
                      Location (optional)
                    </label>
                    <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                      <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                      </svg>
                    </div>
                  </div>
                  <p v-if="errors.locationId" class="mt-2 text-sm text-red-600">{{ errors.locationId }}</p>
                  <p v-if="formData.companyId && filteredLocations.length === 0" class="mt-2 text-sm text-slate-500">
                    No locations available for this company
                  </p>
                </div>
              </div>

              <!-- Step 3: Bill Upload + Review -->
              <div v-if="currentStep === 3" class="space-y-6">
                <div class="mb-6">
                  <h2 class="text-xl font-semibold text-slate-900 mb-1">Bill & Review</h2>
                  <p class="text-sm text-slate-500">Attach the bill and confirm the details</p>
                </div>

                <!-- Dropzone -->
                <div>
                  <label class="block text-sm font-medium text-slate-500 mb-2">
                    Bill Document <span class="text-slate-400">(optional)</span>
                  </label>
                  <label
                    class="mt-1 flex justify-center px-6 py-8 border-2 border-dashed rounded-lg transition-all duration-200 cursor-pointer group"
                    :class="isDragging
                      ? 'border-indigo-500 bg-indigo-50'
                      : 'border-slate-300 bg-slate-50 hover:border-indigo-400 hover:bg-indigo-50/50'"
                    @dragover.prevent="isDragging = true"
                    @dragleave.prevent="isDragging = false"
                    @drop.prevent="handleDrop"
                  >
                    <input
                      ref="fileInput"
                      type="file"
                      class="sr-only"
                      accept=".pdf,.jpg,.jpeg,.png,.webp"
                      @change="handleFileSelect"
                    />
                    <div class="space-y-3 text-center">
                      <div class="inline-flex items-center justify-center w-12 h-12 bg-white border border-slate-200 rounded-lg group-hover:border-indigo-200 transition-colors shadow-sm">
                        <svg class="h-6 w-6 text-slate-400 group-hover:text-indigo-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5" />
                        </svg>
                      </div>
                      <div class="text-sm text-slate-600">
                        <span class="font-semibold text-indigo-600">Tap to upload</span>
                        <span class="text-slate-500"> or drag and drop</span>
                      </div>
                      <p class="text-xs text-slate-400">PDF, PNG, JPG or WEBP — up to 50MB</p>
                    </div>
                  </label>

                  <!-- Selected file chip -->
                  <div
                    v-if="selectedFileName"
                    class="mt-3 flex items-center justify-between px-4 py-3 bg-indigo-50 border border-indigo-200 rounded-lg"
                  >
                    <div class="flex items-center min-w-0">
                      <svg class="w-5 h-5 mr-2.5 text-indigo-600 shrink-0" fill="currentColor" viewBox="0 0 24 24">
                        <path fill-rule="evenodd" d="M5.625 1.5c-1.036 0-1.875.84-1.875 1.875v17.25c0 1.035.84 1.875 1.875 1.875h12.75c1.035 0 1.875-.84 1.875-1.875V12.75A3.75 3.75 0 0016.5 9h-1.875a1.875 1.875 0 01-1.875-1.875V5.25A3.75 3.75 0 009 1.5H5.625z" clip-rule="evenodd" />
                        <path d="M12.971 1.816A5.23 5.23 0 0114.25 5.25v1.875c0 .207.168.375.375.375H16.5a5.23 5.23 0 013.434 1.279 9.768 9.768 0 00-6.963-6.963z" />
                      </svg>
                      <div class="min-w-0">
                        <p class="text-sm font-medium text-slate-900 truncate">{{ selectedFileName }}</p>
                        <p class="text-xs text-slate-500">{{ selectedFileSize }}</p>
                      </div>
                    </div>
                    <button
                      type="button"
                      @click="removeFile"
                      class="ml-3 p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
                      aria-label="Remove file"
                    >
                      <svg class="w-4.5 h-4.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>

                  <p v-if="errors.billFile" class="mt-2 text-sm text-red-600">{{ errors.billFile }}</p>
                </div>

                <!-- Review summary -->
                <div class="bg-slate-50 border border-slate-200 rounded-lg p-4">
                  <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Review details</h3>
                  <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2.5 text-sm">
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Asset</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left">{{ formData.name || '—' }}</dd>
                    </div>
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Cost</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left">{{ formatINR(formData.cost) }}</dd>
                    </div>
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Serial number</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left break-all">{{ formData.serialNumber || '—' }}</dd>
                    </div>
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Company</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left">{{ selectedCompanyName }}</dd>
                    </div>
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Location</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left">{{ selectedLocationName }}</dd>
                    </div>
                    <div class="flex justify-between sm:block">
                      <dt class="text-slate-500">Bill</dt>
                      <dd class="font-medium text-slate-900 text-right sm:text-left truncate">{{ selectedFileName || 'Not attached' }}</dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>

            <!-- Navigation Buttons -->
            <div class="flex justify-between mt-8 pt-6 border-t border-slate-200">
              <button
                v-if="currentStep > 1"
                @click="prevStep"
                :disabled="isSubmitting"
                class="inline-flex items-center px-5 py-2.5 text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 font-medium text-sm"
              >
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                </svg>
                Previous
              </button>
              <div v-else></div>

              <button
                @click="nextStep"
                :disabled="isSubmitting"
                class="inline-flex items-center px-6 py-2.5 text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 font-semibold text-sm shadow-sm hover:shadow-md"
              >
                <span v-if="isSubmitting" class="flex items-center">
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Submitting...
                </span>
                <span v-else-if="currentStep === totalSteps" class="flex items-center">
                  Submit asset
                  <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                  </svg>
                </span>
                <span v-else class="flex items-center">
                  Next
                  <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                  </svg>
                </span>
              </button>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
