<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { gsap } from 'gsap'
import { login } from '../lib/api'

const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const isLoading = ref(false)
const error = ref('')

const card = ref<HTMLElement | null>(null)

function applySessionNotice() {
  if (route.query.reason === 'session_invalid') {
    error.value = 'Your session could not be verified. Please sign in again.'
  }
}

watch(() => route.query.reason, applySessionNotice)

onMounted(() => {
  applySessionNotice()
  if (card.value) {
    gsap.fromTo(
      card.value,
      { opacity: 0, y: 16 },
      { opacity: 1, y: 0, duration: 0.45, ease: 'power3.out' }
    )
  }
})

async function handleSubmit() {
  error.value = ''
  isLoading.value = true
  try {
    await login(email.value, password.value)
    router.push('/admin')
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Login failed'
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex flex-col">
    <header class="border-b border-seam bg-panel">
      <div class="max-w-6xl mx-auto px-5 sm:px-8 py-4 flex items-center justify-between">
        <a href="/onboarding" class="flex items-center gap-3">
          <span class="font-plate text-lg text-paper tracking-wide">AR-9</span>
          <span class="hidden sm:block h-4 w-px bg-seamlight"></span>
          <span class="hidden sm:block silk-label">Asset Register</span>
        </a>
        <div class="flex items-center gap-2">
          <span class="led led-red led-blink"></span>
          <span class="silk-label">Admin console</span>
        </div>
      </div>
    </header>

    <main class="flex-1 flex items-center justify-center px-5 py-12">
      <div ref="card" class="w-full max-w-sm">
        <div class="panel-module overflow-hidden">
          <div class="module-head">
            <h1 class="silk-label-bright">Operator sign-in</h1>
            <span class="silk-label text-silkfaint">SYS·AUTH</span>
          </div>

          <form class="p-5 sm:p-6 space-y-5" @submit.prevent="handleSubmit">
            <div
              v-if="error"
              role="alert"
              class="panel-well flex items-start gap-2.5 px-3.5 py-3"
            >
              <span class="led led-red led-blink mt-1 shrink-0"></span>
              <p class="text-[13px] leading-snug text-stepred">{{ error }}</p>
            </div>

            <div>
              <label for="login-email" class="silk-label block mb-1.5">Email or username</label>
              <input
                id="login-email"
                v-model="email"
                type="text"
                autocomplete="username"
                required
                :disabled="isLoading"
                class="panel-input"
                placeholder="admin or admin@example.com"
              />
            </div>

            <div>
              <label for="login-password" class="silk-label block mb-1.5">Password</label>
              <div class="relative">
                <input
                  id="login-password"
                  v-model="password"
                  :type="showPassword ? 'text' : 'password'"
                  autocomplete="current-password"
                  required
                  :disabled="isLoading"
                  class="panel-input pr-11"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  tabindex="-1"
                  class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-silkfaint hover:text-silk transition-colors"
                  :aria-label="showPassword ? 'Hide password' : 'Show password'"
                  @click="showPassword = !showPassword"
                >
                  <svg v-if="!showPassword" class="w-4.5 h-4.5" width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  <svg v-else class="w-4.5 h-4.5" width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
                  </svg>
                </button>
              </div>
            </div>

            <button type="submit" :disabled="isLoading" class="panel-btn-primary w-full py-3">
              <svg v-if="isLoading" class="w-3.5 h-3.5 animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.25" />
                <path d="M12 2a10 10 0 019.95 9" stroke="currentColor" stroke-width="3" stroke-linecap="round" />
              </svg>
              {{ isLoading ? 'Signing in' : 'Sign in' }}
            </button>
          </form>

          <div class="border-t border-seam px-5 py-3 flex items-center justify-between">
            <span class="silk-label text-silkfaint">Qugen Pathlabs group</span>
            <a href="/onboarding" class="silk-label text-silk hover:text-paper transition-colors">← Register an asset</a>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
