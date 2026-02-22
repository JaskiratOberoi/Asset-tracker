import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../lib/supabase'
import OnboardingView from '../views/OnboardingView.vue'
import LoginView from '../views/LoginView.vue'
import AdminDashboardView from '../views/AdminDashboardView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/onboarding'
    },
    {
      path: '/onboarding',
      name: 'onboarding',
      component: OnboardingView
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { requiresGuest: true }
    },
    {
      path: '/admin',
      name: 'admin',
      component: AdminDashboardView,
      meta: { requiresAuth: true }
    }
  ]
})

// Navigation guard for protected routes
router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  if (to.meta.requiresAuth && !session) {
    next('/login')
  } else if (to.meta.requiresGuest && session) {
    // Check if user is admin
    const { data: adminCheck } = await supabase
      .from('admin_users')
      .select('user_id')
      .eq('user_id', session.user.id)
      .single()

    if (adminCheck) {
      next('/admin')
    } else {
      next()
    }
  } else {
    next()
  }
})

export default router
