-- IOT DEVICES
CREATE TABLE IF NOT EXISTS iot_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    device_identifier TEXT UNIQUE NOT NULL,
    is_online BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT false,
    last_reading DOUBLE PRECISION,
    unit TEXT,
    last_seen TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE iot_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their IoT devices" ON iot_devices FOR ALL USING (auth.uid() = user_id);

-- SENSOR READINGS
CREATE TABLE IF NOT EXISTS sensor_readings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES iot_devices(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    value DOUBLE PRECISION NOT NULL,
    unit TEXT,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their sensor readings" ON sensor_readings FOR ALL USING (auth.uid() = user_id);

-- INDEXES
CREATE INDEX idx_iot_devices_user_id ON iot_devices(user_id);
CREATE INDEX idx_sensor_readings_device_id ON sensor_readings(device_id);
CREATE INDEX idx_sensor_readings_recorded_at ON sensor_readings(recorded_at);
