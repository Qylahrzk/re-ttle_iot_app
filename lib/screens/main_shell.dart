import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';
import 'home_screen.dart';
import 'activity_screen.dart';
import 'scan_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final SupabaseService _supabaseService = SupabaseService();
  int _currentIndex = 0;

  late final String _currentUserId;
  late final Stream<Profile?> _profileStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabaseService.currentUser!.id;
    _profileStream = _supabaseService.streamProfile(_currentUserId);
  }

  void _onTabSelect(int index) {
    if (index == 2) {
      // Navigate to scan page directly (can be full screen or tab, standard full screen is clean!)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<Profile?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;

        final List<Widget> screens = [
          HomeScreen(profile: profile),
          ActivityScreen(profile: profile),
          const SizedBox(), // Spacer for Scan
          RewardsScreen(profile: profile),
          ProfileScreen(profile: profile),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          extendBody: true,
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardBgDark.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight.withOpacity(0.6),
                ),
                boxShadow: AppTheme.shadowCard,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, LucideIcons.home, 'Home', isDark),
                  _buildNavItem(1, LucideIcons.barChart3, 'Activity', isDark),
                  _buildScanFAB(isDark),
                  _buildNavItem(3, LucideIcons.gift, 'Rewards', isDark),
                  _buildNavItem(4, LucideIcons.user, 'Profile', isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = AppTheme.textMuted;

    return GestureDetector(
      onTap: () => _onTabSelect(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFAB(bool isDark) {
    return GestureDetector(
      onTap: () => _onTabSelect(2),
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.gradientPrimary,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowFab,
                border: Border.all(
                  color: isDark ? AppTheme.bgDark : AppTheme.mintColor,
                  width: 4,
                ),
              ),
              child: const Icon(
                LucideIcons.scanLine,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Scan',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
