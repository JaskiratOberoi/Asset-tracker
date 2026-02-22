-- Allow anonymous users to SELECT companies and locations for the onboarding form
-- This is needed so the dropdown can be populated

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow anonymous SELECT for companies" ON public.companies;
DROP POLICY IF EXISTS "Allow anonymous SELECT for locations" ON public.locations;

-- Companies: Allow anonymous SELECT (for dropdown in onboarding form)
CREATE POLICY "Allow anonymous SELECT for companies"
    ON public.companies
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Locations: Allow anonymous SELECT (for dropdown in onboarding form)
CREATE POLICY "Allow anonymous SELECT for locations"
    ON public.locations
    FOR SELECT
    TO anon, authenticated
    USING (true);
