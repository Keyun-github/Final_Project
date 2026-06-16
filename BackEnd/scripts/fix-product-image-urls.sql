-- ===========================================================
-- Fix product imageUrl host: localhost / api.kelun.com
--     -> api-kelun.ngelantour.cloud (Dokploy backend)
--
-- Run this in Dokploy's terminal (or any psql connected to
-- the production Postgres) BEFORE redeploying the backend.
--
-- After this script:
--   - Aqua Galon, Aqua 600ml, Club Galon -> images load
--     (files already exist on Dokploy)
--   - Gula, Kapal Api, Beras PinPin -> URL updated, but
--     the underlying files are still on the old laptop and
--     must be re-uploaded via the admin panel.
-- ===========================================================

BEGIN;

-- Preview the rows that will change (safe, no writes):
SELECT id, name, "imageUrl"
FROM products
WHERE "imageUrl" LIKE '%/uploads/%';

-- Apply the host replacement:
UPDATE products
SET "imageUrl" = REPLACE(
    REPLACE(
        "imageUrl",
        'http://localhost:3000/products/uploads/',
        'https://api-kelun.ngelantour.cloud/products/uploads/'
    ),
    'https://api.kelun.com/products/uploads/',
    'https://api-kelun.ngelantour.cloud/products/uploads/'
)
WHERE "imageUrl" LIKE '%/uploads/%';

-- Verify (should show 0 rows with old hosts):
SELECT id, name, "imageUrl"
FROM products
WHERE "imageUrl" LIKE '%localhost:3000%'
   OR "imageUrl" LIKE '%api.kelun.com%';

COMMIT;
