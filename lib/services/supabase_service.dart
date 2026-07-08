import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../models/scan_session.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://rewxzeenlewxzbdnjras.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_17n_T8uGF8IxgS_Z9UpLsg_HF8qzeBY';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // Initialize service
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
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

  // Sign In with Google OAuth
  Future<void> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.rettle://login-callback',
      );
    } catch (e) {
      debugPrint('Error Google Sign In: $e');
      rethrow;
    }
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      debugPrint('Error resending confirmation: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PROFILE METHODS
  // ============================================================================

  String getGravatarUrl(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final bytes = utf8.encode(cleanEmail);
    final digest = md5.convert(bytes);
    return 'https://www.gravatar.com/avatar/$digest?s=200&d=identicon';
  }

  Future<Profile> _populateStatsForProfile(
    Map<String, dynamic> profileJson,
  ) async {
    final userId = profileJson['id'] as String;

    int dbPoints = -1;
    try {
      final pointsResponse = await client
          .from('user_points')
          .select('total_points')
          .eq('user_id', userId)
          .maybeSingle();
      if (pointsResponse != null) {
        dbPoints = pointsResponse['total_points'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching dbPoints for comparison: $e');
    }

    int totalBottles = 0;
    double co2SavedKg = 0.0;
    int plasticDivertedG = 0;
    String? lastScanDate;
    int streakDays = 0;
    int totalPointsEarned = 0;

    try {
      final sessionsResponse = await client
          .from('scan_sessions')
          .select(
            'bottle_count, co2_saved_kg, plastic_diverted_g, created_at, points_earned',
          )
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      if (sessionsResponse.isNotEmpty) {
        for (final session in sessionsResponse) {
          totalBottles += (session['bottle_count'] as num? ?? 0).toInt();
          co2SavedKg += (session['co2_saved_kg'] as num? ?? 0.0).toDouble();
          plasticDivertedG += (session['plastic_diverted_g'] as num? ?? 0.0)
              .round();
          totalPointsEarned += (session['points_earned'] as num? ?? 0).toInt();
        }

        final latestSession = sessionsResponse.first;
        lastScanDate = latestSession['created_at'] as String?;

        final dates = sessionsResponse
            .map((s) => s['created_at'] as String?)
            .whereType<String>()
            .map((s) => DateTime.parse(s).toLocal())
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList();

        dates.sort((a, b) => b.compareTo(a));

        if (dates.isNotEmpty) {
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);
          final yesterdayDate = todayDate.subtract(const Duration(days: 1));

          if (dates.first == todayDate || dates.first == yesterdayDate) {
            streakDays = 1;
            var current = dates.first;
            for (var i = 1; i < dates.length; i++) {
              final expected = current.subtract(const Duration(days: 1));
              if (dates[i] == expected) {
                streakDays++;
                current = dates[i];
              } else {
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching scan sessions for stats: $e');
    }

    int totalPointsSpent = 0;
    try {
      final redemptionsResponse = await client
          .from('redemptions')
          .select('points_spent')
          .eq('user_id', userId);
      for (final redemption in redemptionsResponse) {
        totalPointsSpent += (redemption['points_spent'] as num? ?? 0).toInt();
      }
    } catch (e) {
      debugPrint('Error fetching redemptions for stats: $e');
    }

    int totalPoints = totalPointsEarned - totalPointsSpent;
    if (totalPoints < 0) totalPoints = 0;

    // Sync calculated points back to user_points table in database only if different
    if (dbPoints != totalPoints) {
      try {
        await client.from('user_points').upsert({
          'user_id': userId,
          'total_points': totalPoints,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error syncing total points to user_points: $e');
      }
    }

    final fullJson = Map<String, dynamic>.from(profileJson);
    fullJson['total_points'] = totalPoints;
    fullJson['total_bottles'] = totalBottles;
    fullJson['co2_saved_kg'] = co2SavedKg;
    fullJson['plastic_diverted_g'] = plasticDivertedG;
    fullJson['streak_days'] = streakDays;
    fullJson['last_scan_date'] = lastScanDate;

    return Profile.fromJson(fullJson);
  }

  Future<void> _ensureUserPointsRow(String userId) async {
    try {
      final pointsResponse = await client
          .from('user_points')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (pointsResponse == null) {
        debugPrint(
          'user_points record missing for $userId, inserting default...',
        );
        await client.from('user_points').insert({
          'user_id': userId,
          'total_points': 0,
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user_points row: $e');
    }
  }

  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        await _ensureUserPointsRow(userId);
        return await _populateStatsForProfile(response);
      }

      // Profile does not exist, let's create a default profile row!
      final user = client.auth.currentUser;
      if (user != null) {
        final email = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        final fullName =
            metadata['full_name'] as String? ?? email.split('@').first;
        final matricNumber =
            metadata['matric_number'] as String? ?? '2023239326';

        final avatarUrl =
            metadata['avatar_url'] as String? ??
            metadata['picture'] as String? ??
            getGravatarUrl(email);

        final newProfileMap = {
          'id': userId,
          'email': email,
          'full_name': fullName,
          'matric_number': matricNumber,
          'avatar_url': avatarUrl,
        };

        await client.from('profiles').insert(newProfileMap);
        await _ensureUserPointsRow(userId);

        // Retrieve again
        final secondResponse = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        return await _populateStatsForProfile(secondResponse);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting or auto-creating profile: $e');
      return null;
    }
  }

  final StreamController<Profile?> _profileRefreshController =
      StreamController<Profile?>.broadcast();

  // Realtime Profile updates stream combined with manual refresh
  Stream<Profile?> streamProfile(String userId) {
    final controller = StreamController<Profile?>.broadcast();

    StreamSubscription? subProfiles;
    StreamSubscription? subPoints;
    StreamSubscription? subSessions;
    StreamSubscription? subRefresh;

    int currentSequence = 0;

    Future<void> triggerUpdate() async {
      final seq = ++currentSequence;
      try {
        // Wait a short delay to allow database triggers to complete and group rapid events
        await Future.delayed(const Duration(milliseconds: 200));
        if (seq != currentSequence) return;

        final profile = await getProfile(userId);
        if (seq == currentSequence && !controller.isClosed) {
          controller.add(profile);
        }
      } catch (e) {
        if (seq == currentSequence && !controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    subProfiles = client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((_) => triggerUpdate(), onError: controller.addError);

    subPoints = client
        .from('user_points')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((_) => triggerUpdate(), onError: controller.addError);

    subSessions = client
        .from('scan_sessions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((_) => triggerUpdate(), onError: controller.addError);

    subRefresh = _profileRefreshController.stream.listen((profile) {
      // Increment sequence to invalidate any running triggerUpdates
      currentSequence++;
      controller.add(profile);
    }, onError: controller.addError);

    controller.onCancel = () {
      subProfiles?.cancel();
      subPoints?.cancel();
      subSessions?.cancel();
      subRefresh?.cancel();
    };

    // Trigger initial fetch
    triggerUpdate();

    return controller.stream;
  }

  // Force a manual REST fetch and emit it instantly
  Future<Profile?> refreshProfile(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile != null) {
        _profileRefreshController.add(profile);
      }
      return profile;
    } catch (e) {
      debugPrint('Error manual refreshing profile: $e');
      return null;
    }
  }

  // Update Profile Name and Avatar
  Future<void> updateProfileNameAndAvatar(
    String userId,
    String newName,
    String newAvatar,
  ) async {
    try {
      await client
          .from('profiles')
          .update({
            'full_name': newName,
            'avatar_url': newAvatar.isEmpty ? null : newAvatar,
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating profile name and avatar: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BOTTLE DETECTION METHODS (IoT Integration)
  // ============================================================================

  /// Watch bottle detections in real-time (for current scan session)
  /// Shows count of bottles detected since scan started
  Stream<List<Map<String, dynamic>>> watchBottleDetections(
    String userId,
    String binId, {
    int sinceSeconds = 300, // Last 5 minutes
  }) {
    // Force UTC comparison
    final since = DateTime.now().toUtc().subtract(
      Duration(seconds: sinceSeconds),
    );

    return client
        .from('bottle_detections')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (detections) => detections.where((d) {
            final binMatch = d['bin_id'] == binId;
            final isValid = d['ir_triggered'] == true;
            final createdAtStr = d['created_at'] as String?;
            if (createdAtStr == null) return false;

            final createdAt = DateTime.parse(createdAtStr);
            return binMatch && isValid && createdAt.isAfter(since);
          }).toList(),
        );
  }

  /// Get bottle count for current session in real-time
  /// Useful for display: "3 bottles detected"
  Stream<int> watchBottleCountSince(
    String userId,
    String binId,
    DateTime sessionStart,
  ) {
    final since = sessionStart.toUtc();

    return client
        .from('bottle_detections')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (detections) => detections.where((d) {
            final binMatch = d['bin_id'] == binId;
            final isValid = d['ir_triggered'] == true;
            final createdAtStr = d['created_at'] as String?;
            if (createdAtStr == null) return false;

            final createdAt = DateTime.parse(createdAtStr);
            return binMatch && isValid && createdAt.isAfter(since);
          }).length,
        );
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
      debugPrint('Error fetching bottle detection history: $e');
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
      debugPrint('Error logging bottle detection: $e');
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
      debugPrint('Error fetching bin status: $e');
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
      debugPrint('Error fetching recent activities: $e');
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
      debugPrint('Error fetching filtered activities: $e');
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
        .map(
          (maps) =>
              (maps as List).map((json) => ScanSession.fromJson(json)).toList(),
        );
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
    double? plasticDivertedG,
  }) async {
    try {
      await client.from('scan_sessions').insert({
        'user_id': userId,
        'bin_id': binId,
        'location': location,
        'bottle_count': bottleCount,
        'points_earned': pointsEarned,
        'co2_saved_kg': co2Saved,
        'plastic_diverted_g': plasticDivertedG ?? (bottleCount * 25.0),
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error inserting scan session: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BIN SESSION METHODS
  // ============================================================================

  Future<void> createBinSession({
    required String userId,
    required String binId,
  }) async {
    try {
      // Close any existing active session for this user/bin
      await client
          .from('bin_sessions')
          .update({
            'is_active': false,
            'session_end': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('bin_id', binId)
          .eq('is_active', true);

      // Create new active session
      await client.from('bin_sessions').insert({
        'user_id': userId,
        'bin_id': binId,
        'is_active': true,
        'session_start': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('Active bin session created.');
    } catch (e) {
      debugPrint('Error creating bin session: $e');
      rethrow;
    }
  }

  Future<void> closeBinSession({
    required String userId,
    required String binId,
  }) async {
    try {
      await client
          .from('bin_sessions')
          .update({
            'is_active': false,
            'session_end': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('bin_id', binId)
          .eq('is_active', true);

      debugPrint('Bin session closed.');
    } catch (e) {
      debugPrint('Error closing session: $e');
      rethrow;
    }
  }

  Future<void> startBinSession({required String binId}) async {
    debugPrint("========== SESSION DEBUG ==========");
    debugPrint("Current User : ${currentUser?.id}");
    debugPrint("Email        : ${currentUser?.email}");
    debugPrint("Bin ID       : $binId");
    debugPrint("===================================");

    await client.from('bin_sessions').insert({
      'bin_id': binId,
      'is_active': true,
    });
  }

  Future<void> endBinSession({
    required String binId,
    required int bottleCount,
  }) async {
    final userId = currentUser!.id;

    await client
        .from('bin_sessions')
        .update({
          'is_active': false,
          'session_end': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('bin_id', binId)
        .eq('is_active', true);

    await insertScanSession(
      userId: userId,
      binId: binId,
      location: 'UiTM Shah Alam · Block A',
      bottleCount: bottleCount,
      pointsEarned: bottleCount * 10,
      co2Saved: bottleCount * 0.2,
      plasticDivertedG: bottleCount * 25.0,
    );
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
      debugPrint('Error fetching rewards: $e');
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
        .map(
          (maps) =>
              (maps as List).map((json) => Reward.fromJson(json)).toList(),
        );
  }

  // ============================================================================
  // LEADERBOARD METHODS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 20}) async {
    try {
      final response = await client
          .from('profiles')
          .select('id, full_name, avatar_url, user_points(total_points)')
          .order(
            'total_points',
            referencedTable: 'user_points',
            ascending: false,
          )
          .limit(limit);

      final list = List<Map<String, dynamic>>.from(response);
      return list.map((p) {
        final ptsMap = p['user_points'] as Map<String, dynamic>?;
        final totalPoints = ptsMap != null
            ? (ptsMap['total_points'] as int? ?? 0)
            : 0;
        return {
          'id': p['id'],
          'full_name': p['full_name'],
          'avatar_url': p['avatar_url'],
          'total_points': totalPoints,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Stream leaderboard in real-time (top 20 users by points)
  Stream<List<Map<String, dynamic>>> streamLeaderboard({int limit = 20}) {
    return client
        .from('user_points')
        .stream(primaryKey: ['id'])
        .order('total_points', ascending: false)
        .limit(limit)
        .asyncMap((pointsList) async {
          final userIds = pointsList
              .map((p) => p['user_id'] as String)
              .toList();
          if (userIds.isEmpty) return [];

          try {
            final profilesResponse = await client
                .from('profiles')
                .select('id, full_name, avatar_url')
                .inFilter('id', userIds);

            final profilesMap = {
              for (var p in profilesResponse) p['id'] as String: p,
            };

            return pointsList.map((pointRow) {
              final userId = pointRow['user_id'] as String;
              final profile = profilesMap[userId];
              return {
                'id': userId,
                'full_name': profile?['full_name'] ?? 'User',
                'avatar_url': profile?['avatar_url'],
                'total_points': pointRow['total_points'] as int? ?? 0,
              };
            }).toList();
          } catch (e) {
            debugPrint('Error in streamLeaderboard mapping: $e');
            return [];
          }
        });
  }

  // ============================================================================
  // REDEMPTION METHODS
  // ============================================================================

  String _generateVoucherCode() {
    final random = math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'RET-$code';
  }

  /// Redeem a reward (deducts points from user)
  /// The trigger will automatically deduct points from user's total_points
  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsSpent,
  }) async {
    try {
      final code = _generateVoucherCode();
      await client.from('redemptions').insert({
        'user_id': userId,
        'reward_id': rewardId,
        'points_spent': pointsSpent,
        'status': 'pending',
        'code': code,
        'voucher_code': code,
      });
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
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
      debugPrint('Error fetching vouchers: $e');
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
        .map(
          (maps) => (maps as List)
              .map((json) => Map<String, dynamic>.from(json))
              .toList(),
        );
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
      debugPrint('Error fetching pending vouchers: $e');
      return [];
    }
  }

  // ============================================================================
  // DEBUG HELPER METHODS
  // ============================================================================

  /// Test connection to Supabase
  Future<bool> testConnection() async {
    try {
      await client.from('bins').select().limit(1);
      return true;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // For testing WITHOUT ESP32
  Future<void> logTestBottleDetection(String userId, String binId) async {
    await logBottleDetection(
      userId: userId,
      binId: binId.isEmpty ? 'BIN_001' : binId,
      weightGrams: 450 + math.Random().nextInt(200),
    );
  }
}
