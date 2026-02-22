-- Create storage bucket for bills
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'bills',
    'bills',
    false, -- Private bucket for security
    52428800, -- 50MB file size limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies for bills bucket
-- Allow anonymous INSERT for public onboarding
CREATE POLICY "Allow anonymous INSERT to bills bucket"
    ON storage.objects
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (bucket_id = 'bills');

-- Restrict SELECT to admins only (service_role bypasses RLS but included for clarity)
CREATE POLICY "Allow admin SELECT from bills bucket"
    ON storage.objects
    FOR SELECT
    TO authenticated, service_role
    USING (
        bucket_id = 'bills' 
        AND (auth.role() = 'service_role' OR public.is_admin())
    );

-- Restrict UPDATE to admins only
CREATE POLICY "Allow admin UPDATE to bills bucket"
    ON storage.objects
    FOR UPDATE
    TO authenticated, service_role
    USING (
        bucket_id = 'bills' 
        AND (auth.role() = 'service_role' OR public.is_admin())
    )
    WITH CHECK (
        bucket_id = 'bills' 
        AND (auth.role() = 'service_role' OR public.is_admin())
    );

-- Restrict DELETE to admins only
CREATE POLICY "Allow admin DELETE from bills bucket"
    ON storage.objects
    FOR DELETE
    TO authenticated, service_role
    USING (
        bucket_id = 'bills' 
        AND (auth.role() = 'service_role' OR public.is_admin())
    );

-- Grant necessary permissions on storage schema
GRANT USAGE ON SCHEMA storage TO anon, authenticated;
GRANT ALL ON storage.objects TO anon, authenticated;
GRANT ALL ON storage.buckets TO anon, authenticated;
