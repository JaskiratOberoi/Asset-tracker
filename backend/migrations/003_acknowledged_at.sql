-- Allow admin to acknowledge onboarded assets (anyone can onboard, admin must acknowledge)
ALTER TABLE public.assets
ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ DEFAULT NULL;

COMMENT ON COLUMN public.assets.acknowledged_at IS 'When an admin acknowledged this asset; NULL means pending acknowledgement';
