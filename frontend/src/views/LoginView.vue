<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login } from '../lib/api'
import { gsap } from 'gsap'

const router = useRouter()
const route = useRoute()
const email = ref('')
const password = ref('')
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
      <div class="max-w-7xl mx-auto px-8 py-6">
        <h1 class="text-2xl font-semibold text-slate-900">Asset Tracker</h1>
        <p class="text-sm text-slate-500 mt-1">Admin console</p>
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
              <input
                id="password"
                v-model="password"
                type="password"
                required
                autocomplete="current-password"
                class="w-full px-4 py-3 bg-white border border-slate-300 rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition"
                placeholder="Enter your password"
                :disabled="isLoading"
              />
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
