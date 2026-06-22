-- ===========================================================
-- Create the store_config table (singleton row, id=1) so admins
-- can update the store's address / lat / lng from the admin
-- panel instead of editing source code.
--
-- Run this in the Dokploy postgres terminal BEFORE redeploying
-- the backend.
-- ===========================================================

BEGIN;

CREATE TABLE IF NOT EXISTS store_config (
  id          INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  address     VARCHAR(500) NOT NULL,
  lat         DOUBLE PRECISION NOT NULL,
  lng         DOUBLE PRECISION NOT NULL,
  updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_by  VARCHAR(100)
);

-- Seed with the existing hardcoded defaults so existing
-- rows behave identically until the admin updates them.
INSERT INTO store_config (id, address, lat, lng)
VALUES (1, 'Jl. Kedung Rukem IV / 55', -7.2628478, 112.7336368)
ON CONFLICT (id) DO NOTHING;

-- Verify
SELECT id, address, lat, lng, updated_at, updated_by
FROM   store_config;

COMMIT;