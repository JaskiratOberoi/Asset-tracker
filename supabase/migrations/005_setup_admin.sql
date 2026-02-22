-- This migration sets up the first admin user
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID of your admin user
-- You can get this from the auth.users table after creating a user account

-- Example: To make a user an admin, run this SQL after getting their user_id:
-- INSERT INTO public.admin_users (user_id) VALUES ('<user-uuid-here>');

-- Note: For initial setup, you may need to temporarily disable RLS or use service_role
-- to insert the first admin user. After that, admins can manage other admins.
