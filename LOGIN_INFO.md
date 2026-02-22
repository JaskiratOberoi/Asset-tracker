# Admin Login Information

## ✅ Your Admin Account is Ready!

The user account has been created directly in the database. You can **skip creating it in Supabase Studio**.

## Login Credentials

- **Email**: `Jso101196@gmail.com`
- **Password**: `Test123456!`
- **Status**: ✅ Admin (already added to admin_users table)

## Access the Admin Dashboard

1. **Open your browser** and go to: **http://localhost:1200/login**

2. **Enter your credentials**:
   - Email: `Jso101196@gmail.com`
   - Password: `Test123456!`

3. **Click "Sign In"**

4. You'll be automatically redirected to: **http://localhost:1200/admin**

## What You'll See

Once logged in, the admin dashboard includes:

- **Assets Table**: View all assets with company and location information
- **View Bill Links**: Click to view bill documents
- **Expense Charts**: 
  - Bar chart showing asset distribution across companies
  - Doughnut chart showing percentage breakdown
- **Logout Button**: In the top right corner

## Troubleshooting

### "Access denied. Admin privileges required."
- The user is already in the `admin_users` table
- If you see this error, try refreshing the page or clearing browser cache

### "Login failed"
- Make sure the frontend is running on port 1200
- Check that Supabase services are running: `docker-compose ps`
- Verify the email and password are correct

### Can't access login page
- Make sure the frontend dev server is running: `cd frontend && npm run dev`
- Check http://localhost:1200 is accessible

## Quick Links

- **Login Page**: http://localhost:1200/login
- **Admin Dashboard**: http://localhost:1200/admin
- **Onboarding Form**: http://localhost:1200/onboarding
- **Supabase Studio**: http://localhost:3001

---

**Note**: You don't need to create the user in Supabase Studio anymore - it's already created and ready to use!
