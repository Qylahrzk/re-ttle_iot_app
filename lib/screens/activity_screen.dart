import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../models/profile.dart';
import '../models/scan_session.dart';
import '../services/supabase_service.dart';

class ActivityScreen extends StatefulWidget {
  final Profile? profile;
  const ActivityScreen({super.key, this.profile});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  String _activeFilter = 'Week';
  final List<String> _filters = ['Today', 'Week', 'Month', 'Year'];

  List<ScanSession> _sessions = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile?.totalBottles != oldWidget.profile?.totalBottles) {
      _loadActivities();
    }
  }

  DateTime _calculateSinceDate() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Week':
        return now.subtract(const Duration(days: 7));
      case 'Month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'Year':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _loadActivities() async {
    if (widget.profile == null) return;
    setState(() => _isLoading = true);
    try {
      final since = _calculateSinceDate();
      final data = await _supabaseService.getActivitiesInTimeframe(
        widget.profile!.id,
        since,
      );
      if (mounted) {
        setState(() {
          _sessions = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter by search query
    final filteredSessions = _sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      final location = (s.location ?? '').toLowerCase();
      final binId = s.binId.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return location.contains(query) || binId.contains(query);
    }).toList();

    // Aggregates
    final totalBottles = filteredSessions.fold<int>(
      0,
      (sum, item) => sum + item.bottleCount,
    );
    final totalPoints = filteredSessions.fold<int>(
      0,
      (sum, item) => sum + item.pointsEarned,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity',
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
                        color: isDark
                            ? AppTheme.borderDark
                            : AppTheme.borderLight,
                      ),
                      boxShadow: AppTheme.shadowCard,
                    ),
                    child: const Icon(LucideIcons.download, size: 16),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Hero
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientHero,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.shadowFab,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BOTTLES (${_activeFilter.toUpperCase()})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$totalBottles',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'POINTS EARNED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '+$totalPoints',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.cardBgDark
                            : AppTheme.borderLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: _filters.map((f) {
                          final isActive = _activeFilter == f;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeFilter = f;
                                });
                                _loadActivities();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark
                                            ? AppTheme.bgDark
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: isActive
                                      ? AppTheme.shadowCard
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? (isDark
                                                ? AppTheme.accentLime
                                                : AppTheme.primaryDark)
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                        hintText: 'Search location or bin ID',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activities list
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : filteredSessions.isEmpty
                        ? Container(
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
                            padding: const EdgeInsets.all(40),
                            child: const Column(
                              children: [
                                Text('📭', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 12),
                                Text(
                                  'No activity in this period yet.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredSessions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final session = filteredSessions[index];
                              final dateStr = DateFormat(
                                'MMM d, yyyy h:mm a',
                              ).format(session.createdAt);
                              return Container(
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
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 48,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppTheme.primaryDark.withValues(
                                                alpha: 0.4,
                                              )
                                            : AppTheme.mintColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        LucideIcons.recycle,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${session.bottleCount} bottle${session.bottleCount > 1 ? "s" : ""}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${session.location ?? "UiTM Campus"} • Bin ${session.binId}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 11),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateStr,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '+${session.pointsEarned}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${session.co2SavedKg}kg CO₂',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 10),
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
            ),
          ],
        ),
      ),
    );
  }
}
