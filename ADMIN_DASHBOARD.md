# Admin Dashboard Documentation

## Overview

The admin dashboard provides secure access to asset management with authentication, data visualization, and bill viewing capabilities.

## Features

### 🔐 Authentication
- **Login Page**: Secure authentication via Supabase
- **Admin Verification**: Checks user against `admin_users` table
- **Protected Routes**: Automatic redirect to login if not authenticated
- **Session Management**: Persistent login sessions

### 📊 Data Visualization
- **Bar Chart**: Asset distribution across companies
- **Doughnut Chart**: Percentage breakdown by company
- **Real-time Data**: Fetches latest data from Supabase
- **Responsive Charts**: Adapts to screen size

### 📋 Assets Management
- **Data Table**: Complete list of all assets
- **Company & Location**: Shows associated company and location
- **Serial Numbers**: Displays serial numbers (if available)
- **View Bill Links**: Secure signed URLs for bill documents
- **Sortable Columns**: Easy data navigation

### 🎨 UI/UX
- **Fluid Animations**: GSAP-powered smooth transitions
- **Patterned Backgrounds**: SVG patterns for visual appeal
- **Glass Morphism**: Modern backdrop blur effects
- **Responsive Design**: Works on all screen sizes

## Routes

- `/login` - Login page (public)
- `/admin` - Admin dashboard (protected)
- `/onboarding` - Public asset onboarding form

## Authentication Flow

1. User visits `/admin` → Redirected to `/login` if not authenticated
2. User enters credentials → Supabase authenticates
3. System checks `admin_users` table → Verifies admin status
4. If admin → Access granted to dashboard
5. If not admin → Access denied, redirected to login

## Components

### LoginView.vue
- Email/password authentication
- Admin verification
- Error handling
- Animated entrance

### AdminDashboardView.vue
- Protected layout
- Header with user info and logout
- Charts section
- Assets table section

### AssetsTable.vue
- Fetches all assets with joins
- Displays asset information
- Generates signed URLs for bills
- Row animations

### ExpenseCharts.vue
- Bar chart for asset counts
- Doughnut chart for distribution
- Fetches company statistics
- Chart animations

## Security

- **RLS Policies**: Database enforces admin-only access
- **JWT Tokens**: Secure authentication tokens
- **Signed URLs**: Time-limited bill access (1 hour)
- **Route Guards**: Prevents unauthorized access

## Usage

### First Time Setup

1. **Create Admin User:**
   ```sql
   -- Get user ID from auth.users after creating account
   INSERT INTO public.admin_users (user_id) 
   VALUES ('<user-uuid-here>');
   ```

2. **Login:**
   - Navigate to `/login`
   - Enter admin credentials
   - Access dashboard

### Viewing Bills

1. Click "View Bill" link in assets table
2. System generates signed URL (valid 1 hour)
3. Bill opens in new tab

### Charts

- Charts automatically load on dashboard
- Data refreshes on page load
- Shows asset counts per company
- Visual representation of distribution

## Development

### Adding New Charts

1. Import chart type from `vue-chartjs/legacy`
2. Register Chart.js components
3. Create data computed property
4. Add to template with options

### Customizing Animations

Modify GSAP animations in component `onMounted` hooks:
```typescript
gsap.from(element, {
  opacity: 0,
  y: 20,
  duration: 0.5,
  ease: 'power2.out'
})
```

## Troubleshooting

### Can't Login
- Verify user exists in `auth.users`
- Check user is in `admin_users` table
- Verify Supabase connection

### Charts Not Loading
- Check browser console for errors
- Verify companies exist in database
- Check network requests in DevTools

### Bills Not Opening
- Verify storage bucket exists
- Check RLS policies allow admin access
- Verify file paths are correct
