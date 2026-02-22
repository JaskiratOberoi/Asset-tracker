-- Setup the 3 required companies: Qugen/Genomics, Ares, Other
-- This migration replaces any existing companies

-- First, delete existing companies (this will cascade delete locations and assets)
-- Only do this if you want to start fresh
-- DELETE FROM public.companies;

-- Insert the 3 companies
-- Using ON CONFLICT to allow re-running this migration safely
INSERT INTO public.companies (id, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440010', 'Qugen/Genomics'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Ares'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Other')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Alternative: If you want to insert without specific IDs (let database generate them)
-- INSERT INTO public.companies (name) VALUES
--     ('Qugen/Genomics'),
--     ('Ares'),
--     ('Other')
-- ON CONFLICT DO NOTHING;
