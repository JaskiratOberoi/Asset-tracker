# Asset Tracker Frontend

Vue 3 + TypeScript + Vite frontend for the Asset Tracker application.

## Features

- **Vue 3** with Composition API and TypeScript
- **TailwindCSS** for styling with responsive design
- **Supabase Client** for backend integration
- **Zod** for form validation
- **GSAP** for smooth animations
- **Vue Router** for navigation

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your Supabase URL and anon key
```

3. Start development server:
```bash
npm run dev
```

The server will start on http://localhost:1200

## Project Structure

```
src/
├── lib/
│   └── supabase.ts      # Supabase client configuration
├── router/
│   └── index.ts         # Vue Router configuration
├── views/
│   └── OnboardingView.vue  # Main onboarding form
├── App.vue
├── main.ts
└── style.css
```

## Onboarding Form

The `/onboarding` route features:

- **Multi-step form** with 3 steps:
  1. Basic Information (name, description, serial number)
  2. Company & Location selection
  3. Bill document upload (optional)

- **Form Validation** using Zod:
  - Required field validation
  - File type and size validation
  - UUID validation for company/location IDs

- **GSAP Animations**:
  - Smooth transitions between form steps
  - Fade and slide animations

- **File Upload**:
  - Progress tracking
  - Secure upload to Supabase Storage
  - File type and size validation

- **Responsive Design**:
  - SVG pattern background
  - Mobile-friendly layout
  - TailwindCSS utility classes

## Environment Variables

- `VITE_SUPABASE_URL`: Your Supabase API URL (default: http://localhost:8000)
- `VITE_SUPABASE_ANON_KEY`: Your Supabase anonymous key

## Build

```bash
npm run build
```

## Preview

```bash
npm run preview
```
