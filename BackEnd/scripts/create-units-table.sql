-- ===========================================================
-- Create the units table and seed the five default units.
-- Run this in the Dokploy postgres terminal (or any psql
-- connected to the production database) BEFORE the redeploy.
-- Safe to re-run: uses IF NOT EXISTS and ON CONFLICT DO NOTHING.
-- ===========================================================

BEGIN;

CREATE TABLE IF NOT EXISTS units (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(50) UNIQUE NOT NULL,
  "isDefault" BOOLEAN NOT NULL DEFAULT FALSE,
  "isActive"  BOOLEAN NOT NULL DEFAULT TRUE,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO units (name, "isDefault", "isActive")
VALUES
  ('KG',          TRUE, TRUE),
  ('Box',         TRUE, TRUE),
  ('Sack - 25kg', TRUE, TRUE),
  ('Sack - 50kg', TRUE, TRUE),
  ('Piece',       TRUE, TRUE)
ON CONFLICT (name) DO NOTHING;

-- Verify
SELECT id, name, "isDefault", "isActive" FROM units ORDER BY "isDefault" DESC, name;

COMMIT;
