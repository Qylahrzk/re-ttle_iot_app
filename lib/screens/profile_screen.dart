import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final Profile? profile;
  final void Function(int)? onTabSelect;

  const ProfileScreen({super.key, this.profile, this.onTabSelect});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Profile? _localProfile;

  final List<Map<String, dynamic>> _achievements = [
    {
      'id': 'eco-starter',
      'title': 'Eco Starter',
      'emoji': '🌱',
      'threshold': 1,
      'type': 'bottles',
    },
    {
      'id': 'streak',
      'title': '7-Day Streak',
      'emoji': '🔥',
      'threshold': 7,
      'type': 'streak',
    },
    {
      'id': 'ocean',
      'title': 'Ocean Saver',
      'emoji': '🌊',
      'threshold': 25,
      'type': 'bottles',
    },
    {
      'id': 'hero',
      'title': 'Bottle Hero',
      'emoji': '🦸',
      'threshold': 50,
      'type': 'bottles',
    },
  ];

  @override
  void initState() {
    super.initState();
    _localProfile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localProfile = widget.profile;
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

  void _showEditProfileDialog() {
    final profile = _localProfile;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.fullName);
    final avatarController = TextEditingController(
      text: profile.avatarUrl ?? '',
    );
    String selectedAvatar = profile.avatarUrl ?? '';

    final avatarPresets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=150',
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=150',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardBgDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Profile Picture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: avatarPresets.map((url) {
                        final isSelected = selectedAvatar == url;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedAvatar = url;
                              avatarController.text = url;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(url),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: avatarController,
                      onChanged: (val) {
                        setSheetState(() {
                          selectedAvatar = val.trim();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Or Paste Avatar Image URL',
                        prefixIcon: Icon(LucideIcons.image, size: 20),
                        hintText: 'https://example.com/avatar.png',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(LucideIcons.user, size: 20),
                        hintText: 'Enter your full name',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Name cannot be empty'),
                            ),
                          );
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        try {
                          await _supabaseService.updateProfileNameAndAvatar(
                            _localProfile!.id,
                            newName,
                            selectedAvatar,
                          );
                          final updatedProfile = _localProfile!.copyWith(
                            fullName: newName,
                            avatarUrl: selectedAvatar.isEmpty
                                ? null
                                : selectedAvatar,
                          );
                          setState(() {
                            _localProfile = updatedProfile;
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error updating profile: $e'),
                              backgroundColor: AppTheme.destructiveColor,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAchievementsDialog() {
    final profile = _localProfile;
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? AppTheme.cardBgDark : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _achievements.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ach = _achievements[index];
                      final type = ach['type'];
                      final threshold = ach['threshold'] as int;
                      final userVal = type == 'streak'
                          ? (profile.streakDays)
                          : (profile.totalBottles);
                      final unlocked = userVal >= threshold;
                      final progress = (userVal / threshold).clamp(0.0, 1.0);

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgDark : AppTheme.mintColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ach['emoji'] as String,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ach['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$userVal / $threshold ${type == 'streak' ? 'days' : 'bottles'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: unlocked
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.grey.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    unlocked ? 'UNLOCKED' : 'LOCKED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: unlocked
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  unlocked
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = _localProfile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials =
        profile.fullName != null && profile.fullName!.trim().isNotEmpty
        ? profile.fullName!
              .split(' ')
              .where((word) => word.isNotEmpty)
              .map((word) => word[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'ME';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Title
              Text(
                'Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Profile Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  boxShadow: AppTheme.shadowCard,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        profile.avatarUrl != null
                            ? CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(
                                  profile.avatarUrl!,
                                ),
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: isDark
                                    ? AppTheme.bgDark
                                    : AppTheme.mintColor,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.accentLime
                                        : AppTheme.primaryDark,
                                  ),
                                ),
                              ),
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.cardBgDark
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.pencil,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.fullName ?? 'Student',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.matricNumber ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    icon: LucideIcons.star,
                    label: 'Points',
                    value: '${profile.totalPoints}',
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: LucideIcons.box,
                    label: 'Bottles',
                    value: '${profile.totalBottles}',
                    color: AppTheme.warningColor,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: LucideIcons.leaf,
                    label: 'CO₂ Saved',
                    value: '${profile.co2SavedKg.toStringAsFixed(1)} kg',
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _buildStatCard(
                    icon: LucideIcons.droplet,
                    label: 'Plastic Saved',
                    value: '${profile.plasticDivertedG}g',
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Settings Section
              Text(
                'Settings',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  boxShadow: AppTheme.shadowCard,
                ),
                child: Column(
                  children: [
                    _buildSettingRow(
                      icon: LucideIcons.moon,
                      label: 'Theme',
                      trailing: ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeNotifier,
                        builder: (context, currentMode, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF282F48)
                                  : const Color(0xFFEEF2F6),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentMode == ThemeMode.system
                                      ? LucideIcons.monitor
                                      : (currentMode == ThemeMode.dark
                                            ? LucideIcons.moon
                                            : LucideIcons.sun),
                                  size: 10,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentMode == ThemeMode.system
                                      ? 'System'
                                      : (currentMode == ThemeMode.dark
                                            ? 'Dark'
                                            : 'Light'),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () => _showThemeDialog(isDark),
                    ),
                    const Divider(height: 1),
                    _buildSettingRow(
                      icon: LucideIcons.bell,
                      label: 'Notifications',
                      trailing: Text(
                        'Enabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => _showNotificationsDialog(isDark),
                    ),
                    const Divider(height: 1),
                    _buildSettingRow(
                      icon: LucideIcons.info,
                      label: 'About & Help',
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      onTap: () => _showAboutDialog(isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Achievements Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _showAchievementsDialog,
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
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: _achievements.take(4).map((ach) {
                  final type = ach['type'];
                  final threshold = ach['threshold'] as int;
                  final userVal = type == 'streak'
                      ? profile.streakDays
                      : profile.totalBottles;
                  final unlocked = userVal >= threshold;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgDark : AppTheme.mintColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unlocked
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : (isDark
                                  ? AppTheme.borderDark
                                  : AppTheme.borderLight),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          ach['emoji'],
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            ach['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          unlocked ? LucideIcons.checkCircle : LucideIcons.lock,
                          size: 12,
                          color: unlocked
                              ? AppTheme.primaryColor
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              ElevatedButton.icon(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppTheme.cardBgDark
                      : AppTheme.cardBgLight,
                  foregroundColor: AppTheme.destructiveColor,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(LucideIcons.logOut, size: 16),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : AppTheme.mintColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing ??
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardBgDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: themeNotifier.value,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    themeNotifier.value = value;
                    await saveThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeNotifier.value,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    themeNotifier.value = value;
                    await saveThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeNotifier.value,
                onChanged: (ThemeMode? value) async {
                  if (value != null) {
                    themeNotifier.value = value;
                    await saveThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardBgDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: const Text('Recycle Reminders'),
                subtitle: const Text('Daily reminders to recycle'),
                value: true,
                onChanged: (val) {},
              ),
              CheckboxListTile(
                title: const Text('Achievement Unlocked'),
                subtitle: const Text(
                  'Get notified when you unlock achievements',
                ),
                value: true,
                onChanged: (val) {},
              ),
              CheckboxListTile(
                title: const Text('Leaderboard Updates'),
                subtitle: const Text('Weekly ranking updates'),
                value: true,
                onChanged: (val) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardBgDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('About Re:ttle'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Re:ttle is a smart recycling system that rewards students for sustainable practices.',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 16),
                Text(
                  'How it works:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• Scan the QR code on a smart bin\n'
                  '• Insert plastic bottles\n'
                  '• Earn points instantly\n'
                  '• Redeem rewards on campus',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 16),
                Text(
                  'Contact: support@rettle.eco',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
