# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Internal operations staff of a small Indian diagnostics group (companies in the register: "Qugen/Genomics", "Ares", "Others"). Two roles, same team:

- **Ops staff** use the public (unauthenticated) onboarding wizard to register newly purchased assets — name, cost in INR, serial number, owning company, site, and the purchase bill (PDF/image). Confirmed: the form is used by internal staff, not external clients; "public" is only technical.
- **Admins** sign in to the dashboard to review the register: acknowledge newly registered assets, edit/delete records, view bills, and read stats.

Sites are North-Indian cities (Delhi, Lucknow, Srinagar, Haldwani, Rohtak, Karnal, Agra, Bareilly, Rudrapur), all currently under Qugen/Genomics.

## Product Purpose

A company asset register: capture every purchased asset with its bill at the moment of purchase, and give admins one place to verify (acknowledge), value, and locate everything the group owns. Success = every asset registered with a bill, acknowledged promptly, and spend/distribution visible at a glance.

## Operating Context

- Desk work on desktop/laptop, occasional mobile entry. Currency is INR, `en-IN` formatting throughout.
- Workflow: purchase happens → ops registers the asset via the 3-step wizard (with bill upload, up to 50 MB PDF/PNG/JPG/WEBP) → asset lands "Pending" → admin acknowledges it (single or bulk) → register is the ongoing source of truth.
- Deployed as Docker containers (asset_tracker_api + Postgres + Mongo GridFS for bills), fronted at api-asset.stellarinfomatica.com; frontend built with Vite, API base URL injected at build time.

## Capabilities and Constraints

- Stack: Vue 3 + TypeScript + Vite + Tailwind 3 + GSAP + chart.js (vue-chartjs). No store; JWT in localStorage.
- Data model (must be fully retained): assets (name, serial_number [globally unique], company_id, location_id, bill file id, acknowledged_at, created_at, `details` JSONB holding `{description, cost}`), companies (name), locations (name, company_id; address fields exist in DB but are unused). No warranty, category, assignee, or purchase-date fields exist — lifecycle stats must derive from `created_at`; do not fabricate warranty data.
- API surface is fixed (Express): login/me, companies list, locations list + create, asset create (multipart)/list/patch/acknowledge/delete, bill upload/replace (`POST /api/assets/:id/bill`), bill delete, bill file streaming. Aggregate endpoints exist but client-side aggregation is fine.
- Location filtering and chart grouping deliberately key on location **name**, not id (historical duplicate-row bug); keep name-based grouping.
- Admin stats priorities (confirmed): (1) spend & value in INR, (2) lifecycle/timeline (from created_at; warranty only when data exists), (3) volume & distribution by company/location. Coverage/data-quality stats were explicitly not prioritized.
- Retain all current behavior: 3-step onboarding with zod validation and drag-drop bill upload, login, KPI cards, charts, searchable/filterable assets table with row detail + inline edit modal, acknowledge (single + bulk), delete with confirm, View Bill via authenticated blob.

## Brand Commitments

- No incumbent brand. Confirmed: invent a proper product identity (name + wordmark) as part of the overhaul; user approves it in the result.
- User-pinned aesthetic direction (binding): **editorial, informative, denser and more useful than the current barebones look; bento-grid-style stat compositions; purposeful animation; radical color-scheme change is explicitly allowed.**

## Evidence on Hand

- Real seed data: 3 companies, 9 locations, mock assets. Real bills exist only in the deployed prod database, not in the repo.
- No testimonials, pricing, or marketing claims exist — internal tool; none may be invented.

## Product Principles

1. The register is the product: density, scanability, and trust in the numbers outrank decoration.
2. Every number is real and INR-formatted; derived stats must be derivable from actual fields, never invented.
3. Entry must stay fast: the wizard serves repeat internal data entry, not first-time visitors.
4. One component vocabulary across dashboard and wizard; the two surfaces are one product.
5. Ship on the existing API; prefer surfacing implemented-but-unused endpoints (bill replace/delete, inline location add) over inventing new backend.
