-- Insert 3 companies: Qugen/Genomics, Ares, Other
INSERT INTO public.companies (id, name) VALUES
    ('550e8400-e29b-41d4-a716-446655440010', 'Qugen/Genomics'),
    ('550e8400-e29b-41d4-a716-446655440011', 'Ares'),
    ('550e8400-e29b-41d4-a716-446655440012', 'Other')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- Insert mock locations for each company
INSERT INTO public.locations (id, company_id, name, address, city, state, country, postal_code) VALUES
    -- Acme Corporation locations
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Headquarters', '123 Main St', 'San Francisco', 'CA', 'USA', '94102'),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Warehouse East', '456 Industrial Blvd', 'New York', 'NY', 'USA', '10001'),
    
    -- TechStart Industries locations
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 'Main Office', '789 Tech Park', 'Austin', 'TX', 'USA', '78701'),
    ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440002', 'Development Center', '321 Innovation Drive', 'Seattle', 'WA', 'USA', '98101'),
    
    -- Global Solutions Inc. locations
    ('660e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440003', 'Corporate HQ', '999 Business Plaza', 'London', 'Greater London', 'UK', 'SW1A 1AA'),
    ('660e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440003', 'Asia Pacific Office', '88 Financial Street', 'Singapore', 'Central Region', 'Singapore', '018956')
ON CONFLICT (id) DO NOTHING;

-- Insert mock assets
INSERT INTO public.assets (id, name, details, serial_number, company_id, location_id, bill_url) VALUES
    -- Acme Corporation assets
    ('770e8400-e29b-41d4-a716-446655440001', 'Laptop Dell XPS 15', '{"brand": "Dell", "model": "XPS 15", "processor": "Intel i7", "ram": "16GB", "storage": "512GB SSD"}', 'DL-XPS15-2024-001', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'bills/acme/dell-xps15-001.pdf'),
    ('770e8400-e29b-41d4-a716-446655440002', 'Office Printer HP LaserJet', '{"brand": "HP", "model": "LaserJet Pro M404dn", "type": "Laser", "color": "Monochrome"}', 'HP-LJ-M404-2024-002', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'bills/acme/hp-printer-002.pdf'),
    ('770e8400-e29b-41d4-a716-446655440003', 'Forklift Toyota 8FGCU25', '{"brand": "Toyota", "model": "8FGCU25", "capacity": "2500kg", "power": "Electric"}', 'TOY-8FGCU25-2024-003', '550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002', 'bills/acme/toyota-forklift-003.pdf'),
    
    -- TechStart Industries assets
    ('770e8400-e29b-41d4-a716-446655440004', 'MacBook Pro 16"', '{"brand": "Apple", "model": "MacBook Pro 16", "processor": "M2 Pro", "ram": "32GB", "storage": "1TB SSD"}', 'APP-MBP16-2024-004', '550e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440003', 'bills/techstart/macbook-pro-004.pdf'),
    ('770e8400-e29b-41d4-a716-446655440005', 'Server Rack Dell PowerEdge', '{"brand": "Dell", "model": "PowerEdge R750", "processors": "2x Intel Xeon", "ram": "128GB", "storage": "4x 1TB SSD"}', 'DL-PE-R750-2024-005', '550e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440004', 'bills/techstart/dell-server-005.pdf'),
    ('770e8400-e29b-41d4-a716-446655440006', 'Monitor LG UltraWide 34"', '{"brand": "LG", "model": "34WP65C-B", "size": "34 inch", "resolution": "3440x1440", "panel": "IPS"}', 'LG-UW34-2024-006', '550e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440003', 'bills/techstart/lg-monitor-006.pdf'),
    
    -- Global Solutions Inc. assets
    ('770e8400-e29b-41d4-a716-446655440007', 'Conference Table', '{"brand": "Herman Miller", "model": "Canvas Table", "size": "10ft", "material": "Walnut", "seating": "12"}', 'HM-CT-10FT-2024-007', '550e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440005', 'bills/global/herman-miller-table-007.pdf'),
    ('770e8400-e29b-41d4-a716-446655440008', 'Security Camera System', '{"brand": "Hikvision", "model": "DS-2CD2T47G1-L", "type": "IP Camera", "resolution": "4MP", "quantity": 8}', 'HIK-DS2CD-2024-008', '550e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440005', 'bills/global/hikvision-cameras-008.pdf'),
    ('770e8400-e29b-41d4-a716-446655440009', 'Projector Epson PowerLite', '{"brand": "Epson", "model": "PowerLite X41+", "resolution": "Full HD", "brightness": "4200 lumens", "type": "3LCD"}', 'EPS-PL-X41-2024-009', '550e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440006', 'bills/global/epson-projector-009.pdf')
ON CONFLICT (id) DO NOTHING;
