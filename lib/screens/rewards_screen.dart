import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import '../constants/theme.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../services/supabase_service.dart';

class RewardsScreen extends StatefulWidget {
  final Profile? profile;
  const RewardsScreen({super.key, this.profile});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final List<String> _categories = [
    'All',
    'Food',
    'Campus',
    'Lifestyle',
    'Shopping',
    'Transportation',
    'Eco Products'
  ];

  String _activeCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Reward> _rewards = [];
  bool _isLoading = false;
  String? _redeemingId;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadRewards();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getRewards();
      if (mounted) {
        setState(() {
          _rewards = data;
        });
      }
    } catch (e) {
      print('Error loading rewards: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeem(Reward reward) async {
    final profile = widget.profile;
    if (profile == null) return;

    if (profile.totalPoints < reward.pointsRequired) {
      _showToast('Need ${reward.pointsRequired - profile.totalPoints} more pts', isError: true);
      return;
    }

    setState(() => _redeemingId = reward.id);

    try {
      await _supabaseService.redeemReward(
        userId: profile.id,
        rewardId: reward.id,
        pointsSpent: reward.pointsRequired,
      );

      if (mounted) {
        _confettiController.play();
        _showToast('Redeemed: ${reward.title}', isError: false);
      }
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception:', '').trim(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _redeemingId = null);
      }
    }
  }

  void _showToast(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: isError ? AppTheme.destructiveColor : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final points = widget.profile?.totalPoints ?? 0;

    // Filter logic
    final filteredRewards = _rewards.where((r) {
      final matchCategory = _activeCategory == 'All' || r.category == _activeCategory;
      final matchQuery = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchQuery;
    }).toList();

    // Featured reward
    final featuredReward = _rewards.isNotEmpty
        ? _rewards.firstWhere((r) => r.featured, orElse: () => _rewards.first)
        : null;

    final featuredProgress = featuredReward != null
        ? (points / featuredReward.pointsRequired).clamp(0.0, 1.0)
        : 0.0;
    final featuredPercent = (featuredProgress * 100).round();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rewards',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? AppTheme.textLight : AppTheme.primaryDark,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardBgDark : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                          ),
                          boxShadow: AppTheme.shadowCard,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              points.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.accentLime : AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '★',
                              style: TextStyle(color: Colors.amber, fontSize: 13),
                            ),
                          ],
                        ),
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
                        // Featured Card
                        if (featuredReward != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                              ),
                              boxShadow: AppTheme.shadowCard,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 120,
                                  color: isDark
                                      ? AppTheme.primaryDark.withOpacity(0.3)
                                      : AppTheme.mintColor,
                                  child: Center(
                                    child: Text(
                                      featuredReward.imageEmoji ?? '🎁',
                                      style: const TextStyle(fontSize: 56),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              featuredReward.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            child: Text(
                                              '$featuredPercent%',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (featuredReward.description != null)
                                        Text(
                                          featuredReward.description!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(100),
                                        child: LinearProgressIndicator(
                                          value: featuredProgress,
                                          minHeight: 8,
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : AppTheme.primaryColor.withOpacity(0.1),
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${points.clamp(0, featuredReward.pointsRequired)} / ${featuredReward.pointsRequired} pts to unlock',
                                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Search Field
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(LucideIcons.search, size: 18),
                            hintText: 'Search rewards',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Categories Scroll
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isActive = _activeCategory == category;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeCategory = category;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isActive ? AppTheme.gradientPrimary : null,
                                    color: isActive
                                        ? null
                                        : (isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.transparent
                                          : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                    ),
                                    boxShadow: isActive ? AppTheme.shadowFab : AppTheme.shadowCard,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? Colors.white
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // List Header
                        Row(
                          children: [
                            const Icon(LucideIcons.sparkles, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Available for you',
                              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rewards catalog list
                        _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : filteredRewards.isEmpty
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(40),
                                    child: const Column(
                                      children: [
                                        Text('🎟️', style: TextStyle(fontSize: 36)),
                                        SizedBox(height: 8),
                                        Text(
                                          'No matching rewards found.',
                                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredRewards.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final reward = filteredRewards[index];
                                      final affordable = points >= reward.pointsRequired;
                                      final isRedeeming = _redeemingId == reward.id;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                                          borderRadius: BorderRadius.circular(28),
                                          border: Border.all(
                                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                          ),
                                          boxShadow: AppTheme.shadowCard,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 56,
                                              width: 56,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppTheme.primaryDark.withOpacity(0.4)
                                                    : AppTheme.mintColor,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  reward.imageEmoji ?? '🎁',
                                                  style: const TextStyle(fontSize: 32),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    reward.title,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (reward.description != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      reward.description!,
                                                      style: theme.textTheme.bodySmall,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${reward.pointsRequired} ★ · ${reward.category}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: (!affordable || isRedeeming) ? null : () => _redeem(reward),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primaryColor,
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
                                                disabledForegroundColor: AppTheme.textMuted,
                                                elevation: 0,
                                                minimumSize: const Size(68, 36),
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                              ),
                                              child: isRedeeming
                                                  ? const SizedBox(
                                                      height: 14,
                                                      width: 14,
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                    )
                                                  : Text(
                                                      affordable ? 'Redeem' : 'Locked',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
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

          // Confetti overlay
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.amber, AppTheme.primaryColor, AppTheme.accentLime],
            ),
          ),
        ],
      ),
    );
  }
}
