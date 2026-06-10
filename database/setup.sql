-- ============================================
-- Database Setup Script for Kelun Project (PRODUCTION-READY)
-- PostgreSQL 15
--
-- Match dengan semua TypeORM entities per 2026-06-10:
--   - product.entity.ts
--   - product-variant.entity.ts
--   - driver.entity.ts
--   - customer.entity.ts
--   - order.entity.ts
--   - order-item.entity.ts
--   - time-slot.entity.ts
--   - chat/entities/conversation.entity.ts
--   - chat/entities/message.entity.ts
--
-- Designed for:
--   - synchronize: false (TypeORM will NOT touch schema)
--   - Production deployment di Dokploy
--   - No dummy product seed (admin input manual)
--   - Default driver accounts untuk testing login
-- ============================================

-- Create the database (run as superuser, separate connection)
-- CREATE DATABASE kelun_db;

-- Connect to the database and run the following:
-- \c kelun_db

-- ============================================
-- 1. PRODUCTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    price DECIMAL(12, 2) NOT NULL,
    "imageUrl" VARCHAR(500) DEFAULT '',
    category VARCHAR(100) DEFAULT '',
    rating DECIMAL(3, 1) DEFAULT 0,
    sold INTEGER DEFAULT 0,
    seller VARCHAR(255) DEFAULT '',
    "sellerCity" VARCHAR(100) DEFAULT '',
    stock INTEGER DEFAULT 0,
    "leadTime" INTEGER DEFAULT 3,
    "safetyStock" INTEGER DEFAULT 5,
    unit VARCHAR(50) DEFAULT 'Piece',
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 2. PRODUCT VARIANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS product_variants (
    id SERIAL PRIMARY KEY,
    "productId" INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    "unitName" VARCHAR(100) NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. DRIVERS TABLE (Employees/Couriers)
-- ============================================
CREATE TABLE IF NOT EXISTS drivers (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) DEFAULT '',
    "isActive" BOOLEAN DEFAULT true,
    "vehicleType" VARCHAR(50) DEFAULT 'motorcycle',
    "vehicleBrand" VARCHAR(100) DEFAULT '',
    "vehiclePlate" VARCHAR(50) DEFAULT '',
    "vehicleColor" VARCHAR(50) DEFAULT '',
    "currentLat" DECIMAL(10, 7),
    "currentLng" DECIMAL(10, 7),
    "isAvailable" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. CUSTOMERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(100) DEFAULT '',
    phone VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    address TEXT DEFAULT '',
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 5. ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    "customerId" INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    "customerName" VARCHAR(255) NOT NULL,
    "customerPhone" VARCHAR(50) DEFAULT '',
    "pickupAddress" TEXT DEFAULT 'Gudang Utama, Jl. Industri No. 15, Jakarta Utara',
    "deliveryAddress" TEXT DEFAULT '',
    "totalAmount" DECIMAL(12, 2) DEFAULT 0,
    "paymentMethod" VARCHAR(50) DEFAULT 'COD',
    status VARCHAR(50) DEFAULT 'pending',
    "driverId" INTEGER REFERENCES drivers(id) ON DELETE SET NULL,
    "deliveryPhoto" VARCHAR(500),
    "deliveryLat" DOUBLE PRECISION DEFAULT 0,
    "deliveryLng" DOUBLE PRECISION DEFAULT 0,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 6. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    "orderId" INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    "productId" INTEGER REFERENCES products(id) ON DELETE SET NULL,
    "productName" VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    "unitPrice" DECIMAL(12, 2) NOT NULL,
    "unitName" VARCHAR(100) DEFAULT '',
    subtotal DECIMAL(12, 2) NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 7. TIME SLOTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS time_slots (
    id SERIAL PRIMARY KEY,
    "slotTime" VARCHAR(10) NOT NULL,
    "slotDate" VARCHAR(20) NOT NULL,
    bookings INTEGER DEFAULT 0,
    "maxBookings" INTEGER DEFAULT 3,
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE("slotTime", "slotDate")
);

-- ============================================
-- 8. CONVERSATIONS TABLE (Chat)
-- ============================================
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    "order_id" INTEGER UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    "customer_id" INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    "driver_id" INTEGER NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 9. MESSAGES TABLE (Chat)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    "conversation_id" INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    "sender_type" VARCHAR(20) NOT NULL CHECK ("sender_type" IN ('customer', 'driver')),
    "sender_id" INTEGER NOT NULL,
    message TEXT NOT NULL,
    "is_read" BOOLEAN DEFAULT false,
    "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_seller ON products(seller);

CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants("productId");

CREATE INDEX IF NOT EXISTS idx_drivers_active ON drivers("isActive");
CREATE INDEX IF NOT EXISTS idx_drivers_available ON drivers("isAvailable");
CREATE INDEX IF NOT EXISTS idx_drivers_username ON drivers(username);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_username ON customers(username);

CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_driver ON orders("driverId");
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders("customerId");
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders("createdAt");

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items("orderId");
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items("productId");

CREATE INDEX IF NOT EXISTS idx_time_slots_date ON time_slots("slotDate");
CREATE INDEX IF NOT EXISTS idx_time_slots_active ON time_slots("isActive");

CREATE INDEX IF NOT EXISTS idx_conversations_order ON conversations("order_id");
CREATE INDEX IF NOT EXISTS idx_conversations_customer ON conversations("customer_id");
CREATE INDEX IF NOT EXISTS idx_conversations_driver ON conversations("driver_id");

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages("conversation_id");
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages("sender_type", "sender_id");
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages("created_at");

-- ============================================
-- SEED DATA: Default Drivers (untuk testing login)
-- ============================================
INSERT INTO drivers (username, password, name, phone, "isActive", "isAvailable")
VALUES
    ('driver1', 'driver1', 'Ahmad Kurniawan', '081234567890', true, true),
    ('driver2', 'driver2', 'Bambang Suryadi', '081298765432', true, true)
ON CONFLICT (username) DO NOTHING;

-- NOTE: No product seed. Admin must add products via Admin Panel Stock page.
-- This keeps the production catalog clean and owned by the store admin.

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- View: Order Summary with Driver Info
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.id,
    o."customerId",
    o."customerName",
    o."customerPhone",
    o."deliveryAddress",
    o."totalAmount",
    o."paymentMethod",
    o.status,
    o."driverId",
    d.name AS "driverName",
    d.phone AS "driverPhone",
    o."createdAt",
    o."updatedAt"
FROM orders o
LEFT JOIN drivers d ON o."driverId" = d.id;

-- View: Product Sales Summary
CREATE OR REPLACE VIEW v_product_sales AS
SELECT
    p.id,
    p.name,
    p.category,
    p.price,
    p.stock,
    p.sold AS "currentSold",
    COALESCE(SUM(oi.quantity), 0) AS "orderItemSold",
    COALESCE(SUM(oi.subtotal), 0) AS "totalRevenue"
FROM products p
LEFT JOIN order_items oi ON p.id = oi."productId"
GROUP BY p.id, p.name, p.category, p.price, p.stock, p.sold;

-- View: Low Stock Products (uses safetyStock threshold)
CREATE OR REPLACE VIEW v_low_stock_products AS
SELECT
    p.id,
    p.name,
    p.category,
    p.stock,
    p."safetyStock",
    p."leadTime",
    p.sold
FROM products p
WHERE p.stock <= p."safetyStock"
ORDER BY p.stock ASC;

-- ============================================
-- TRIGGER FUNCTION: Update updatedAt column
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for products
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for product_variants
DROP TRIGGER IF EXISTS update_product_variants_updated_at ON product_variants;
CREATE TRIGGER update_product_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for drivers
DROP TRIGGER IF EXISTS update_drivers_updated_at ON drivers;
CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for customers
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for orders
DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for order_items
DROP TRIGGER IF EXISTS update_order_items_updated_at ON order_items;
CREATE TRIGGER update_order_items_updated_at
    BEFORE UPDATE ON order_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for time_slots
DROP TRIGGER IF EXISTS update_time_slots_updated_at ON time_slots;
CREATE TRIGGER update_time_slots_updated_at
    BEFORE UPDATE ON time_slots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for conversations (uses updated_at)
CREATE OR REPLACE FUNCTION update_updated_at_column_lower()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updated_at" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column_lower();

-- ============================================
-- POST-INSTALL VERIFICATION
-- ============================================

DO $$
DECLARE
    table_count INTEGER;
    driver_count INTEGER;
    product_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('products', 'product_variants', 'drivers', 'customers', 'orders', 'order_items', 'time_slots', 'conversations', 'messages');

    SELECT COUNT(*) INTO driver_count FROM drivers;
    SELECT COUNT(*) INTO product_count FROM products;

    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database setup completed';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables created: % / 9 expected', table_count;
    RAISE NOTICE 'Drivers seeded: %', driver_count;
    RAISE NOTICE 'Products in catalog: % (should be 0, admin adds via UI)', product_count;
    RAISE NOTICE '========================================';
END $$;
