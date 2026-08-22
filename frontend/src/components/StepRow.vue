<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { inr } from '../lib/useRegister'

// The year as a sixteen-step row, cut to twelve: JAN–DEC as step keys,
// quartered Q1 red / Q2 orange / Q3 yellow / Q4 white like the four banks
// of a rhythm machine. A key is lit when its month wrote assets into the
// register; the chase light marks "now". Pressing a key filters the register
// to that month.
const props = defineProps<{
  months: Array<{ label: string; count: number; spend: number }>
  selected: number | null
  year: number
}>()

const emit = defineEmits<{ (e: 'select', index: number | null): void }>()

const QUARTER_KEY = ['key-red', 'key-orange', 'key-yellow', 'key-white']

const nowMonth = new Date().getMonth()
const isCurrentYear = props.year === new Date().getFullYear()

// chase light: a faint highlight sweeping the row on a slow clock
const chase = ref(-1)
let timer: ReturnType<typeof setInterval> | null = null
const reduced = typeof window !== 'undefined'
  && window.matchMedia('(prefers-reduced-motion: reduce)').matches

onMounted(() => {
  if (reduced) return
  timer = setInterval(() => {
    chase.value = (chase.value + 1) % 12
  }, 620)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})

function press(i: number) {
  emit('select', props.selected === i ? null : i)
}
</script>

<template>
  <div>
    <div class="grid grid-cols-6 sm:grid-cols-12 gap-1.5 sm:gap-2">
      <div v-for="(m, i) in months" :key="m.label" class="flex flex-col items-center gap-1.5">
        <span
          class="font-mono text-[10px] tracking-silk"
          :class="[
            selected === i ? 'text-stepred font-semibold'
              : isCurrentYear && i === nowMonth ? 'text-paper'
              : 'text-silkfaint',
          ]"
        >{{ m.label }}</span>
        <button
          type="button"
          class="step-key w-full h-14 sm:h-16"
          :class="[
            QUARTER_KEY[Math.floor(i / 3)],
            m.count === 0 ? 'key-unlit' : '',
            chase === i ? 'ring-1 ring-stepred/60' : '',
            selected === i ? 'ring-2 ring-stepred' : '',
          ]"
          :aria-pressed="selected === i"
          :title="m.count === 0
            ? `${m.label} ${year} — no assets registered`
            : `${m.label} ${year} — ${m.count} asset${m.count === 1 ? '' : 's'}, ${inr(m.spend)}`"
          @click="press(i)"
        >
          <span
            class="key-window"
            :class="{
              'key-window-lit': m.count > 0,
              'led-blink': isCurrentYear && i === nowMonth,
            }"
          ></span>
          <span
            class="absolute bottom-1.5 left-1/2 -translate-x-1/2 font-mono text-[10px] font-semibold"
            :class="Math.floor(i / 3) === 3 ? 'text-black/60' : 'text-black/70'"
          >{{ m.count > 0 ? m.count : '·' }}</span>
        </button>
      </div>
    </div>
    <div class="mt-2 hidden sm:grid sm:grid-cols-4 gap-2">
      <div
        v-for="q in ['Q1', 'Q2', 'Q3', 'Q4']"
        :key="q"
        class="flex items-center gap-2"
      >
        <span class="h-px flex-1 bg-seam"></span>
        <span class="silk-label">{{ q }}</span>
        <span class="h-px flex-1 bg-seam"></span>
      </div>
    </div>
  </div>
</template>
