-- ============================================
-- Database Setup Script for Kelun Project
-- PostgreSQL
-- ============================================

-- Create the database (run as superuser)
-- CREATE DATABASE kelun_db;

-- Connect to the database and run the following:

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
    unit VARCHAR(50) DEFAULT 'Piece',
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 2. PRODUCT VARIANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS product_variants (
    id SERIAL PRIMARY KEY,
    "productId" INTEGER REFERENCES products(id) ON DELETE CASCADE,
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
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    "customerName" VARCHAR(255) NOT NULL,
    "customerPhone" VARCHAR(50) NOT NULL,
    "deliveryAddress" TEXT NOT NULL,
    "totalAmount" DECIMAL(12, 2) NOT NULL,
    "paymentMethod" VARCHAR(50) DEFAULT 'COD',
    status VARCHAR(50) DEFAULT 'pending',
    "driverId" INTEGER REFERENCES drivers(id),
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 5. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    "orderId" INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    "productId" INTEGER REFERENCES products(id),
    "productName" VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    "unitPrice" DECIMAL(12, 2) NOT NULL,
    "unitName" VARCHAR(100) DEFAULT '',
    subtotal DECIMAL(12, 2) NOT NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_driver ON orders("driverId");
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items("orderId");
CREATE INDEX IF NOT EXISTS idx_drivers_active ON drivers("isActive");

-- ============================================
-- SEED DATA: Default Drivers (Employees)
-- ============================================
INSERT INTO drivers (username, password, name, phone, "isActive")
VALUES 
    ('driver1', 'driver1', 'Ahmad Kurniawan', '081234567890', true),
    ('driver2', 'driver2', 'Bambang Suryadi', '081298765432', true)
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- SEED DATA: Sample Products
-- ============================================
INSERT INTO products (name, description, price, "imageUrl", category, rating, sold, seller, "sellerCity", stock, unit)
VALUES 
    ('Gula Pasir Premium', 'Gula pasir putih kualitas premium, cocok untuk kebutuhan masakan dan minuman sehari-hari.', 15000, 'https://picsum.photos/seed/sugar/400/400', 'Food & Drinks', 4.8, 21500, 'Distributor Sembako', 'Jakarta', 40, 'KG'),
    ('Kopi Kapal Api Special', 'Kopi bubuk instan dengan aroma yang khas dan nikmat, sangat cocok menemani pagi hari Anda.', 3500, 'https://picsum.photos/seed/coffee_packet/400/400', 'Food & Drinks', 4.9, 15420, 'Kopi Nusantara', 'Surabaya', 90, 'Piece'),
    ('Wireless Bluetooth Earbuds Pro', 'Premium wireless earbuds with active noise cancellation, 30-hour battery life, and IPX5 water resistance.', 299000, 'https://picsum.photos/seed/earbuds/400/400', 'Electronics', 4.8, 1250, 'TechStore Official', 'Jakarta', 50, 'Piece'),
    ('Kaos Polos Katun Premium', 'Kaos polos bahan katun combed 30s yang adem dan nyaman dipakai sehari-hari.', 89000, 'https://picsum.photos/seed/tshirt/400/400', 'Fashion', 4.6, 5420, 'Fashion House', 'Bandung', 100, 'Piece'),
    ('Sepatu Running Ultralight', 'Sepatu olahraga ultralight dengan sol empuk untuk kenyamanan maksimal saat berlari.', 459000, 'https://picsum.photos/seed/shoes/400/400', 'Fashion', 4.7, 890, 'Sport Zone', 'Surabaya', 30, 'Piece'),
    ('Tas Ransel Anti Air 30L', 'Tas ransel kapasitas 30L dengan bahan anti air, cocok untuk sekolah, kuliah, atau travelling.', 175000, 'https://picsum.photos/seed/backpack/400/400', 'Fashion', 4.5, 3200, 'Bag Corner', 'Yogyakarta', 60, 'Piece'),
    ('Skincare Set Brightening', 'Paket lengkap skincare untuk mencerahkan wajah: facial wash, toner, serum, moisturizer, dan sunscreen SPF50.', 249000, 'https://picsum.photos/seed/skincare/400/400', 'Health & Beauty', 4.9, 7800, 'Beauty Official', 'Jakarta', 80, 'Piece'),
    ('Mie Instan Premium Box (40 pcs)', 'Mie instan premium dengan bumbu spesial. Tersedia rasa: Ayam Bawang, Soto, Kari Ayam, Goreng Spesial.', 120000, 'https://picsum.photos/seed/noodles/400/400', 'Food & Drinks', 4.4, 15000, 'Grocery Mart', 'Semarang', 200, 'Box'),
    ('Mechanical Keyboard RGB', 'Keyboard mekanikal dengan switch Cherry MX, backlight RGB, dan keycap PBT doubleshot.', 550000, 'https://picsum.photos/seed/keyboard/400/400', 'Electronics', 4.7, 620, 'TechStore Official', 'Jakarta', 25, 'Piece'),
    ('Tumbler Stainless 750ml', 'Tumbler premium bahan stainless steel, tahan panas/dingin hingga 12 jam. BPA-free dan food grade.', 135000, 'https://picsum.photos/seed/tumbler/400/400', 'Home & Living', 4.6, 2100, 'Home Essentials', 'Bandung', 75, 'Piece')
ON CONFLICT DO NOTHING;

-- Add variants for Gula Pasir
INSERT INTO product_variants ("productId", "unitName", price)
SELECT p.id, v."unitName", v.price
FROM products p
CROSS JOIN (VALUES 
    ('KG', 15000::DECIMAL),
    ('Sack 25KG', 360000::DECIMAL),
    ('Sack 50KG', 710000::DECIMAL)
) AS v("unitName", price)
WHERE p.name = 'Gula Pasir Premium'
AND NOT EXISTS (
    SELECT 1 FROM product_variants pv WHERE pv."productId" = p.id AND pv."unitName" = v."unitName"
);

-- Add variants for Kopi Kapal Api
INSERT INTO product_variants ("productId", "unitName", price)
SELECT p.id, v."unitName", v.price
FROM products p
CROSS JOIN (VALUES 
    ('Piece', 3500::DECIMAL),
    ('Box', 82000::DECIMAL)
) AS v("unitName", price)
WHERE p.name = 'Kopi Kapal Api Special'
AND NOT EXISTS (
    SELECT 1 FROM product_variants pv WHERE pv."productId" = p.id AND pv."unitName" = v."unitName"
);

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- View: Order Summary with Driver Info
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    o.id,
    o."customerName",
    o."customerPhone",
    o."deliveryAddress",
    o."totalAmount",
    o."paymentMethod",
    o.status,
    d.name AS "driverName",
    o."createdAt"
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
    COALESCE(SUM(oi.quantity), 0) AS "totalSold",
    COALESCE(SUM(oi.subtotal), 0) AS "totalRevenue"
FROM products p
LEFT JOIN order_items oi ON p.id = oi."productId"
GROUP BY p.id, p.name, p.category, p.price, p.stock;

-- ============================================
-- TRIGGER FUNCTION: Update timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_drivers_updated_at ON drivers;
CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_order_items_updated_at ON order_items;
CREATE TRIGGER update_order_items_updated_at
    BEFORE UPDATE ON order_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_product_variants_updated_at ON product_variants;
CREATE TRIGGER update_product_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
