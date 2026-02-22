-- Fix the circular dependency in admin_users RLS policy
-- Allow authenticated users to check if they themselves are admins

-- Drop the existing policy
DROP POLICY IF EXISTS "Only admins can view admin_users" ON public.admin_users;

-- Create a new policy that allows users to check their own admin status
-- This breaks the circular dependency
CREATE POLICY "Users can check their own admin status"
    ON public.admin_users
    FOR SELECT
    TO authenticated, service_role
    USING (
        auth.role() = 'service_role'
        OR user_id = auth.uid()  -- Users can check if they themselves are admins
    );
