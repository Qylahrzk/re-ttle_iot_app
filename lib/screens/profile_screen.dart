import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Profile? profile;
  const ProfileScreen({super.key, this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String _activeTab = 'profile';

  List<Map<String, dynamic>> _leaderboard = [];
  bool _loadingLeaderboard = false;

  final List<Map<String, dynamic>> _achievements = [
    {'id': 'eco-starter', 'title': 'Eco Starter', 'emoji': '🌱', 'threshold': 1, 'type': 'bottles'},
    {'id': 'streak', 'title': '7-Day Streak', 'emoji': '🔥', 'threshold': 7, 'type': 'streak'},
    {'id': 'ocean', 'title': 'Ocean Saver', 'emoji': '🌊', 'threshold': 25, 'type': 'bottles'},
    {'id': 'hero', 'title': 'Bottle Hero', 'emoji': '🦸', 'threshold': 50, 'type': 'bottles'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile?.totalPoints != oldWidget.profile?.totalPoints) {
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final data = await _supabaseService.getLeaderboard(limit: 20);
      if (mounted) {
        setState(() {
          _leaderboard = data;
        });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _signOut() async {
    await _supabaseService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  int _getMyRank() {
    if (widget.profile == null) return -1;
    final index = _leaderboard.indexWhere((p) => p['id'] == widget.profile!.id);
    return index != -1 ? index + 1 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initials = widget.profile?.fullName != null && widget.profile!.fullName!.trim().isNotEmpty
        ? widget.profile!.fullName!
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => word[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'ME';

    final myRank = _getMyRank();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _activeTab == 'profile' ? 'Profile' : 'Leaderboard',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? AppTheme.textLight : AppTheme.primaryDark,
                      fontSize: 24,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardBgDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                      boxShadow: AppTheme.shadowCard,
                    ),
                    child: Icon(
                      _activeTab == 'profile' ? LucideIcons.settings : LucideIcons.share2,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.borderLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 'profile'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 'profile'
                                ? (isDark ? AppTheme.bgDark : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: _activeTab == 'profile' ? AppTheme.shadowCard : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 'profile'
                                    ? (isDark ? AppTheme.accentLime : AppTheme.primaryDark)
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 'leaderboard'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 'leaderboard'
                                ? (isDark ? AppTheme.bgDark : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: _activeTab == 'leaderboard' ? AppTheme.shadowCard : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 'leaderboard'
                                    ? (isDark ? AppTheme.accentLime : AppTheme.primaryDark)
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: _activeTab == 'profile'
                    ? _buildProfileTab(initials, myRank, isDark, theme)
                    : _buildLeaderboardTab(isDark, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(String initials, int myRank, bool isDark, ThemeData theme) {
    final profile = widget.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User Main Card
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
            boxShadow: AppTheme.shadowCard,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  if (profile?.avatarUrl != null)
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: NetworkImage(profile!.avatarUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.mintColor,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.accentLime : AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.crown,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile?.fullName ?? 'Student',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.matricNumber ?? profile?.email ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                profile?.faculty ?? 'UiTM Faculty',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              Text(
                profile?.programme ?? 'UiTM Course',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Statistics Sub-Row
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.bgDark
                      : AppTheme.mintColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildProfileStat('Points', '${profile?.totalPoints ?? 0}')),
                    Container(width: 1, height: 24, color: AppTheme.borderLight.withOpacity(0.5)),
                    Expanded(child: _buildProfileStat('Bottles', '${profile?.totalBottles ?? 0}')),
                    Container(width: 1, height: 24, color: AppTheme.borderLight.withOpacity(0.5)),
                    Expanded(child: _buildProfileStat('Rank', myRank > 0 ? '#$myRank' : '—')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Achievements Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Achievements Grid (4 column layouts)
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: _achievements.map((ach) {
            final type = ach['type'];
            final threshold = ach['threshold'] as int;
            final userVal = type == 'streak' ? (profile?.streakDays ?? 0) : (profile?.totalBottles ?? 0);
            final unlocked = userVal >= threshold;

            return Opacity(
              opacity: unlocked ? 1.0 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  boxShadow: AppTheme.shadowCard,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ach['emoji'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ach['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // List menu options
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
            boxShadow: AppTheme.shadowCard,
          ),
          child: Column(
            children: [
              _buildMenuRow(LucideIcons.history, 'Recycling History', () {}),
              const Divider(height: 1),
              _buildMenuRow(LucideIcons.ticket, 'My Vouchers', () {}),
              const Divider(height: 1),
              _buildMenuRow(LucideIcons.award, 'Achievements', () {}),
              const Divider(height: 1),
              _buildMenuRow(LucideIcons.helpCircle, 'Help & Support', () {}),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Logout
        ElevatedButton.icon(
          onPressed: _signOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
            foregroundColor: AppTheme.destructiveColor,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(LucideIcons.logOut, size: 16),
          label: const Text(
            'Sign out',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab(bool isDark, ThemeData theme) {
    if (_loadingLeaderboard && _leaderboard.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final podium = _leaderboard.take(3).toList();
    final rest = _leaderboard.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekly Title Card
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
            boxShadow: AppTheme.shadowCard,
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.accentLime.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.trophy, color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Eco Hero of the Week',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.accentLime : AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (podium.isNotEmpty) ...[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: const Text('🌱', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      podium[0]['full_name'] ?? '—',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Top Recycler · ${podium[0]['total_points']} pts',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Custom Top 3 Podium
        if (podium.length >= 2) ...[
          _buildPodiumLayout(podium, isDark),
          const SizedBox(height: 24),
        ],

        // Rankings table list
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
            boxShadow: AppTheme.shadowCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Ranking',
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                    ),
                    const Text(
                      'Updates every 7 days',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (rest.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Be the first to climb the leaderboard!',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rest.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rankUser = rest[index];
                    final rankNum = index + 4;
                    final isMe = widget.profile?.id == rankUser['id'];

                    final initials = rankUser['full_name'] != null && rankUser['full_name']!.toString().trim().isNotEmpty
                        ? rankUser['full_name']
                            .toString()
                            .split(' ')
                            .where((word) => word.isNotEmpty)
                            .map((word) => word[0])
                            .take(2)
                            .join()
                            .toUpperCase()
                        : '?';

                    return Container(
                      color: isMe
                          ? (isDark ? AppTheme.primaryDark.withOpacity(0.2) : AppTheme.mintColor.withOpacity(0.6))
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '#$rankNum',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDark ? const Color(0xFF131D18) : AppTheme.borderLight,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.accentLime : AppTheme.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rankUser['full_name'] ?? 'Student',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(LucideIcons.flame, color: Colors.orange, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${rankUser['total_points']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumLayout(List<Map<String, dynamic>> podium, bool isDark) {
    // Map order to: [2nd, 1st, 3rd] -> podium array index order: [1, 0, 2]
    final order = [1, 0, 2];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: order.map((podIndex) {
        if (podIndex >= podium.length) return const Expanded(child: SizedBox());
        
        final user = podium[podIndex];
        final isFirst = podIndex == 0;
        final isSecond = podIndex == 1;

        double blockHeight = 0;
        String medal = '';
        double avatarRadius = 0;
        
        if (isFirst) {
          blockHeight = 90;
          medal = '🥇';
          avatarRadius = 24;
        } else if (isSecond) {
          blockHeight = 70;
          medal = '🥈';
          avatarRadius = 20;
        } else {
          blockHeight = 55;
          medal = '🥉';
          avatarRadius = 20;
        }

        final initials = user['full_name'] != null && user['full_name']!.toString().trim().isNotEmpty
            ? user['full_name']
                .toString()
                .split(' ')
                .where((word) => word.isNotEmpty)
                .map((word) => word[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: isFirst ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.accentLime : AppTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user['full_name']?.toString().split(' ').first ?? '—',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${user['total_points']} pts',
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                height: blockHeight,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  boxShadow: AppTheme.shadowCard,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      isFirst ? '#1' : (isSecond ? '#2' : '#3'),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildMenuRow(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}
