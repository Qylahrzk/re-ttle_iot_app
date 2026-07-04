import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../models/scan_session.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://rewxzeenlewxzbdnjras.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJld3h6ZWVubGV3eHpiZG5qcmFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDEzNjAsImV4cCI6MjA5ODcxNzM2MH0.-2eka0oj1DOpxKed9UpPeP2cyCJ4dqrk6pMFootpHw0';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // Initialize service
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Auth getters
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String matricNumber,
    required String fullName,
  }) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: {'matric_number': matricNumber, 'full_name': fullName},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================================================
  // PROFILE METHODS
  // ============================================================================

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // Realtime Profile updates stream
  Stream<Profile?> streamProfile(String userId) {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((maps) => maps.isNotEmpty ? Profile.fromJson(maps.first) : null);
  }

  // ============================================================================
  // BOTTLE DETECTION METHODS (IoT Integration)
  // ============================================================================

  /// Watch bottle detections in real-time (for current scan session)
  /// Shows count of bottles detected since scan started
  Stream<List<Map<String, dynamic>>> watchBottleDetections(
    String userId,
    String binId, {
    int sinceSeconds = 300, -- Last 5 minutes
  }) {
    final since = DateTime.now().subtract(Duration(seconds: sinceSeconds));
    
    return client
        .from('bottle_detections')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('bin_id', binId)
        .gte('created_at', since.toUtc().toIso8601String())
        .order('created_at', ascending: false);
  }

  /// Get bottle count for current session in real-time
  /// Useful for display: "3 bottles detected"
  Stream<int> watchBottleCountForSession(
    String userId,
    String binId, {
    int sinceSeconds = 300,
  }) {
    final since = DateTime.now().subtract(Duration(seconds: sinceSeconds));
    
    return client
        .from('bottle_detections')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('bin_id', binId)
        .gte('created_at', since.toUtc().toIso8601String())
        .map((detections) => detections.length);
  }

  /// Get all bottle detections for a user (historical)
  Future<List<Map<String, dynamic>>> getBottleDetectionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('bottle_detections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching bottle detection history: $e');
      return [];
    }
  }

  /// Log a bottle detection (called by ESP32 or Flutter when in test mode)
  /// This inserts a row into bottle_detections table
  Future<void> logBottleDetection({
    required String userId,
    required String binId,
    required int weightGrams,
    int? ultrasonicLevel,
  }) async {
    try {
      await client.from('bottle_detections').insert({
        'user_id': userId,
        'bin_id': binId,
        'weight_grams': weightGrams,
        'ultrasonic_level': ultrasonicLevel ?? 0,
        'ir_triggered': true,
        'detection_timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'logged',
      });
    } catch (e) {
      print('Error logging bottle detection: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BIN STATUS METHODS
  // ============================================================================

  /// Watch bin status in real-time (fill level, last detection, etc)
  Stream<Map<String, dynamic>?> watchBinStatus(String binId) {
    return client
        .from('bin_status')
        .stream(primaryKey: ['bin_id'])
        .eq('bin_id', binId)
        .map((maps) => maps.isNotEmpty ? maps.first : null);
  }

  /// Get current bin status
  Future<Map<String, dynamic>?> getBinStatus(String binId) async {
    try {
      final response = await client
          .from('bin_status')
          .select()
          .eq('bin_id', binId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching bin status: $e');
      return null;
    }
  }

  // ============================================================================
  // SCAN SESSION METHODS
  // ============================================================================

  Future<List<ScanSession>> getRecentActivities(
    String userId, {
    int limit = 3,
  }) async {
    try {
      final response = await client
          .from('scan_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => ScanSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  Future<List<ScanSession>> getActivitiesInTimeframe(
    String userId,
    DateTime since,
  ) async {
    try {
      final response = await client
          .from('scan_sessions')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since.toUtc().toIso8601String())
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ScanSession.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching filtered activities: $e');
      return [];
    }
  }

  /// Stream scan sessions in real-time (watch for new sessions)
  Stream<List<ScanSession>> streamScanSessions(String userId) {
    return client
        .from('scan_sessions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((maps) => (maps as List)
            .map((json) => ScanSession.fromJson(json))
            .toList());
  }

  /// Insert scan session (Simulates the end of the IoT process)
  /// This should be called AFTER all bottles have been detected
  /// The trigger will automatically update user's total_points and total_bottles
  Future<void> insertScanSession({
    required String userId,
    required String binId,
    required String location,
    required int bottleCount,
    required int pointsEarned,
    required double co2Saved,
  }) async {
    try {
      await client.from('scan_sessions').insert({
        'user_id': userId,
        'bin_id': binId,
        'location': location,
        'bottle_count': bottleCount,
        'points_earned': pointsEarned,
        'co2_saved_kg': co2Saved,
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('Error inserting scan session: $e');
      rethrow;
    }
  }

  // ============================================================================
  // REWARDS METHODS
  // ============================================================================

  Future<List<Reward>> getRewards() async {
    try {
      final response = await client
          .from('rewards')
          .select()
          .order('featured', ascending: false)
          .order('points_required', ascending: true);
      return (response as List).map((json) => Reward.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching rewards: $e');
      return [];
    }
  }

  /// Stream rewards in real-time (for live updates)
  Stream<List<Reward>> streamRewards() {
    return client
        .from('rewards')
        .stream(primaryKey: ['id'])
        .order('featured', ascending: false)
        .order('points_required', ascending: true)
        .map((maps) => (maps as List)
            .map((json) => Reward.fromJson(json))
            .toList());
  }

  // ============================================================================
  // LEADERBOARD METHODS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    try {
      final response = await client
          .from('profiles')
          .select('id, full_name, total_points, avatar_url')
          .order('total_points', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Stream leaderboard in real-time (top 20 users by points)
  Stream<List<Map<String, dynamic>>> streamLeaderboard({int limit = 20}) {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('total_points', ascending: false)
        .limit(limit)
        .map((maps) => (maps as List)
            .map((json) => Map<String, dynamic>.from(json))
            .toList());
  }

  // ============================================================================
  // REDEMPTION METHODS
  // ============================================================================

  /// Redeem a reward (deducts points from user)
  /// The trigger will automatically deduct points from user's total_points
  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsSpent,
  }) async {
    try {
      await client.from('redemptions').insert({
        'user_id': userId,
        'reward_id': rewardId,
        'points_spent': pointsSpent,
        'status': 'pending',
      });
    } catch (e) {
      print('Error redeeming reward: $e');
      rethrow;
    }
  }

  /// Fetch redemptions (Vouchers redeemed by user)
  Future<List<Map<String, dynamic>>> getUserVouchers(String userId) async {
    try {
      final response = await client
          .from('redemptions')
          .select('*, rewards(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  /// Stream user redemptions in real-time
  Stream<List<Map<String, dynamic>>> streamUserVouchers(String userId) {
    return client
        .from('redemptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((maps) => (maps as List)
            .map((json) => Map<String, dynamic>.from(json))
            .toList());
  }

  /// Get user's pending redemptions (unclaimed vouchers)
  Future<List<Map<String, dynamic>>> getPendingVouchers(String userId) async {
    try {
      final response = await client
          .from('redemptions')
          .select('*, rewards(*)')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pending vouchers: $e');
      return [];
    }
  }

  // ============================================================================
  // DEBUG HELPER METHODS
  // ============================================================================

  /// Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      final response = await client.from('bins').select().limit(1);
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Clear test data (for development only)
  Future<void> clearTestBottleDetections(String userId, String binId) async {
    try {
      if (currentUser?.email?.contains('test') ?? false) {
        await client
            .from('bottle_detections')
            .delete()
            .eq('user_id', userId)
            .eq('bin_id', binId);
        print('Test bottle detections cleared');
      } else {
        print('Cannot clear: not a test user');
      }
    } catch (e) {
      print('Error clearing test data: $e');
    }
  }
}
