-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Allow anonymous INSERT for companies" ON public.companies;
DROP POLICY IF EXISTS "Allow admin SELECT for companies" ON public.companies;
DROP POLICY IF EXISTS "Allow admin UPDATE for companies" ON public.companies;
DROP POLICY IF EXISTS "Allow admin DELETE for companies" ON public.companies;

DROP POLICY IF EXISTS "Allow anonymous INSERT for locations" ON public.locations;
DROP POLICY IF EXISTS "Allow admin SELECT for locations" ON public.locations;
DROP POLICY IF EXISTS "Allow admin UPDATE for locations" ON public.locations;
DROP POLICY IF EXISTS "Allow admin DELETE for locations" ON public.locations;

DROP POLICY IF EXISTS "Allow anonymous INSERT for assets" ON public.assets;
DROP POLICY IF EXISTS "Allow admin SELECT for assets" ON public.assets;
DROP POLICY IF EXISTS "Allow admin UPDATE for assets" ON public.assets;
DROP POLICY IF EXISTS "Allow admin DELETE for assets" ON public.assets;

-- Create admin_users table to track admin users
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Enable RLS on admin_users
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Only admins can view the admin_users table
CREATE POLICY "Only admins can view admin_users"
    ON public.admin_users
    FOR SELECT
    TO authenticated, service_role
    USING (
        auth.role() = 'service_role'
        OR EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE user_id = auth.uid()
        )
    );

-- Allow service_role to manage admin_users (for initial setup)
CREATE POLICY "Service role can manage admin_users"
    ON public.admin_users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Helper function to check if user is admin
-- Checks if user is in admin_users table or is service_role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Service role (backend) is always admin
    IF auth.role() = 'service_role' THEN
        RETURN true;
    END IF;
    
    -- Check if authenticated user is in admin_users table
    IF auth.role() = 'authenticated' THEN
        RETURN EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE user_id = auth.uid()
        );
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions on admin_users
GRANT SELECT ON public.admin_users TO authenticated;

-- Companies RLS Policies
-- Allow anonymous INSERT for public onboarding
CREATE POLICY "Allow anonymous INSERT for companies"
    ON public.companies
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Restrict SELECT to admins only (service_role bypasses RLS but included for clarity)
CREATE POLICY "Allow admin SELECT for companies"
    ON public.companies
    FOR SELECT
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Restrict UPDATE to admins only
CREATE POLICY "Allow admin UPDATE for companies"
    ON public.companies
    FOR UPDATE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin())
    WITH CHECK (auth.role() = 'service_role' OR public.is_admin());

-- Restrict DELETE to admins only
CREATE POLICY "Allow admin DELETE for companies"
    ON public.companies
    FOR DELETE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Locations RLS Policies
-- Allow anonymous INSERT for public onboarding
CREATE POLICY "Allow anonymous INSERT for locations"
    ON public.locations
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Restrict SELECT to admins only
CREATE POLICY "Allow admin SELECT for locations"
    ON public.locations
    FOR SELECT
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Restrict UPDATE to admins only
CREATE POLICY "Allow admin UPDATE for locations"
    ON public.locations
    FOR UPDATE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin())
    WITH CHECK (auth.role() = 'service_role' OR public.is_admin());

-- Restrict DELETE to admins only
CREATE POLICY "Allow admin DELETE for locations"
    ON public.locations
    FOR DELETE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Assets RLS Policies
-- Allow anonymous INSERT for public onboarding
CREATE POLICY "Allow anonymous INSERT for assets"
    ON public.assets
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Restrict SELECT to admins only
CREATE POLICY "Allow admin SELECT for assets"
    ON public.assets
    FOR SELECT
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Restrict UPDATE to admins only
CREATE POLICY "Allow admin UPDATE for assets"
    ON public.assets
    FOR UPDATE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin())
    WITH CHECK (auth.role() = 'service_role' OR public.is_admin());

-- Restrict DELETE to admins only
CREATE POLICY "Allow admin DELETE for assets"
    ON public.assets
    FOR DELETE
    TO authenticated, service_role
    USING (auth.role() = 'service_role' OR public.is_admin());

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.companies TO anon, authenticated;
GRANT ALL ON public.locations TO anon, authenticated;
GRANT ALL ON public.assets TO anon, authenticated;
