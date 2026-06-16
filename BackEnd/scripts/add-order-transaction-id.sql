-- ===========================================================
-- Add `transactionId` column to the `orders` table so we can
-- verify Midtrans payment status from the app.
--
-- Run this in the Dokploy postgres terminal BEFORE redeploying
-- the backend.
-- ===========================================================

BEGIN;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS "transactionId" VARCHAR(255);

-- Verify
SELECT column_name, data_type
FROM   information_schema.columns
WHERE  table_name = 'orders'
ORDER BY ordinal_position;

COMMIT;
