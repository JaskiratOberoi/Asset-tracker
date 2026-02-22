<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { gsap } from 'gsap'
import { onMounted } from 'vue'

const router = useRouter()
const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const isLoading = ref(false)
const loginContainer = ref<HTMLElement | null>(null)

const handleLogin = async () => {
  error.value = null
  isLoading.value = true

  try {
    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (authError) throw authError

    // Check if user is admin
    const { data: adminCheck, error: adminError } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', data.user?.id)
      .single()

    if (adminError || !adminCheck) {
      await supabase.auth.signOut()
      throw new Error('Access denied. Admin privileges required.')
    }

    router.push('/admin')
  } catch (err: any) {
    error.value = err.message || 'Login failed. Please check your credentials.'
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  if (loginContainer.value) {
    gsap.from(loginContainer.value, {
      opacity: 0,
      y: 30,
      duration: 0.6,
      ease: 'power2.out'
    })
  }
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 relative overflow-hidden">
    <!-- Animated Pattern Background -->
    <div class="absolute inset-0 opacity-20">
      <svg class="w-full h-full" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern id="dots" width="60" height="60" patternUnits="userSpaceOnUse">
            <circle cx="30" cy="30" r="2" fill="currentColor" class="text-white">
              <animate attributeName="opacity" values="0.3;1;0.3" dur="3s" repeatCount="indefinite" />
            </circle>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#dots)" />
      </svg>
    </div>

    <!-- Content -->
    <div class="relative z-10 flex items-center justify-center min-h-screen p-4">
      <div ref="loginContainer" class="w-full max-w-md">
        <div class="bg-white/10 backdrop-blur-lg rounded-2xl shadow-2xl p-8 border border-white/20">
          <!-- Header -->
          <div class="text-center mb-8">
            <h1 class="text-4xl font-bold text-white mb-2">Admin Dashboard</h1>
            <p class="text-gray-300">Sign in to access the admin panel</p>
          </div>

          <!-- Error Message -->
          <div v-if="error" class="mb-6 p-4 bg-red-500/20 border border-red-500/50 rounded-lg">
            <p class="text-red-200 text-sm">{{ error }}</p>
          </div>

          <!-- Login Form -->
          <form @submit.prevent="handleLogin" class="space-y-6">
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">
                Email
              </label>
              <input
                v-model="email"
                type="email"
                required
                class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition"
                placeholder="admin@example.com"
                :disabled="isLoading"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">
                Password
              </label>
              <input
                v-model="password"
                type="password"
                required
                class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition"
                placeholder="Enter your password"
                :disabled="isLoading"
              />
            </div>

            <button
              type="submit"
              :disabled="isLoading"
              class="w-full py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white font-semibold rounded-lg hover:from-purple-700 hover:to-indigo-700 focus:outline-none focus:ring-2 focus:ring-purple-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 transform hover:scale-[1.02]"
            >
              <span v-if="isLoading">Signing in...</span>
              <span v-else>Sign In</span>
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
