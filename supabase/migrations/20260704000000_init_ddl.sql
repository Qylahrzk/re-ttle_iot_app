-- =============================================================================
-- RE:TTLE IOT RECYCLING SYSTEM - COMPLETE SUPABASE SCHEMA WITH RLS POLICIES
-- =============================================================================
-- Created: 2026-07-04
-- For: IoT Bottle Detection + Flutter Mobile App Integration
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE 1: PROFILES (Users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  matric_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  faculty TEXT,
  programme TEXT,
  semester TEXT,
  avatar_url TEXT,
  total_points INT DEFAULT 0,
  total_bottles INT DEFAULT 0,
  co2_saved_kg FLOAT DEFAULT 0,
  plastic_diverted_g FLOAT DEFAULT 0,
  streak_days INT DEFAULT 0,
  last_scan_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_matric ON profiles(matric_number);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- RLS Policy: Users can only see their own profile
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid()::text = id::text);

-- Service role can update all (for backend processing)
CREATE POLICY "Service role can update all profiles"
  ON profiles FOR UPDATE
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 2: BINS (Recycling Bin Configuration)
-- ============================================================================
CREATE TABLE IF NOT EXISTS bins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bin_id TEXT UNIQUE NOT NULL, -- "BIN_001", "BIN_002", etc.
  location TEXT NOT NULL, -- "Cafeteria", "Library", etc.
  latitude FLOAT,
  longitude FLOAT,
  capacity_liters INT DEFAULT 50,
  firmware_version TEXT DEFAULT '1.0.0',
  last_maintenance TIMESTAMP,
  status TEXT DEFAULT 'active', -- 'active', 'maintenance', 'offline'
  qr_code_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_bins_bin_id ON bins(bin_id);
CREATE INDEX IF NOT EXISTS idx_bins_status ON bins(status);

-- RLS Policy: Everyone can read bins, only service role can modify
ALTER TABLE bins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view bins"
  ON bins FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify bins"
  ON bins FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 3: BOTTLE DETECTIONS (IoT Data - ESP32 Posts Here)
-- ============================================================================
CREATE TABLE IF NOT EXISTS bottle_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  bin_id TEXT NOT NULL,
  weight_grams INT NOT NULL,
  ir_triggered BOOLEAN DEFAULT true,
  ultrasonic_level INT, -- Fill level percentage (0-100)
  detection_timestamp BIGINT, -- milliseconds from ESP32
  status TEXT DEFAULT 'logged', -- 'logged', 'duplicated_removed', 'validated'
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (bin_id) REFERENCES bins(bin_id) ON DELETE CASCADE
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_bottle_detections_user ON bottle_detections(user_id);
CREATE INDEX IF NOT EXISTS idx_bottle_detections_bin ON bottle_detections(bin_id);
CREATE INDEX IF NOT EXISTS idx_bottle_detections_created ON bottle_detections(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bottle_detections_timestamp ON bottle_detections(detection_timestamp);

-- RLS Policy: Users can view detections from their own scans
-- Service role (ESP32) can insert
ALTER TABLE bottle_detections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own detections"
  ON bottle_detections FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Service role can insert detections (ESP32)"
  ON bottle_detections FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.role() = 'authenticated');

-- Admins can view all
CREATE POLICY "Admins can view all detections"
  ON bottle_detections FOR SELECT
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 4: SCAN SESSIONS (Aggregated Recycling Sessions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS scan_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  bin_id TEXT NOT NULL,
  location TEXT, -- Denormalized from bins for quick access
  bottle_count INT NOT NULL,
  points_earned INT DEFAULT 0,
  co2_saved_kg FLOAT DEFAULT 0, -- (bottle_count * 0.25) kg per bottle
  plastic_diverted_g FLOAT DEFAULT 0,
  status TEXT DEFAULT 'completed', -- 'in_progress', 'completed', 'cancelled'
  session_duration_seconds INT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (bin_id) REFERENCES bins(bin_id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_scan_sessions_user ON scan_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_scan_sessions_bin ON scan_sessions(bin_id);
CREATE INDEX IF NOT EXISTS idx_scan_sessions_created ON scan_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_sessions_status ON scan_sessions(status);

-- RLS Policy
ALTER TABLE scan_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sessions"
  ON scan_sessions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create sessions"
  ON scan_sessions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own sessions"
  ON scan_sessions FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Service role can do all operations"
  ON scan_sessions FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 5: REWARDS (Reward Catalog)
-- ============================================================================
CREATE TABLE IF NOT EXISTS rewards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- 'Food', 'Campus', 'Transportation', 'Shopping', 'Eco Products', 'Lifestyle'
  points_required INT NOT NULL,
  stock INT DEFAULT 100,
  image_emoji TEXT, -- "☕", "🎬", "🍱", etc.
  featured BOOLEAN DEFAULT false,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_rewards_category ON rewards(category);
CREATE INDEX IF NOT EXISTS idx_rewards_featured ON rewards(featured);

-- RLS Policy: Everyone can read rewards
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view rewards"
  ON rewards FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify rewards"
  ON rewards FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 6: REDEMPTIONS (User Reward Redemptions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  reward_id UUID NOT NULL,
  points_spent INT NOT NULL,
  code TEXT UNIQUE, -- Redemption code sent to user
  status TEXT DEFAULT 'pending', -- 'pending', 'claimed', 'expired', 'cancelled'
  claimed_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (reward_id) REFERENCES rewards(id) ON DELETE RESTRICT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_redemptions_user ON redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_reward ON redemptions(reward_id);
CREATE INDEX IF NOT EXISTS idx_redemptions_code ON redemptions(code);
CREATE INDEX IF NOT EXISTS idx_redemptions_status ON redemptions(status);

-- RLS Policy
ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own redemptions"
  ON redemptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create redemptions"
  ON redemptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own redemptions"
  ON redemptions FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Service role can do all operations"
  ON redemptions FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 7: BIN STATUS (Real-time Bin Metrics)
-- ============================================================================
CREATE TABLE IF NOT EXISTS bin_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bin_id TEXT NOT NULL UNIQUE,
  fill_level_percent INT DEFAULT 0, -- 0-100
  total_bottles_today INT DEFAULT 0,
  total_sessions_today INT DEFAULT 0,
  last_detection TIMESTAMP,
  wifi_signal_strength INT DEFAULT 0, -- -100 to 0 dBm
  battery_level_percent INT DEFAULT 100,
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (bin_id) REFERENCES bins(bin_id) ON DELETE CASCADE
);

-- Index
CREATE INDEX IF NOT EXISTS idx_bin_status_bin_id ON bin_status(bin_id);

-- RLS Policy: Everyone can read, service role can update
ALTER TABLE bin_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view bin status"
  ON bin_status FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify bin status"
  ON bin_status FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 8: USER LEADERBOARD (Cached, Updated Daily)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_leaderboard (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE,
  matric_number TEXT,
  full_name TEXT,
  current_rank INT,
  total_points INT DEFAULT 0,
  total_bottles INT DEFAULT 0,
  co2_saved_kg FLOAT DEFAULT 0,
  streak_days INT DEFAULT 0,
  week_points INT DEFAULT 0, -- Points earned this week
  month_points INT DEFAULT 0, -- Points earned this month
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Index
CREATE INDEX IF NOT EXISTS idx_leaderboard_rank ON user_leaderboard(current_rank);
CREATE INDEX IF NOT EXISTS idx_leaderboard_points ON user_leaderboard(total_points DESC);

-- RLS Policy: Everyone can read leaderboard
ALTER TABLE user_leaderboard ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view leaderboard"
  ON user_leaderboard FOR SELECT
  USING (true);

CREATE POLICY "Only service role can modify leaderboard"
  ON user_leaderboard FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- TABLE 9: AUDIT LOG (Track All IoT Activity)
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL, -- 'bottle_detected', 'session_created', 'redemption', 'bin_alert'
  user_id UUID,
  bin_id TEXT,
  details JSONB, -- Flexible data storage
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);

-- RLS Policy: Only service role can access
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only service role can access audit logs"
  ON audit_logs FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update user points after scan session
CREATE OR REPLACE FUNCTION update_user_stats_after_scan()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET
    total_points = total_points + NEW.points_earned,
    total_bottles = total_bottles + NEW.bottle_count,
    co2_saved_kg = co2_saved_kg + COALESCE(NEW.co2_saved_kg, 0),
    last_scan_date = NOW()
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger when scan session is completed
CREATE TRIGGER trg_update_user_stats_after_scan
AFTER INSERT ON scan_sessions
FOR EACH ROW
WHEN (NEW.status = 'completed')
EXECUTE FUNCTION update_user_stats_after_scan();

-- Function to deduct points after redemption
CREATE OR REPLACE FUNCTION deduct_points_after_redemption()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET total_points = total_points - NEW.points_spent
  WHERE id = NEW.user_id AND total_points >= NEW.points_spent;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger when reward is redeemed
CREATE TRIGGER trg_deduct_points_after_redemption
AFTER INSERT ON redemptions
FOR EACH ROW
WHEN (NEW.status = 'pending')
EXECUTE FUNCTION deduct_points_after_redemption();

-- Function to update bin status after bottle detection
CREATE OR REPLACE FUNCTION update_bin_status_after_detection()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO bin_status (bin_id, total_bottles_today, last_detection)
  VALUES (NEW.bin_id, 1, NOW())
  ON CONFLICT (bin_id) DO UPDATE
  SET
    total_bottles_today = bin_status.total_bottles_today + 1,
    last_detection = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger when bottle is detected
CREATE TRIGGER trg_update_bin_status_after_detection
AFTER INSERT ON bottle_detections
FOR EACH ROW
EXECUTE FUNCTION update_bin_status_after_detection();

-- ============================================================================
-- SEED DATA (Optional - Insert Initial Data)
-- ============================================================================

-- Insert sample bins
INSERT INTO bins (bin_id, location, latitude, longitude, capacity_liters, status)
VALUES
  ('BIN_001', 'Main Cafeteria', 5.3520, 103.0411, 50, 'active'),
  ('BIN_002', 'Library Ground Floor', 5.3522, 103.0413, 50, 'active'),
  ('BIN_003', 'Student Campus', 5.3519, 103.0408, 50, 'active')
ON CONFLICT (bin_id) DO NOTHING;

-- Insert sample rewards
INSERT INTO rewards (title, description, category, points_required, stock, image_emoji, featured)
VALUES
  ('$5 Coffee Voucher', 'Redeem at any participating campus cafe.', 'Food', 500, 100, '☕', true),
  ('Printing Credit RM10', 'Free printing credit at campus print shop.', 'Campus', 300, 100, '🖨️', true),
  ('Grab Voucher RM15', 'Use on any Grab ride within Terengganu.', 'Transportation', 800, 100, '🚗', false),
  ('Campus Cafe Meal', 'A full meal at the student cafeteria.', 'Food', 600, 100, '🍱', true),
  ('Bookstore 20% Off', 'Discount at UiTM campus bookstore.', 'Shopping', 400, 100, '📚', false),
  ('Movie Ticket', 'TGV standard movie ticket.', 'Lifestyle', 1200, 100, '🎬', true),
  ('Reusable Bottle', 'Re:ttle branded eco-friendly bottle.', 'Eco Products', 1500, 50, '🍶', false),
  ('Plant a Tree', 'Donate to reforestation on your behalf.', 'Eco Products', 200, 100, '🌳', true)
ON CONFLICT DO NOTHING;
