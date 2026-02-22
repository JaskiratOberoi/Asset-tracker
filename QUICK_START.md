# Quick Start Guide

## 1. Start Supabase

```bash
docker-compose up -d
```

Wait for all services to be healthy (check with `docker-compose ps`).

## 2. Access Supabase Studio

Open http://localhost:3001 in your browser.

## 3. Create Your First User

### Option A: Via Supabase Studio
1. Go to Authentication → Users
2. Click "Add User"
3. Enter email and password
4. Note the User ID (UUID)

### Option B: Via API
```bash
curl -X POST 'http://localhost:8000/auth/v1/signup' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "secure-password"
  }'
```

## 4. Make User an Admin

### Option A: Via SQL Editor in Studio
1. Go to SQL Editor
2. Run:
```sql
-- Replace with your user's UUID
INSERT INTO public.admin_users (user_id) 
VALUES ('<your-user-uuid-here>');
```

### Option B: Via Script
```bash
# Linux/Mac
./setup-admin.sh admin@example.com

# Windows PowerShell
.\setup-admin.ps1 -UserEmail admin@example.com
```

## 5. Test the API

### Create a Company (Anonymous - Allowed)
```bash
curl -X POST 'http://localhost:8000/rest/v1/companies' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Company"}'
```

### Query Companies (Requires Admin Auth)
```bash
# First, get a JWT token by signing in
TOKEN=$(curl -X POST 'http://localhost:8000/auth/v1/token?grant_type=password' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "secure-password"
  }' | jq -r '.access_token')

# Then query companies
curl -X GET 'http://localhost:8000/rest/v1/companies' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer $TOKEN"
```

## Default Keys (Development Only)

- **ANON_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0`
- **SERVICE_ROLE_KEY**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU`

⚠️ **Change these in production!**

## Troubleshooting

### Can't connect to database
- Check if containers are running: `docker-compose ps`
- Check database logs: `docker-compose logs db`
- Wait for health check to pass

### RLS policies not working
- Verify user is in `admin_users` table
- Check JWT token is valid
- Ensure you're using the correct role (authenticated vs service_role)

### Storage upload fails
- Verify bucket exists: Check `storage.buckets` table
- Check file size (limit: 50MB)
- Verify MIME type is allowed
