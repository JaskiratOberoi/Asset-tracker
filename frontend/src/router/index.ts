import { createRouter, createWebHistory } from 'vue-router'
import { getSession, getMe } from '../lib/api'
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

router.beforeEach(async (to, _from, next) => {
  const session = getSession()
  const hasToken = !!session

  if (to.meta.requiresAuth && !hasToken) {
    next('/login')
  } else if (to.meta.requiresGuest && hasToken) {
    try {
      const me = await getMe()
      if (me?.user) next('/admin')
      else next()
    } catch {
      next()
    }
  } else {
    next()
  }
})

export default router
