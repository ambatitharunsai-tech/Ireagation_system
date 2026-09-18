-- ============================================================
-- Smart Agriculture App - Supabase Database Schema
-- ============================================================
-- Run this entire script in your Supabase SQL Editor:
--   https://supabase.com/dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROFILES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL DEFAULT 'Farmer',
    email TEXT,
    farm_name TEXT,
    location TEXT,
    language TEXT DEFAULT 'en',
    farm_size DOUBLE PRECISION,
    soil_type TEXT,
    profile_pic TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. CROPS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Active',
    growth_stage TEXT,
    sowing_date TEXT,
    expected_harvest_date TEXT,
    area DOUBLE PRECISION,
    soil_type TEXT,
    irrigation_method TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. TASKS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    crop_id UUID,
    title TEXT NOT NULL,
    date TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'Medium',
    status TEXT NOT NULL DEFAULT 'Pending',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. EXPENSES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    crop_id UUID,
    category TEXT NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. SALES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    crop_id UUID,
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    price DOUBLE PRECISION NOT NULL DEFAULT 0,
    buyer TEXT,
    date TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DISABLE RLS FOR DEMO MODE
-- (In production, you would enable RLS and add policies)
-- ============================================================
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE crops DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- INSERT DEMO USER PROFILE
-- ============================================================
INSERT INTO profiles (id, name, email, farm_name, location, farm_size, soil_type)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Demo Farmer',
    'demo@smartagri.com',
    'Green Valley Farm',
    'Karnataka, India',
    12.5,
    'Alluvial'
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- INSERT SAMPLE DATA (so dashboard isn't empty on first load)
-- ============================================================

-- Sample Crops
INSERT INTO crops (user_id, name, status, growth_stage, sowing_date, area, irrigation_method) VALUES
('00000000-0000-0000-0000-000000000000', 'Wheat', 'Active', 'Vegetative', '2026-06-15', 5.0, 'Drip'),
('00000000-0000-0000-0000-000000000000', 'Rice', 'Active', 'Flowering', '2026-05-01', 3.5, 'Flood'),
('00000000-0000-0000-0000-000000000000', 'Tomato', 'Active', 'Fruiting', '2026-07-10', 1.2, 'Drip'),
('00000000-0000-0000-0000-000000000000', 'Sugarcane', 'Active', 'Vegetative', '2026-04-20', 2.8, 'Furrow')
ON CONFLICT DO NOTHING;

-- Sample Tasks
INSERT INTO tasks (user_id, title, date, priority, status) VALUES
('00000000-0000-0000-0000-000000000000', 'Apply urea fertilizer to wheat', '2026-09-18', 'High', 'Pending'),
('00000000-0000-0000-0000-000000000000', 'Check drip irrigation lines', '2026-09-17', 'Medium', 'Pending'),
('00000000-0000-0000-0000-000000000000', 'Harvest ripe tomatoes', '2026-09-19', 'High', 'Pending'),
('00000000-0000-0000-0000-000000000000', 'Soil pH testing', '2026-09-20', 'Low', 'Pending')
ON CONFLICT DO NOTHING;

-- Sample Expenses
INSERT INTO expenses (user_id, category, amount, date) VALUES
('00000000-0000-0000-0000-000000000000', 'Seeds', 450.00, '2026-06-01'),
('00000000-0000-0000-0000-000000000000', 'Fertilizer', 320.00, '2026-07-15'),
('00000000-0000-0000-0000-000000000000', 'Labor', 800.00, '2026-08-01'),
('00000000-0000-0000-0000-000000000000', 'Equipment', 1200.00, '2026-06-10'),
('00000000-0000-0000-0000-000000000000', 'Irrigation', 250.00, '2026-07-20')
ON CONFLICT DO NOTHING;

-- Sample Sales
INSERT INTO sales (user_id, quantity, price, buyer, date) VALUES
('00000000-0000-0000-0000-000000000000', 200, 12.50, 'Local Market', '2026-08-25'),
('00000000-0000-0000-0000-000000000000', 150, 8.00, 'Wholesale Dealer', '2026-09-05')
ON CONFLICT DO NOTHING;

-- ============================================================
-- Done! Your database is ready for the Smart Agriculture app.
-- ============================================================
