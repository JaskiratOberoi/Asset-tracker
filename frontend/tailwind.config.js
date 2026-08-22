/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // AR-9 panel world
        chassis: '#0e0e10',      // page ground behind the panel
        panel: '#131316',        // main panel surface
        module: '#1a1a1e',       // raised module surface
        well: '#0a0a0c',         // recessed wells (inputs, display windows)
        seam: '#26262c',         // hairline module borders
        seamlight: '#33333b',    // hover/active hairlines
        silk: '#bdbdbd',         // silkscreen label gray
        silkdim: '#8a8a92',      // secondary silkscreen
        silkfaint: '#5c5c64',    // tertiary / disabled silkscreen
        paper: '#f2f2f2',        // brightest text (step white)
        stepred: '#ff3b30',
        steporange: '#ff9a00',
        stepyellow: '#ffe100',
        stepwhite: '#f2f2f2',
        ledgreen: '#3ddc68',
        ledamber: '#ffb020',
      },
      fontFamily: {
        mono: ['"Spline Sans Mono"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
        plate: ['Michroma', '"Spline Sans Mono"', 'sans-serif'],
        display: ['Anton', '"Arial Narrow"', 'sans-serif'],
      },
      boxShadow: {
        key: '0 2px 0 rgba(0,0,0,0.55), 0 4px 10px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.18)',
        keydown: '0 1px 0 rgba(0,0,0,0.55), 0 2px 4px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.12)',
        module: '0 1px 0 rgba(255,255,255,0.03) inset, 0 8px 24px rgba(0,0,0,0.35)',
        well: 'inset 0 2px 6px rgba(0,0,0,0.7), inset 0 -1px 0 rgba(255,255,255,0.04)',
      },
      letterSpacing: {
        silk: '0.14em',
        wide2: '0.22em',
      },
    },
  },
  plugins: [],
}
