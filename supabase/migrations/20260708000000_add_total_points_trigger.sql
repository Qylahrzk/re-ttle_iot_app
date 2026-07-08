-- =============================================================================
-- RE:TTLE IOT RECYCLING SYSTEM - DATABASE SCHEMA ADJUSTMENTS & TRIGGERS
-- =============================================================================
-- Description: 
-- 1. Ensures public.bin_status table exists in the database.
-- 2. Adds total_points_after_detection & points_awarded to bottle_detections.
-- 3. Adds voucher_code to redemptions.
-- 4. Sets up a BEFORE INSERT trigger on bottle_detections to automatically
--    populate points snapshot columns when logged via ESP32/IoT (when NULL).
-- 5. Drop and recreate supabase_realtime publication to enable Realtime streams
--    on all required tables and fix Stream error RealtimeSubscribeException.
-- 6. Reloads the PostgREST schema cache to resolve PGRST204 errors immediately.
-- =============================================================================

-- 1. Ensure bin_status table exists
CREATE TABLE IF NOT EXISTS public.bin_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bin_id TEXT NOT NULL UNIQUE,
  fill_level_percent INT DEFAULT 0,
  total_bottles_today INT DEFAULT 0,
  total_sessions_today INT DEFAULT 0,
  last_detection TIMESTAMP,
  wifi_signal_strength INT DEFAULT 0,
  battery_level_percent INT DEFAULT 100,
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (bin_id) REFERENCES public.bins(bin_id) ON DELETE CASCADE
);

-- 2. Ensure bottle_detections columns exist
ALTER TABLE public.bottle_detections 
ADD COLUMN IF NOT EXISTS total_points_after_detection INTEGER,
ADD COLUMN IF NOT EXISTS points_awarded INTEGER;

-- 3. Ensure redemptions columns exist
ALTER TABLE public.redemptions 
ADD COLUMN IF NOT EXISTS voucher_code TEXT;

-- 4. Create/update the trigger function to compute the points snapshot automatically when NULL
CREATE OR REPLACE FUNCTION set_total_points_after_detection()
RETURNS TRIGGER AS $$
DECLARE
  v_current_points INTEGER;
  v_session_start TIMESTAMP;
  v_session_bottle_count INTEGER;
BEGIN
  -- Default points_awarded to 10 if not provided
  IF NEW.points_awarded IS NULL THEN
    NEW.points_awarded := 10;
  END IF;

  -- Calculate total_points_after_detection if not provided
  IF NEW.total_points_after_detection IS NULL THEN
    -- Get user's current points from user_points table (or fallback to profiles if empty)
    SELECT total_points INTO v_current_points
    FROM public.user_points
    WHERE user_id = NEW.user_id;

    IF v_current_points IS NULL THEN
      SELECT total_points INTO v_current_points
      FROM public.profiles
      WHERE id = NEW.user_id;
    END IF;

    -- Get the start time of the current active session
    SELECT session_start INTO v_session_start
    FROM public.bin_sessions
    WHERE user_id = NEW.user_id AND bin_id = NEW.bin_id AND is_active = true
    ORDER BY session_start DESC
    LIMIT 1;

    -- If there's no active session, default to NOW() - INTERVAL '5 minutes'
    IF v_session_start IS NULL THEN
      v_session_start := NOW() - INTERVAL '5 minutes';
    END IF;

    -- Count previous valid detections in this session (excluding this new insert)
    SELECT COUNT(*) INTO v_session_bottle_count
    FROM public.bottle_detections
    WHERE user_id = NEW.user_id 
      AND bin_id = NEW.bin_id 
      AND ir_triggered = true
      AND created_at >= v_session_start;

    -- Set total points after this detection (including this one's points)
    NEW.total_points_after_detection := COALESCE(v_current_points, 0) + (v_session_bottle_count * 10) + NEW.points_awarded;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create BEFORE INSERT trigger on bottle_detections
DROP TRIGGER IF EXISTS trg_set_total_points_after_detection ON public.bottle_detections;
CREATE TRIGGER trg_set_total_points_after_detection
BEFORE INSERT ON public.bottle_detections
FOR EACH ROW
EXECUTE FUNCTION set_total_points_after_detection();

-- 6. Drop and recreate publication to enable Realtime for all tables
-- This fixes RealtimeSubscribeException channelError on the client
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE 
  public.profiles,
  public.user_points,
  public.scan_sessions,
  public.bottle_detections,
  public.bin_status,
  public.rewards,
  public.redemptions;

-- 7. Reload PostgREST schema cache to ensure new/altered columns are cached
NOTIFY pgrst, 'reload schema';
