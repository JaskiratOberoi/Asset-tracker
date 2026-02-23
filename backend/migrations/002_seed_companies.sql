INSERT INTO public.companies (id, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440010', 'Qugen/Genomics'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Ares'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Other')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
