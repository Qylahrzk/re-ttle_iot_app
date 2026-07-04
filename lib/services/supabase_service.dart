import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../models/scan_session.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://lmvhgqzgvcpxdeqvstvd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxtdmhncXpndmNweGRlcXZzdHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0OTg2ODAsImV4cCI6MjA5NzA3NDY4MH0.yLd_jgngqrIbVQBhTLrBnpUm9C0wesUXlNtFlHbVhYY';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // Initialize service
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Auth getters
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Sign In
  Future<AuthResponse> signIn({required String email, required String password}) async {
    try {
      return await client.auth.signInWithPassword(email: email, password: password);
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
        data: {
          'matric_number': matricNumber,
          'full_name': fullName,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Profile methods
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

  // Scan Sessions (Activities)
  Future<List<ScanSession>> getRecentActivities(String userId, {int limit = 3}) async {
    try {
      final response = await client
          .from('scan_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((json) => ScanSession.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  Future<List<ScanSession>> getActivitiesInTimeframe(String userId, DateTime since) async {
    try {
      final response = await client
          .from('scan_sessions')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since.toUtc().toIso8601String())
          .order('created_at', ascending: false);
      return (response as List).map((json) => ScanSession.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching filtered activities: $e');
      return [];
    }
  }

  // Insert scan session (Simulates the end of the IoT process)
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
      });
    } catch (e) {
      rethrow;
    }
  }

  // Rewards methods
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

  // Leaderboard methods
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

  // Redeem Reward
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
      });
    } catch (e) {
      rethrow;
    }
  }

  // Fetch redemptions (Vouchers redeemed by user)
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
}
