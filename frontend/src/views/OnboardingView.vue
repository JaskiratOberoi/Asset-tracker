<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import { z } from 'zod'
import { getCompanies, getLocations, createAsset } from '../lib/api'
import { gsap } from 'gsap'

// Form validation schema
const assetSchema = z.object({
  name: z.string().min(1, 'Asset name is required').max(255, 'Asset name is too long'),
  description: z.string().optional(),
  serialNumber: z.string().max(100, 'Serial number is too long').optional().or(z.literal('')),
  companyId: z.string().uuid('Please select a valid company'),
  locationId: z.string().uuid('Please select a valid location').optional(),
  billFile: z.union([z.instanceof(File), z.undefined(), z.null()]).optional()
})

type AssetForm = z.infer<typeof assetSchema>

// Form state
const currentStep = ref(1)
const totalSteps = 3
const formData = ref<Partial<AssetForm>>({
  name: '',
  description: '',
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

// GSAP animations
const stepContainer = ref<HTMLElement | null>(null)

const animateStepTransition = (direction: 'next' | 'prev') => {
  if (!stepContainer.value) return
  
  const tl = gsap.timeline()
  
  if (direction === 'next') {
    tl.to(stepContainer.value, {
      opacity: 0,
      x: -30,
      scale: 0.95,
      duration: 0.4,
      ease: 'power2.in'
    })
    .set(stepContainer.value, { x: 30, scale: 0.95 })
    .to(stepContainer.value, {
      opacity: 1,
      x: 0,
      scale: 1,
      duration: 0.5,
      ease: 'power3.out'
    })
  } else {
    tl.to(stepContainer.value, {
      opacity: 0,
      x: 30,
      scale: 0.95,
      duration: 0.4,
      ease: 'power2.in'
    })
    .set(stepContainer.value, { x: -30, scale: 0.95 })
    .to(stepContainer.value, {
      opacity: 1,
      x: 0,
      scale: 1,
      duration: 0.5,
      ease: 'power3.out'
    })
  }
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

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    
    // Validate file type
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      errors.value.billFile = 'Please upload a PDF or image file (JPEG, PNG, WEBP)'
      return
    }
    
    // Validate file size (50MB)
    const maxSize = 50 * 1024 * 1024
    if (file.size > maxSize) {
      errors.value.billFile = 'File size must be less than 50MB'
      return
    }
    
    formData.value.billFile = file
    selectedFileName.value = file.name
    errors.value.billFile = ''
  }
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

const submitForm = async () => {
  errors.value = {}
  isSubmitting.value = true
  uploadProgress.value = 0
  submitError.value = null
  
  try {
    // Validate entire form (billFile is optional - can be undefined, null, or File)
    const dataToValidate = {
      name: formData.value.name || '',
      description: formData.value.description || undefined,
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
    if (validatedData.serialNumber?.trim()) fd.append('serialNumber', validatedData.serialNumber.trim())
    if (validatedData.locationId) fd.append('locationId', validatedData.locationId)
    if (validatedData.billFile && validatedData.billFile instanceof File) {
      fd.append('billFile', validatedData.billFile)
    }

    await createAsset(fd)
    submitSuccess.value = true
    
    // Reset form after 3 seconds
    setTimeout(() => {
      formData.value = {
        name: '',
        description: '',
        serialNumber: '',
        companyId: '',
        locationId: undefined,
        billFile: undefined
      }
      selectedFileName.value = ''
      if (fileInput.value) (fileInput.value as HTMLInputElement).value = ''
      currentStep.value = 1
      submitSuccess.value = false
      uploadProgress.value = 0
    }, 3000)
    
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
  
  // Animate initial load
  nextTick(() => {
    if (stepContainer.value) {
      gsap.from(stepContainer.value, {
        opacity: 0,
        y: 20,
        duration: 0.4,
        ease: 'power2.out'
      })
    }
  })
})
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <!-- Content -->
    <div class="flex items-center justify-center min-h-screen p-8">
      <div class="w-full max-w-2xl">
        <!-- Header -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-semibold text-slate-900 mb-2">
            Asset Onboarding
          </h1>
          <p class="text-base text-slate-500">
            Register your asset in our system
          </p>
        </div>
        
        <!-- Form Card -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
          <!-- Progress Bar -->
          <div class="mb-8">
            <div class="flex justify-between items-center mb-2">
              <span class="text-sm font-medium text-slate-500">Step {{ currentStep }} of {{ totalSteps }}</span>
              <span class="text-sm font-medium text-slate-500">{{ Math.round((currentStep / totalSteps) * 100) }}%</span>
            </div>
            <div class="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
              <div 
                class="bg-indigo-600 h-2 rounded-full transition-all duration-300"
                :style="{ width: `${(currentStep / totalSteps) * 100}%` }"
              ></div>
            </div>
          </div>
          
          <!-- Success Message -->
          <div v-if="submitSuccess" class="mb-8 p-4 bg-green-50 border border-green-200 rounded-xl">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-green-600 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              <div>
                <p class="text-sm font-semibold text-slate-900">Asset registered successfully!</p>
                <p class="text-sm text-slate-500 mt-0.5">Your asset has been added to the system.</p>
              </div>
            </div>
          </div>
          
          <!-- Error Message -->
          <div v-if="submitError" class="mb-8 p-4 bg-red-50 border border-red-200 rounded-xl">
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
            <div v-if="currentStep === 1" class="space-y-6">
              <div class="mb-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-1">Basic Information</h2>
                <p class="text-sm text-slate-500">Provide essential asset details</p>
              </div>
              
              <!-- Asset Name with Floating Label -->
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
              
              <!-- Description with Floating Label -->
              <div class="relative">
                <div class="relative">
                  <textarea
                    v-model="formData.description"
                    @focus="handleFocus('description')"
                    @blur="handleBlur('description')"
                    rows="4"
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
              </div>
              
              <!-- Serial Number with Floating Label -->
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
            <div v-if="currentStep === 2" class="space-y-6">
              <div class="mb-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-1">Company & Location</h2>
                <p class="text-sm text-slate-500">Select organization and location</p>
              </div>
              
              <!-- Company Select with Floating Label -->
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
                <p v-if="!isLoadingCompanies && !companiesError && companies.length === 0" class="mt-2 text-sm text-amber-600">
                  No companies available. Please contact an administrator.
                </p>
              </div>
              
              <!-- Location Select with Floating Label -->
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
                <p v-if="errors.locationId" class="mt-2 text-sm text-red-600 flex items-center">
                  <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                  </svg>
                  {{ errors.locationId }}
                </p>
                <p v-if="formData.companyId && filteredLocations.length === 0" class="mt-2 text-sm text-slate-500">
                  No locations available for this company
                </p>
              </div>
            </div>
            
            <!-- Step 3: Bill Upload -->
            <div v-if="currentStep === 3" class="space-y-6">
              <div class="mb-6">
                <h2 class="text-xl font-semibold text-slate-900 mb-1">Bill Upload</h2>
                <p class="text-sm text-slate-500">Attach supporting documentation</p>
              </div>
              
              <div>
                <label class="block text-sm font-medium text-slate-500 mb-2">
                  Bill Document <span class="text-slate-400">(Optional)</span>
                </label>
                <div class="mt-1 flex justify-center px-8 pt-12 pb-12 border-2 border-slate-300 border-dashed rounded-lg bg-slate-50 hover:border-indigo-400 hover:bg-indigo-50/50 transition-all duration-200 cursor-pointer group">
                  <div class="space-y-4 text-center">
                    <div class="inline-flex items-center justify-center w-12 h-12 bg-slate-100 rounded-lg group-hover:bg-indigo-100 transition-colors">
                      <svg class="h-6 w-6 text-slate-400 group-hover:text-indigo-600 transition-colors" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                        <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                      </svg>
                    </div>
                    <div class="flex items-center justify-center text-sm text-slate-600">
                      <label class="relative cursor-pointer font-medium text-indigo-600 hover:text-indigo-700 transition-colors">
                        <span>Upload a file</span>
                        <input
                          ref="fileInput"
                          type="file"
                          class="sr-only"
                          accept=".pdf,.jpg,.jpeg,.png,.webp"
                          @change="handleFileSelect"
                        />
                      </label>
                      <span class="mx-2 text-slate-400">or</span>
                      <span class="text-slate-500">drag and drop</span>
                    </div>
                    <p class="text-xs text-slate-500">PDF, PNG, JPG, WEBP up to 50MB</p>
                    <div v-if="selectedFileName" class="mt-4 inline-flex items-center px-4 py-2 bg-indigo-50 border border-indigo-200 rounded-lg">
                      <svg class="w-4 h-4 mr-2 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                      </svg>
                      <span class="text-sm text-slate-900 font-medium">{{ selectedFileName }}</span>
                    </div>
                  </div>
                </div>
                <p v-if="errors.billFile" class="mt-2 text-sm text-red-600 flex items-center">
                  <svg class="w-4 h-4 mr-1.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                  </svg>
                  {{ errors.billFile }}
                </p>
              </div>
              
              <!-- Upload Progress -->
              <div v-if="isSubmitting && uploadProgress > 0" class="mt-6">
                <div class="flex justify-between items-center mb-2">
                  <span class="text-sm font-medium text-slate-900">Uploading...</span>
                  <span class="text-sm text-slate-500">{{ uploadProgress }}%</span>
                </div>
                <div class="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div 
                    class="bg-indigo-600 h-2 rounded-full transition-all duration-300"
                    :style="{ width: `${uploadProgress}%` }"
                  ></div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Navigation Buttons -->
          <div class="flex justify-between mt-8 pt-8 border-t border-slate-200">
            <button
              v-if="currentStep > 1"
              @click="prevStep"
              :disabled="isSubmitting"
              class="inline-flex items-center px-6 py-3 text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 font-medium text-sm"
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
              class="inline-flex items-center px-6 py-3 text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 font-medium text-sm shadow-sm hover:shadow-md"
            >
              <span v-if="isSubmitting" class="flex items-center">
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Submitting...
              </span>
              <span v-else-if="currentStep === totalSteps" class="flex items-center">
                Submit
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
        </div>
      </div>
    </div>
  </div>
</template>
