import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';
import '../models/scan_session.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final Profile? profile;
  final void Function(int)? onTabSelect;
  const HomeScreen({super.key, this.profile, this.onTabSelect});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<ScanSession> _recentSessions = [];
  bool _loadingActivities = false;

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile?.totalBottles != oldWidget.profile?.totalBottles) {
      _loadRecentActivities();
    }
  }

  Future<void> _loadRecentActivities() async {
    if (widget.profile == null) return;
    setState(() => _loadingActivities = true);
    try {
      final data = await _supabaseService.getRecentActivities(
        widget.profile!.id,
        limit: 3,
      );
      if (mounted) {
        setState(() {
          _recentSessions = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent: $e');
    } finally {
      if (mounted) setState(() => _loadingActivities = false);
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.profile != null) {
      await _supabaseService.refreshProfile(widget.profile!.id);
      await _loadRecentActivities();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = widget.profile;
    final points = profile?.totalPoints ?? 0;
    const nextRewardAt = 500;
    final progress = (points / nextRewardAt).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final pointsNeeded = (nextRewardAt - points).clamp(0, nextRewardAt);

    final initials =
        profile?.fullName != null && profile!.fullName!.trim().isNotEmpty
        ? profile.fullName!
              .split(' ')
              .where((word) => word.isNotEmpty)
              .map((word) => word[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'ME';

    final firstName =
        profile?.fullName != null && profile!.fullName!.trim().isNotEmpty
        ? profile.fullName!.split(' ').first
        : 'there';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hi, $firstName! 👋',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDark
                                ? AppTheme.textLight
                                : AppTheme.primaryDark,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onTabSelect != null) {
                          widget.onTabSelect!(4); // Profile tab index is 4
                        }
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardBgDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                          ),
                          boxShadow: AppTheme.shadowCard,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: (profile?.avatarUrl?.isNotEmpty ?? false)
                              ? Image.network(
                                  profile!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppTheme.accentLime
                                            : AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppTheme.accentLime
                                          : AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Points Card
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientHero,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.shadowHero,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.accentLime.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL POINTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                NumberFormat('#,###').format(points),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: AppTheme.accentLime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  '🌍 You\'re in the top 5% this month!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onTabSelect?.call(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: const Text(
                                    'Redeem',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stat Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      title: 'Bottles Recycled',
                      value: '${profile?.totalBottles ?? 0}',
                      icon: const Icon(
                        LucideIcons.recycle,
                        color: AppTheme.primaryColor,
                      ),
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      title: 'CO₂ Saved',
                      value:
                          '${(profile?.co2SavedKg ?? 0.0).toStringAsFixed(1)} kg',
                      icon: const Icon(
                        LucideIcons.leaf,
                        color: AppTheme.primaryColor,
                      ),
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      title: 'Day Streak',
                      value: '${profile?.streakDays ?? 0}',
                      icon: const Icon(LucideIcons.flame, color: Colors.orange),
                      isDark: isDark,
                    ),
                    _buildStatCard(
                      title: 'Plastic Diverted',
                      value: '${profile?.plasticDivertedG ?? 0} g',
                      icon: const Icon(LucideIcons.trophy, color: Colors.amber),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Next Reward Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
                    boxShadow: AppTheme.shadowCard,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 64,
                            width: 64,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.12,
                                    ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textLight
                                  : AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Reward',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Text(
                              '\$5 Coffee Voucher',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pointsNeeded pts to unlock',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Quick actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickAction(
                          icon: LucideIcons.scanLine,
                          label: 'Scan',
                          color: AppTheme.primaryColor,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScanScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAction(
                          icon: LucideIcons.gift,
                          label: 'Rewards',
                          color: Colors.pink,
                          isDark: isDark,
                          onTap: () => widget.onTabSelect?.call(3),
                        ),
                        _buildQuickAction(
                          icon: LucideIcons.barChart3,
                          label: 'Activity',
                          color: Colors.blue,
                          isDark: isDark,
                          onTap: () => widget.onTabSelect?.call(1),
                        ),
                        _buildQuickAction(
                          icon: LucideIcons.bell,
                          label: 'Alerts',
                          color: Colors.amber,
                          isDark: isDark,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'No new alerts. Your recycling bins are active!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent Activity List
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onTabSelect?.call(1),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.cardBgDark
                            : AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                        ),
                        boxShadow: AppTheme.shadowCard,
                      ),
                      padding: _recentSessions.isEmpty
                          ? const EdgeInsets.all(40)
                          : EdgeInsets.zero,
                      child: _loadingActivities
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _recentSessions.isEmpty
                          ? const Column(
                              children: [
                                Text('🍶', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 12),
                                Text(
                                  'No recycles yet. Tap Scan to start!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentSessions.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final session = _recentSessions[index];
                                final dateStr = DateFormat(
                                  'MMM d, h:mm a',
                                ).format(session.createdAt);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppTheme.primaryDark.withValues(
                                                  alpha: 0.4,
                                                )
                                              : AppTheme.mintColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.recycle,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${session.bottleCount} bottle${session.bottleCount > 1 ? "s" : ""} recycled',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${session.location ?? "UiTM Campus"} • $dateStr',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+${session.pointsEarned}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Daily Eco Tip
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2F26)
                        : AppTheme.accentLime.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x3322C55E)
                          : AppTheme.accentLime.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY ECO TIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.accentLime
                                    : AppTheme.primaryDark,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recycling one plastic bottle saves enough energy to power a lightbulb for 3 hours.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : AppTheme.primaryDark,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Icon icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
        boxShadow: AppTheme.shadowCard,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon,
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          boxShadow: AppTheme.shadowCard,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
