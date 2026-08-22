---
name: AR-9 · Computer Controlled Asset Register
description: An asset register styled as an early-80s rhythm machine faceplate — matte charcoal modules, step-key quartet, LED readouts.
colors:
  chassis: "#0e0e10"
  panel: "#131316"
  module: "#1a1a1e"
  well: "#0a0a0c"
  seam: "#26262c"
  seam-light: "#33333b"
  silk: "#bdbdbd"
  silk-dim: "#8a8a92"
  silk-faint: "#85858e"
  paper: "#f2f2f2"
  step-red: "#ff3b30"
  step-orange: "#ff9a00"
  step-yellow: "#ffe100"
  step-white: "#f2f2f2"
  led-green: "#3ddc68"
  led-amber: "#ffb020"
typography:
  display:
    fontFamily: "Anton, 'Arial Narrow', sans-serif"
    fontSize: "1.5rem–3.75rem (text-2xl to text-6xl, by moment)"
    fontWeight: 400
    lineHeight: 1
    letterSpacing: "normal"
  plate:
    fontFamily: "Michroma, 'Spline Sans Mono', sans-serif"
    fontSize: "1.125rem"
    fontWeight: 400
    letterSpacing: "0.025em"
  body:
    fontFamily: "'Spline Sans Mono Variable', 'Spline Sans Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "13px–14px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "'Spline Sans Mono Variable', 'Spline Sans Mono', ui-monospace, monospace"
    fontSize: "10px"
    fontWeight: 500
    letterSpacing: "0.14em"
rounded:
  led: "2px"
  key: "4px"
  well: "4px"
  module: "6px"
spacing:
  meter-gap: "3px"
  key-gap: "6px"
  module-pad: "16px"
  bento-gap: "16px"
  btn-pad: "10px 18px"
components:
  button-primary:
    backgroundColor: "{colors.step-red}"
    textColor: "#000000"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    padding: "{spacing.btn-pad}"
  button-primary-hover:
    backgroundColor: "#ff554b"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.silk}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    padding: "{spacing.btn-pad}"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.silk-dim}"
    typography: "{typography.label}"
    rounded: "{rounded.key}"
    padding: "{spacing.btn-pad}"
  input:
    backgroundColor: "{colors.well}"
    textColor: "{colors.paper}"
    rounded: "{rounded.key}"
    padding: "10px 12px"
  module:
    backgroundColor: "{colors.module}"
    rounded: "{rounded.module}"
    padding: "{spacing.module-pad}"
---

# Design System: AR-9 · Computer Controlled Asset Register

## Overview

**Creative North Star: "The Rhythm Machine Register"**

Every surface is the faceplate of an early-80s rhythm machine. Records are steps you arm, acknowledgement is a lit LED, the year is a twelve-key step row, and totals read off 7-segment LED windows. The world is a single matte charcoal instrument: raised modules on a panel, recessed display wells, physical keycaps, silkscreened caps labels. It explicitly refuses the white-card SaaS dashboard with an indigo accent.

Density is instrument-grade: small mono type, tight silkscreen labels, hairline seams between modules, tabular numerals everywhere numbers appear. Color is scarce and semantic — the step-key quartet (red / orange / yellow / white) and two status LEDs (green / amber) are the only chroma on an otherwise near-black panel. Light is the interface's voice: the only glow anywhere comes from lit LEDs, lit segments, and key windows.

Mode is Operate on all three surfaces (login, onboarding, admin console). The product identity is the AR-9 model plate (Michroma), owned by the Qugen Pathlabs group.

**Key Characteristics:**
- Matte charcoal hardware panel with brushed-plastic grain on the chassis
- Step-key quartet accents cycled Q1→Q4 (red, orange, yellow, white)
- LED glow as the only glow; red 7-segment readouts, amber only for pending
- Silkscreen-gray mono caps labels (10px, 0.14em) as the labeling voice
- Physicality via raised modules, recessed wells, and pressable keycaps — never floating cards

## Colors

A near-monochrome charcoal chassis lit by four step-key hues and two status LEDs; chroma is always semantic, never decorative.

### Primary
- **Step Red** (#ff3b30): the machine's voice. Primary buttons, default 7-segment readouts, focus outlines, text caret, selection background, chase-light ring, error text, red LEDs. The single interactive accent.

### Secondary
- **Step Orange** (#ff9a00): Q2 bank keycaps and the second chart-series color. Never a UI control color.
- **Step Yellow** (#ffe100): Q3 bank keycaps and the third chart-series color.
- **Step White** (#f2f2f2): Q4 bank keycaps and the fourth chart-series color (same hex as Paper; distinct role).

### Tertiary
- **LED Amber** (#ffb020): the pending vocabulary — blinking amber LED and the amber-colored pending readout. Appears nowhere else.
- **LED Green** (#3ddc68): the acknowledged/healthy vocabulary — steady green LED. Appears nowhere else.

### Neutral
- **Chassis** (#0e0e10): page ground behind the panel, with fine SVG-noise grain and a faint top radial sheen.
- **Panel** (#131316): main panel surface — sticky header, scrollbar tracks.
- **Module** (#1a1a1e): raised module (bento cell) surface.
- **Well** (#0a0a0c): recessed wells — inputs and segment-display windows.
- **Seam** (#26262c): hairline module borders and rules; **Seam Light** (#33333b) for hover/active hairlines and scrollbar thumbs.
- **Silk** (#bdbdbd): bright silkscreen labels; **Silk Dim** (#8a8a92): secondary labels, placeholders, captions; **Silk Faint** (#85858e): tertiary silkscreen floor.
- **Paper** (#f2f2f2): brightest text — values, names, plate text.

### Named Rules
**The One Glow Rule.** Glow (box-shadow bloom or SVG drop-shadow) appears only on lit LEDs, lit 7-segment content, lit key windows, and the chase light. Text, borders, buttons, and cards never glow.

**The Amber Pending Rule.** Pending = amber LED blinking + amber readout. Acknowledged = green LED steady. Every other readout is red. Amber and green never appear outside status.

**The Silkscreen Floor Rule.** Tertiary silkscreen text never drops below #85858e — that value holds 4.5:1 on module surfaces.

**The Hue-Preserved Unlit Rule.** Unlit step keys use dedicated low-lightness variants of their own hue (#63201b / #63400a / #5d520c / #595955) — never `brightness()` or `saturate()` filters, which muddy the hue.

## Typography

**Display Font:** Anton (with Arial Narrow fallback)
**Plate Font:** Michroma (with Spline Sans Mono fallback)
**Body Font:** Spline Sans Mono Variable (ui-monospace stack fallback)

All three are self-hosted via Fontsource (`@fontsource/michroma`, `@fontsource/anton`, `@fontsource-variable/spline-sans-mono`), imported in `main.ts`.

**Character:** an instrument's typography. Michroma is the machined model plate; Anton is the loud stenciled statement; Spline Sans Mono is everything the machine prints — labels, values, prose. There is no proportional body face anywhere.

### Hierarchy
- **Display** (Anton 400, text-2xl–text-6xl, leading-none, uppercase): statement moments only — onboarding headline, the "Asset registered" stamp, the admin timeline year. Operate restraint: it never labels chrome.
- **Plate** (Michroma 400, 18px header / 48px login hero, tracking-wide): the AR-9 model plate identity, nothing else.
- **Body** (Spline Sans Mono 400–500, 13–14px): table cells, prose, captions at 11px in Silk Dim.
- **Label** (Spline Sans Mono 500–600, 10px, 0.14em, uppercase): silkscreen labels — module heads, buttons, quarter markers, meta rows. Bright variant (600, Silk) for module titles; dim variant (500, Silk Dim) for everything else.

### Named Rules
**The Earned Anton Rule.** Anton appears only at moments of statement; on the admin console exactly one — the timeline year. If a heading can be a silkscreen label, it is one.

**The Tabular Instrument Rule.** Every numeric column and inline count uses `tabular-nums`; numbers read as instrument readouts.

## Layout

The admin console is a bento faceplate: a `max-w-7xl` centered column (px-5, sm:px-8) under a sticky panel header (border-b seam) holding the AR-9 plate, operator identity, and actions. Modules sit on a 12-column grid (`lg:grid-cols-12`, gap-4 / 16px) — first viewport is a readout row of four segment displays (value 4-col, count 3, pending 2, sites 3), then the 12-month step row full-width (the 12 keys need the full column to stay individually pressable; 6 columns on mobile), charts (7/5 split), then the register table. Login and onboarding center a single module on the chassis. Module interiors use a `module-head` title bar (px-4 py-2.5, border-b seam) over px-4 py-4 content. Rhythm is Tailwind's 4px scale, dominated by 16px module padding and gaps.

## Elevation & Depth

Depth is physical, not atmospheric: surfaces are millimetres of hardware, not floating layers. Raised modules get a hairline top-light inset plus a heavy soft drop; wells are pressed into the panel with inset shadows; keycaps carry a hard 2px undershadow and a top-light bevel that compresses on press. Nothing hovers, nothing lifts on hover, and glows belong exclusively to light sources (see The One Glow Rule).

### Shadow Vocabulary
- **module** (`0 1px 0 rgba(255,255,255,0.03) inset, 0 8px 24px rgba(0,0,0,0.35)`): every raised panel module.
- **well** (`inset 0 2px 6px rgba(0,0,0,0.7), inset 0 -1px 0 rgba(255,255,255,0.04)`): recessed inputs and segment windows.
- **key** (`0 2px 0 rgba(0,0,0,0.55), 0 4px 10px rgba(0,0,0,0.45), inset 0 1px 0 rgba(255,255,255,0.18)`): step keycaps at rest; **keydown** (shallower: `0 1px 0`, `0 2px 4px`, inset 0.12) with `translateY(1px)` on `:active`.
- **LED glows** (`0 0 6px 1px` at the LED's own hue, 0.6–0.7 alpha, plus a white inset pinprick): lit LEDs only.

### Named Rules
**The Faceplate Rule.** Elevation states physical construction (raised / recessed / pressable), never hierarchy or hover flair. Hover changes color or border, never shadow or position — the only positional response is the keycap's 1px press.

## Shapes

Machined-hardware corners: small radii everywhere, no pills, no sharp 0px edges. Modules round at 6px, keycaps / wells / buttons / inputs at 4px, LEDs and key windows at 2px (LEDs are square-ish lamps, not dots). Borders are constant hairlines — 1px seam around every module, 1px black around wells and keycaps. The recurring silhouettes: the bento module with its title bar, the tall keycap with a small lit window near its top, the right-aligned segment window, and the 8px square LED lamp. Segment digits skew −4° like real LED displays.

## Components

### Buttons
Flat panel switches in the RUN/CLEAR vocabulary — silkscreen type on a control, not a rounded web button.
- **Shape:** small machined corner (4px), 1px border, uppercase mono 11px/600/0.14em, padding 10px 18px.
- **Primary:** Step Red fill, black text, red border; hover lifts the fill to #ff554b (color only).
- **Secondary:** transparent fill, Silk text, Seam Light border; hover brightens to Paper text / Silk Faint border.
- **Ghost:** transparent, Silk Dim text, invisible border; hover brightens text to Paper.
- **Disabled:** 45% opacity, not-allowed cursor. **Focus:** global 2px Step Red outline, offset 2.

### Cards / Containers
- **Corner Style:** 6px.
- **Background:** Module (#1a1a1e) on the Panel/Chassis ground.
- **Shadow Strategy:** module shadow (raised faceplate cell; see Elevation).
- **Border:** 1px Seam hairline.
- **Internal Padding:** module-head px-4 py-2.5 with silk-label-bright title; content px-4 py-4.

### Inputs / Fields
- **Style:** recessed well — Well background, 1px Seam border, 4px radius, well inset shadow, mono 13px, Silk Dim placeholder, red caret.
- **Focus:** border turns Step Red plus a 1px red halo ring (`0 0 0 1px rgba(255,59,48,0.4)`) layered over the inset; no glow bloom.
- **Disabled:** 50% opacity.

### Navigation
Sticky faceplate header: Panel background, 1px Seam bottom border, AR-9 Michroma plate at left with a vertical Seam Light tick separating the silkscreen console label and operator email; primary + secondary panel buttons at right. No nav links, no active states — each surface is one screen of the instrument.

### Segment Display (signature)
SVG 7-segment readout inside a `seg-window` (a right-aligned well, padding 8px 12px). Unlit ghost segments stay faintly visible (7% opacity of the digit color) like real hardware; lit segments carry an SVG drop-shadow glow in their own color. Default color Step Red; the pending readout alone passes #ffb020. Cells left-pad with blanks (`minCells`) so displays hold stable width; digits skew −4°.

### Step Row (signature)
Twelve keycaps JAN–DEC, quartered Q1 red / Q2 orange / Q3 yellow / Q4 white, each with a key window that lights warm-white when its month holds assets and blinks on the current month. Unlit keys use the hue-preserved dim variants. A chase-light ring (1px Step Red at 60%) sweeps the row every 620ms; selecting a key sets a 2px red ring and filters the register. Quarter markers beneath are silk labels between hairlines.

### LEDs & Meters (signature)
The 8px LED lamp (2px radius) is the status vocabulary: dark #3a3a40 at rest, red/green/amber lit with glow; `led-blink` steps opacity at 1.1s. Company-share meters render 24 3px-gapped segments lit proportionally in the quartet hue. Chart.js output follows the panel: mono 10px type, quartet series colors at ~85% alpha (full on hover), Well-black tooltips with Seam Light borders, Silk Dim ticks, 2px bar radius, no legend.

## Do's and Don'ts

### Do:
- **Do** keep every glow attached to a light source — LEDs, lit segments, key windows, the chase light (The One Glow Rule).
- **Do** format currency as ₹ + en-IN grouping with zero decimals via `inr()`; segment displays get digits + en-IN separators only via `segDigits()` — never a ₹ glyph in LED cells.
- **Do** speak status in LED vocabulary: pending = amber blinking, acknowledged/healthy = green steady, readouts otherwise red.
- **Do** label with silkscreen caps (10px mono, 0.14em) and keep tertiary text at or above #85858e.
- **Do** draw icons as inline SVG in the Heroicons manner (1.5–2 stroke); size chart and meter color from the step-key quartet, cycled in order.
- **Do** keep motion state-conveying and short: 150–300ms GSAP entrances (power2/power3.out, opacity + ≤20px rise), the 620ms chase, the 1.1s LED blink — all collapsed under `prefers-reduced-motion`.
- **Do** group location data by name, not id — historical duplicate location rows share a name.

### Don't:
- **Don't** build white cards, light surfaces, or an indigo/blue accent — the refused SaaS dashboard is the anti-reference.
- **Don't** use Anton outside statement moments, or Michroma outside the AR-9 plate; no proportional or system display faces anywhere.
- **Don't** dim keys or accents with `brightness()`/`saturate()` filters — use the hue-preserved unlit variants.
- **Don't** add hover elevation, floating shadows, or glowing text/borders/buttons; hover changes color only, and only keycaps move (1px press).
- **Don't** use unicode glyphs or icon fonts as icons.
- **Don't** put amber or green anywhere except status LEDs and the pending readout.
