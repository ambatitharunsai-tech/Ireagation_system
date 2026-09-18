-- FARMS
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    location TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    area DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their farms" ON farms FOR ALL USING (auth.uid() = user_id);

-- FIELDS
CREATE TABLE IF NOT EXISTS fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    area DOUBLE PRECISION,
    soil_type TEXT,
    crop_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE fields ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage fields via farm ownership" ON fields FOR ALL 
USING (EXISTS (SELECT 1 FROM farms WHERE farms.id = fields.farm_id AND farms.user_id = auth.uid()));

-- CROPS
CREATE TABLE IF NOT EXISTS crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    variety TEXT,
    area DOUBLE PRECISION,
    sowing_date TEXT,
    expected_harvest_date TEXT,
    growth_stage TEXT,
    status TEXT NOT NULL DEFAULT 'Active',
    irrigation_method TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE crops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their crops" ON crops FOR ALL USING (auth.uid() = user_id);

-- TASKS
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    date TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'Medium',
    status TEXT NOT NULL DEFAULT 'Pending',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their tasks" ON tasks FOR ALL USING (auth.uid() = user_id);

-- EXPENSES
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    category TEXT NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their expenses" ON expenses FOR ALL USING (auth.uid() = user_id);

-- SALES
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    price DOUBLE PRECISION NOT NULL DEFAULT 0,
    buyer TEXT,
    date TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their sales" ON sales FOR ALL USING (auth.uid() = user_id);

-- INDEXES
CREATE INDEX idx_farms_user_id ON farms(user_id);
CREATE INDEX idx_fields_farm_id ON fields(farm_id);
CREATE INDEX idx_crops_user_id ON crops(user_id);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_expenses_user_id ON expenses(user_id);
CREATE INDEX idx_sales_user_id ON sales(user_id);
