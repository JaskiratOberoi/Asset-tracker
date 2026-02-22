-- Add is_anonymous column to auth.users for Supabase Dashboard compatibility
-- The Dashboard (Authentication > Users) expects this column (used for anonymous sign-ins).
-- Existing users are treated as non-anonymous.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth'
          AND table_name = 'users'
          AND column_name = 'is_anonymous'
    ) THEN
        ALTER TABLE auth.users
        ADD COLUMN is_anonymous boolean NOT NULL DEFAULT false;
    END IF;
END
$$;
