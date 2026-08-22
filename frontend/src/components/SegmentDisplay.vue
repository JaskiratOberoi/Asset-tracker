<script setup lang="ts">
import { computed } from 'vue'

// A real 7-segment LED readout drawn in SVG: unlit ghost segments stay faintly
// visible (like actual hardware), lit segments glow. Accepts digits, en-IN
// group separators (,), decimal points and minus signs.
const props = withDefaults(defineProps<{
  value: string
  color?: string
  height?: number
  minCells?: number
}>(), {
  color: '#ff3b30',
  height: 34,
  minCells: 0,
})

const SEGS: Record<string, string> = {
  A: '10,4 46,4 52,10 46,16 10,16 4,10',
  B: '46,8 52,14 52,44 46,50 40,44 40,14',
  C: '46,50 52,56 52,86 46,92 40,86 40,56',
  D: '10,84 46,84 52,90 46,96 10,96 4,90',
  E: '10,50 16,56 16,86 10,92 4,86 4,56',
  F: '10,8 16,14 16,44 10,50 4,44 4,14',
  G: '10,44 46,44 52,50 46,56 10,56 4,50',
}

const DIGIT_MAP: Record<string, string[]> = {
  '0': ['A', 'B', 'C', 'D', 'E', 'F'],
  '1': ['B', 'C'],
  '2': ['A', 'B', 'G', 'E', 'D'],
  '3': ['A', 'B', 'G', 'C', 'D'],
  '4': ['F', 'G', 'B', 'C'],
  '5': ['A', 'F', 'G', 'C', 'D'],
  '6': ['A', 'F', 'G', 'E', 'D', 'C'],
  '7': ['A', 'B', 'C'],
  '8': ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
  '9': ['A', 'B', 'F', 'G', 'C', 'D'],
  '-': ['G'],
  ' ': [],
}

const DIGIT_W = 66
const SEP_W = 22

interface Cell {
  x: number
  kind: 'digit' | 'comma' | 'dot'
  lit: string[]
}

const layout = computed(() => {
  let chars = props.value.split('')
  // left-pad with blank cells so displays hold a stable width
  const digitCount = chars.filter(c => DIGIT_MAP[c] !== undefined).length
  if (props.minCells > digitCount) {
    chars = [...Array(props.minCells - digitCount).fill(' '), ...chars]
  }
  const cells: Cell[] = []
  let x = 0
  for (const ch of chars) {
    if (ch === ',') {
      cells.push({ x, kind: 'comma', lit: [] })
      x += SEP_W
    } else if (ch === '.') {
      cells.push({ x, kind: 'dot', lit: [] })
      x += SEP_W
    } else {
      cells.push({ x, kind: 'digit', lit: DIGIT_MAP[ch] ?? [] })
      x += DIGIT_W
    }
  }
  return { cells, width: Math.max(x - 10, 56) }
})

const filterId = `segglow-${Math.random().toString(36).slice(2, 8)}`
</script>

<template>
  <svg
    :viewBox="`0 0 ${layout.width} 100`"
    :style="{ height: height + 'px' }"
    class="block"
    aria-hidden="true"
    preserveAspectRatio="xMaxYMid meet"
  >
    <defs>
      <filter :id="filterId" x="-40%" y="-40%" width="180%" height="180%">
        <feDropShadow dx="0" dy="0" stdDeviation="3" :flood-color="color" flood-opacity="0.7" />
      </filter>
    </defs>
    <g transform="skewX(-4)">
      <template v-for="(cell, i) in layout.cells" :key="i">
        <!-- digit cell -->
        <g v-if="cell.kind === 'digit'" :transform="`translate(${cell.x},0)`">
          <polygon
            v-for="(pts, seg) in SEGS"
            :key="seg"
            :points="pts"
            :fill="color"
            :opacity="cell.lit.includes(String(seg)) ? 0 : 0.07"
          />
          <g :filter="`url(#${filterId})`">
            <polygon
              v-for="seg in cell.lit"
              :key="seg"
              :points="SEGS[seg]"
              :fill="color"
            />
          </g>
        </g>
        <!-- en-IN group separator: a small lit tail low in the cell -->
        <g v-else-if="cell.kind === 'comma'" :transform="`translate(${cell.x},0)`">
          <polygon points="4,84 14,84 12,100 2,100" :fill="color" :filter="`url(#${filterId})`" />
        </g>
        <!-- decimal point -->
        <g v-else :transform="`translate(${cell.x},0)`">
          <rect x="3" y="85" width="11" height="11" :fill="color" :filter="`url(#${filterId})`" />
        </g>
      </template>
    </g>
  </svg>
</template>
