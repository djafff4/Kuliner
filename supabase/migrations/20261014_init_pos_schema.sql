-- ==============================================================================
-- SKEMA DATABASE SUPABASE (POSTGRESQL) - POS KULINER
-- Versi: 1.0 (Berdasarkan PRD POS Kuliner Bab 10 & 11)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL TOKO & OUTLET (FR-SET)
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    address TEXT,
    phone VARCHAR(30),
    npwp VARCHAR(50),
    tax_percent NUMERIC(5,2) DEFAULT 10.0,
    service_charge_percent NUMERIC(5,2) DEFAULT 5.0,
    timezone VARCHAR(50) DEFAULT 'Asia/Jakarta',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS outlets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABEL PENGGUNA & PERAN (FR-AUTH)
CREATE TYPE user_role AS ENUM ('owner', 'manager', 'cashier', 'kitchen');

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    outlet_id UUID REFERENCES outlets(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    pin_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'cashier',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABEL KATEGORI & PRODUK MENU (FR-MENU)
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(50) PRIMARY KEY,
    outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(50) PRIMARY KEY,
    category_id VARCHAR(50) REFERENCES categories(id) ON DELETE SET NULL,
    outlet_id UUID REFERENCES outlets(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    base_price INT NOT NULL,
    photo_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    version INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS product_variants (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price_difference INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS modifier_groups (
    id VARCHAR(50) PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    min_select INT DEFAULT 0,
    max_select INT DEFAULT 1
);

CREATE TABLE IF NOT EXISTS modifier_options (
    id VARCHAR(50) PRIMARY KEY,
    group_id VARCHAR(50) NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    additional_price INT DEFAULT 0
);

-- 5. TABEL SHIFT & MANAJEMEN KAS (FR-SHIFT)
CREATE TABLE IF NOT EXISTS shifts (
    id VARCHAR(100) PRIMARY KEY,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    opening_cash INT NOT NULL,
    closing_cash_actual INT,
    total_cash_sales INT DEFAULT 0,
    total_non_cash_sales INT DEFAULT 0,
    total_cash_in INT DEFAULT 0,
    total_cash_out INT DEFAULT 0,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    is_open BOOLEAN DEFAULT TRUE
);

CREATE TYPE cash_movement_type AS ENUM ('cash_in', 'cash_out');

CREATE TABLE IF NOT EXISTS cash_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id VARCHAR(100) NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
    type cash_movement_type NOT NULL,
    amount INT NOT NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by_name VARCHAR(100) NOT NULL
);

-- 6. TABEL PESANAN & TRANSAKSI (FR-POS & FR-PAY)
CREATE TYPE order_type AS ENUM ('dine_in', 'takeaway', 'delivery');
CREATE TYPE order_status AS ENUM ('active', 'held', 'completed', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'qris', 'debit', 'split');

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY, -- Dibuat di client (UUID v4) untuk idempotensi offline-first
    queue_number INT NOT NULL,
    outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
    shift_id VARCHAR(100) REFERENCES shifts(id) ON DELETE SET NULL,
    order_type order_type NOT NULL DEFAULT 'dine_in',
    table_number VARCHAR(50),
    customer_name VARCHAR(100),
    delivery_address TEXT,
    subtotal INT NOT NULL,
    discount_amount INT DEFAULT 0,
    discount_reason VARCHAR(200),
    tax_amount INT DEFAULT 0,
    service_charge_amount INT DEFAULT 0,
    total INT NOT NULL,
    payment_method payment_method NOT NULL,
    amount_tendered INT DEFAULT 0,
    change_due INT DEFAULT 0,
    payment_reference VARCHAR(150),
    cashier_id UUID REFERENCES users(id),
    cashier_name VARCHAR(100) NOT NULL,
    status order_status NOT NULL DEFAULT 'completed',
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. TABEL ITEM PESANAN DENGAN SNAPSHOT DATA (Catatan PRD Bab 10)
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id VARCHAR(50) NOT NULL,
    product_name_snapshot VARCHAR(150) NOT NULL,
    variant_name_snapshot VARCHAR(100),
    unit_price_snapshot INT NOT NULL,
    quantity INT NOT NULL,
    total_price INT NOT NULL,
    note TEXT
);

CREATE TABLE IF NOT EXISTS order_item_modifiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    option_id VARCHAR(50) NOT NULL,
    name_snapshot VARCHAR(100) NOT NULL,
    price_snapshot INT NOT NULL
);

-- 8. TABEL OUTBOX & AUDIT LOGS (FR-SYNC & NON-FUNCTIONAL)
CREATE TABLE IF NOT EXISTS outbox_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    attempts INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    synced_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(50) NOT NULL,
    entity VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id),
    old_value JSONB,
    new_value JSONB,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. INDEXES UNTUK PERFORMA QUERY
CREATE INDEX IF NOT EXISTS idx_orders_outlet_created ON orders(outlet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_shifts_outlet_open ON shifts(outlet_id, is_open);

-- 10. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE outlets ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policy isolasi: Kasir & Staf hanya dapat mengakses data outlet mereka
CREATE POLICY "Users can access data of their own outlet" ON orders
    FOR ALL USING (
        outlet_id IN (SELECT outlet_id FROM users WHERE id = auth.uid())
    );
