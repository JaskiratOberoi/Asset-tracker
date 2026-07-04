<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login } from '../lib/api'
import { gsap } from 'gsap'

const router = useRouter()
const route = useRoute()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const error = ref<string | null>(null)
const isLoading = ref(false)
const loginContainer = ref<HTMLElement | null>(null)
const bgLayer = ref<HTMLElement | null>(null)

// Mouse position for interactive background (normalized -1 to 1)
const mouse = ref({ x: 0, y: 0 })
const targetMouse = ref({ x: 0, y: 0 })

const onMouseMove = (e: MouseEvent) => {
  const w = window.innerWidth
  const h = window.innerHeight
  targetMouse.value.x = (e.clientX / w) * 2 - 1
  targetMouse.value.y = (e.clientY / h) * 2 - 1
}

let rafId = 0
const lerp = (a: number, b: number, t: number) => a + (b - a) * t
const animateMouse = () => {
  mouse.value.x = lerp(mouse.value.x, targetMouse.value.x, 0.08)
  mouse.value.y = lerp(mouse.value.y, targetMouse.value.y, 0.08)
  rafId = requestAnimationFrame(animateMouse)
}

// Show message when redirected back from admin (e.g. session could not be verified)
watch(
  () => route.query.reason,
  (reason) => {
    if (reason === 'session_invalid') {
      error.value = 'Your session could not be verified. Please sign in again.'
    }
  },
  { immediate: true }
)

const handleLogin = async () => {
  error.value = null
  isLoading.value = true

  try {
    await login(email.value, password.value)
    router.push('/admin')
  } catch (err: unknown) {
    const message = (err instanceof Error ? err.message : null) || 'Login failed. Please check your credentials.'
    error.value = message
    console.error('Login error:', err)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  if (loginContainer.value) {
    gsap.from(loginContainer.value, {
      opacity: 0,
      y: 20,
      duration: 0.4,
      ease: 'power2.out'
    })
  }
  // Floating animation for background orbs
  const blobEls = bgLayer.value?.querySelectorAll('[data-blob]')
  blobEls?.forEach((el, i) => {
    const sign = i % 2 === 0 ? 1 : -1
    gsap.to(el, {
      x: `+=${80 * sign}`,
      y: `+=${40 * sign}`,
      duration: 8 + i * 2,
      repeat: -1,
      yoyo: true,
      ease: 'sine.inOut'
    })
  })
  rafId = requestAnimationFrame(animateMouse)
  window.addEventListener('mousemove', onMouseMove)
})

onUnmounted(() => {
  cancelAnimationFrame(rafId)
  window.removeEventListener('mousemove', onMouseMove)
})
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <!-- Header - matches AdminDashboardView -->
    <header class="relative z-20 bg-white border-b border-slate-200 shadow-sm">
      <div class="max-w-7xl mx-auto px-6 lg:px-8 py-4">
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center shadow-sm shrink-0">
            <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24">
              <path d="M11.25 3.03a.75.75 0 01.75 0l8.25 4.76a.75.75 0 010 1.3L12 13.85 3.75 9.09a.75.75 0 010-1.3l7.5-4.76z" opacity=".9"/>
              <path d="M3 11.38l8.25 4.77v5.32L3.38 16.9A.75.75 0 013 16.25v-4.87zM21 11.38v4.87a.75.75 0 01-.38.65l-7.87 4.57v-5.32L21 11.38z"/>
            </svg>
          </div>
          <div>
            <h1 class="text-xl font-semibold text-slate-900">Asset Tracker</h1>
            <p class="text-sm text-slate-500">Admin console</p>
          </div>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="relative min-h-[calc(100vh-88px)] flex items-center justify-center overflow-hidden">
      <!-- Interactive background -->
      <div ref="bgLayer" class="absolute inset-0 pointer-events-none">
        <div class="absolute inset-0 bg-gradient-to-br from-slate-50 via-indigo-50/40 to-slate-100" />
        <!-- Subtle grid -->
        <div
          class="absolute inset-0 opacity-[0.4]"
          style="background-image: linear-gradient(rgba(148,163,184,0.15) 1px, transparent 1px), linear-gradient(90deg, rgba(148,163,184,0.15) 1px, transparent 1px); background-size: 48px 48px;"
        />
        <!-- Floating orbs with mouse parallax -->
        <div
          class="absolute top-1/4 left-1/4 w-[320px] h-[320px] rounded-full"
          :style="{ transform: `translate(${mouse.x * 24}px, ${mouse.y * 24}px)` }"
        >
          <div
            data-blob
            class="absolute inset-0 rounded-full bg-indigo-300/50 blur-3xl"
          />
        </div>
        <div
          class="absolute top-1/2 right-1/5 w-[280px] h-[280px] rounded-full"
          :style="{ transform: `translate(${mouse.x * -20}px, ${mouse.y * 20}px)` }"
        >
          <div
            data-blob
            class="absolute inset-0 rounded-full bg-violet-300/40 blur-3xl"
          />
        </div>
        <div
          class="absolute bottom-1/4 left-1/3 w-[240px] h-[240px] rounded-full"
          :style="{ transform: `translate(${mouse.x * 16}px, ${mouse.y * -16}px)` }"
        >
          <div
            data-blob
            class="absolute inset-0 rounded-full bg-slate-300/35 blur-3xl"
          />
        </div>
        <div
          class="absolute top-1/3 right-1/3 w-[200px] h-[200px] rounded-full"
          :style="{ transform: `translate(${mouse.x * -12}px, ${mouse.y * -12}px)` }"
        >
          <div
            data-blob
            class="absolute inset-0 rounded-full bg-indigo-200/30 blur-2xl"
          />
        </div>
        <div
          class="absolute bottom-1/3 right-1/2 w-[180px] h-[180px] rounded-full"
          :style="{ transform: `translate(${mouse.x * 10}px, ${mouse.y * 10}px)` }"
        >
          <div
            data-blob
            class="absolute inset-0 rounded-full bg-violet-200/25 blur-2xl"
          />
        </div>
      </div>

      <div ref="loginContainer" class="relative z-10 w-full max-w-md mx-auto px-8 py-12">
        <!-- Card - same style as admin dashboard bento cards -->
        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-8">
          <div class="mb-8">
            <h2 class="text-xl font-semibold text-slate-900 mb-1">Sign in</h2>
            <p class="text-sm text-slate-500">Sign in to access the admin panel</p>
          </div>

          <!-- Error Message -->
          <div
            v-if="error"
            role="alert"
            class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg"
          >
            <p class="text-sm font-medium text-red-800">{{ error }}</p>
          </div>

          <!-- Login Form -->
          <form @submit.prevent="handleLogin" class="space-y-6">
            <div>
              <label for="email" class="block text-sm font-medium text-slate-700 mb-2">
                Email or username
              </label>
              <input
                id="email"
                v-model="email"
                type="text"
                required
                autocomplete="username"
                class="w-full px-4 py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                placeholder="admin or admin@example.com"
                :disabled="isLoading"
              />
            </div>

            <div>
              <label for="password" class="block text-sm font-medium text-slate-700 mb-2">
                Password
              </label>
              <div class="relative">
                <input
                  id="password"
                  v-model="password"
                  :type="showPassword ? 'text' : 'password'"
                  required
                  autocomplete="current-password"
                  class="w-full px-4 py-3 pr-12 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                  placeholder="Enter your password"
                  :disabled="isLoading"
                />
                <button
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
                  :aria-label="showPassword ? 'Hide password' : 'Show password'"
                  tabindex="-1"
                >
                  <svg v-if="showPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                  <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </button>
              </div>
            </div>

            <button
              type="submit"
              :disabled="isLoading"
              class="w-full py-3 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              <span v-if="isLoading">Signing in...</span>
              <span v-else>Sign in</span>
            </button>
          </form>
        </div>
      </div>
    </main>
  </div>
</template>
