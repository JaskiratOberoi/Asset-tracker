-- One-time cleanup: seed migrations 004/005 were not idempotent before and re-ran on
-- every API restart, creating ~37 duplicate rows per location. Repoint assets to the
-- canonical (lowest-id) row per (company_id, name), delete the duplicates, and add a
-- unique index so duplicates cannot recur. Safe to re-run: subsequent runs find no
-- duplicates and the index is IF NOT EXISTS.

UPDATE public.assets a SET location_id = r.canonical_id
FROM (
    SELECT id,
           FIRST_VALUE(id) OVER (PARTITION BY company_id, name ORDER BY id) AS canonical_id,
           ROW_NUMBER() OVER (PARTITION BY company_id, name ORDER BY id) AS rn
    FROM public.locations
) r
WHERE a.location_id = r.id AND r.rn > 1;

DELETE FROM public.locations l USING (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY company_id, name ORDER BY id) AS rn
    FROM public.locations
) d
WHERE l.id = d.id AND d.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS locations_company_name_uniq
    ON public.locations (company_id, name);
