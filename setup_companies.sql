-- Setup the 3 required companies: Qugen/Genomics, Ares, Other
-- Run this in Supabase Studio SQL Editor

-- Insert the 3 companies
-- Using ON CONFLICT to allow re-running this script safely
INSERT INTO public.companies (id, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440010', 'Qugen/Genomics'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Ares'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Other')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Verify the companies were created
SELECT id, name, created_at FROM public.companies ORDER BY name;
