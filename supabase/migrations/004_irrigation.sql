-- IRRIGATION ZONES
CREATE TABLE IF NOT EXISTS irrigation_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    field_id UUID REFERENCES fields(id) ON DELETE SET NULL,
    pump_device_id TEXT,
    valve_device_id TEXT,
    moisture_threshold_min DOUBLE PRECISION DEFAULT 30,
    moisture_threshold_max DOUBLE PRECISION DEFAULT 80,
    daily_water_limit DOUBLE PRECISION,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE irrigation_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage irrigation zones via farm ownership" ON irrigation_zones FOR ALL 
USING (EXISTS (SELECT 1 FROM farms WHERE farms.id = irrigation_zones.farm_id AND farms.user_id = auth.uid()));
