import { createApp } from 'vue'
import '@fontsource/michroma'
import '@fontsource/anton'
import '@fontsource-variable/spline-sans-mono'
import './style.css'
import App from './App.vue'
import router from './router'

createApp(App).use(router).mount('#app')
