# How to Access the Admin Console

## Quick Steps

1. **Create a user account** (if you don't have one)
2. **Make the user an admin**
3. **Login at** http://localhost:1200/login
4. **Access dashboard at** http://localhost:1200/admin

---

## Step-by-Step Instructions

### Option 1: Using Supabase Studio (Easiest)

#### Step 1: Create User Account

1. Open **Supabase Studio**: http://localhost:3001
2. Go to **Authentication** → **Users**
3. Click **"Add User"** or **"Create User"**
4. Enter:
   - **Email**: `admin@example.com` (or your email)
   - **Password**: Choose a secure password
5. Click **"Create User"**
6. **Copy the User ID** (UUID) - you'll need this

#### Step 2: Make User an Admin

1. In Supabase Studio, go to **SQL Editor**
2. Run this SQL (replace `YOUR_USER_ID_HERE` with the UUID you copied):

```sql
INSERT INTO public.admin_users (user_id) 
VALUES ('YOUR_USER_ID_HERE')
ON CONFLICT (user_id) DO NOTHING;
```

3. Click **"Run"**

#### Step 3: Login to Admin Dashboard

1. Open your frontend: http://localhost:1200/login
2. Enter your email and password
3. Click **"Sign In"**
4. You'll be redirected to http://localhost:1200/admin

---

### Option 2: Using PowerShell Script (Windows)

1. **Create user via API** (or Supabase Studio):
   ```powershell
   $headers = @{
       'apikey' = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE4MDMyMDQ1NDF9.Zjp54s-IyfdfyB2z0veijDFJgMZmunXmqHXkD94gWHs'
       'Content-Type' = 'application/json'
   }
   $body = @{
       email = 'admin@example.com'
       password = 'your-secure-password'
   } | ConvertTo-Json
   
   Invoke-WebRequest -Uri 'http://localhost:8000/auth/v1/signup' -Method POST -Headers $headers -Body $body
   ```

2. **Run the setup script**:
   ```powershell
   .\setup-admin.ps1 -UserEmail "admin@example.com"
   ```

3. **Login**: http://localhost:1200/login

---

### Option 3: Direct SQL (If you know the user ID)

```sql
-- Get user ID first
SELECT id, email FROM auth.users WHERE email = 'admin@example.com';

-- Then add to admin_users (replace with actual UUID)
INSERT INTO public.admin_users (user_id) 
VALUES ('<user-uuid-from-above>')
ON CONFLICT (user_id) DO NOTHING;
```

---

## Troubleshooting

### "Access denied. Admin privileges required."
- The user is not in the `admin_users` table
- Run the SQL to add them (see Step 2 above)

### "Login failed"
- Check email/password are correct
- User might not exist - create via Supabase Studio first

### Can't access Supabase Studio
- Make sure Docker containers are running: `docker-compose ps`
- Studio should be at http://localhost:3001

### User not found in database
- Create the user first via Supabase Studio or Auth API
- Then add them to `admin_users` table

---

## Admin Dashboard Features

Once logged in at http://localhost:1200/admin, you can:

- **View all assets** in a data table
- **View bill documents** (click "View Bill" links)
- **See expense reports** with charts showing asset distribution across companies
- **Logout** from the header

---

## Quick Reference

- **Login Page**: http://localhost:1200/login
- **Admin Dashboard**: http://localhost:1200/admin
- **Supabase Studio**: http://localhost:3001
- **Onboarding Form**: http://localhost:1200/onboarding
