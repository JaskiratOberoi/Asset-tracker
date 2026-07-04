-- Add Bareilly and Rudrapur locations for Qugen/Genomics (company_id from 002_seed_companies)
-- Idempotent: migrations re-run on every API start, so guard against duplicate seeding.
INSERT INTO public.locations (company_id, name)
SELECT v.company_id::uuid, v.name
FROM (VALUES
    ('550e8400-e29b-41d4-a716-446655440010', 'Bareilly'),
    ('550e8400-e29b-41d4-a716-446655440010', 'Rudrapur')
) AS v(company_id, name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.locations l
    WHERE l.company_id = v.company_id::uuid AND l.name = v.name
);
