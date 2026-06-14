-- =====================================================================
-- Clear Dummy Products
-- =====================================================================
-- Purpose:
--   Remove all product records that were auto-seeded by the backend's
--   SeedService. This is a one-time cleanup script to be run BEFORE
--   the backend is restarted after disabling the auto-seed (see
--   BackEnd/src/seed/seed.service.ts).
--
--   Order history is preserved: order_items.productId is nullable and
--   has no ON DELETE CASCADE on the product FK, so the order_items
--   rows remain intact. The productName column on order_items is a
--   plain string and is also kept.
--
-- When to run this:
--   1. Disable auto-seed in seed.service.ts (already done)
--   2. Run this script in the kelun_db database
--   3. Restart the backend
--
-- How to run (pick one):
--   - psql:
--       docker exec -i kelun-postgres psql -U postgres -d kelun_db \
--         < BackEnd/scripts/clear-dummy-products.sql
--   - pgAdmin / DBeaver / TablePlus:
--       Open the file and execute it
-- =====================================================================

BEGIN;

-- Use TRUNCATE ... CASCADE to handle product_variants (variants FK to products)
-- and reset the sequence so future inserts start at id 1.
-- The product_variants table will also be cleared because of CASCADE on the
-- product FK defined in product-variant.entity.ts.
TRUNCATE TABLE products
  RESTART IDENTITY
  CASCADE;

-- Sanity check: confirm products table is empty
DO $$
DECLARE
  remaining INTEGER;
BEGIN
  SELECT COUNT(*) INTO remaining FROM products;
  RAISE NOTICE 'Products remaining after truncate: %', remaining;
END $$;

COMMIT;

-- =====================================================================
-- Post-run expectations:
--   - SELECT COUNT(*) FROM products;            -> 0
--   - SELECT COUNT(*) FROM product_variants;    -> 0
--   - SELECT COUNT(*) FROM order_items;         -> unchanged
--   - SELECT COUNT(*) FROM orders;              -> unchanged
--
-- After this, restart the backend. The SeedService no longer inserts
-- dummy products, so the products table will stay empty until the admin
-- adds products manually via the admin panel Stock page.
-- =====================================================================
