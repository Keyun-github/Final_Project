-- ===========================================================
-- Add `stock` column to product_variants so each unit-of-measure
-- keeps its own stock. Backfill from the parent product's stock
-- for any variants that don't have a value yet.
--
-- Run this in the Dokploy postgres terminal BEFORE redeploying
-- the backend.
-- ===========================================================

BEGIN;

ALTER TABLE product_variants
  ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 0;

-- Backfill: copy the parent's stock into the variant so existing
-- products keep behaving the same way until admins edit them.
UPDATE product_variants pv
SET    stock = p.stock
FROM   products p
WHERE  pv."productId" = p.id
  AND  (pv.stock IS NULL OR pv.stock = 0);

-- Verify
SELECT pv.id, p.name AS product, pv."unitName", pv.stock
FROM   product_variants pv
JOIN   products p ON p.id = pv."productId"
ORDER BY p.name, pv."unitName";

COMMIT;
