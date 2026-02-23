<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
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
})
</script>

<template>
  <div class="min-h-screen bg-slate-50">
    <!-- Header - matches AdminDashboardView -->
    <header class="bg-white border-b border-slate-200 shadow-sm">
      <div class="max-w-7xl mx-auto px-8 py-6">
        <h1 class="text-2xl font-semibold text-slate-900">Asset Tracker</h1>
        <p class="text-sm text-slate-500 mt-1">Admin console</p>
      </div>
    </header>

    <!-- Main Content -->
    <main class="max-w-7xl mx-auto px-8 py-12 flex items-center justify-center min-h-[calc(100vh-88px)]">
      <div ref="loginContainer" class="w-full max-w-md">
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
