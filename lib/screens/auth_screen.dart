import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/theme.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isSignInMode = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();

  final List<String> uitmDomains = ['student.uitm.edu.my', 'uitm.edu.my'];

  bool _isUitmEmail(String email) {
    if (!email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase().trim();
    return uitmDomains.contains(domain);
  }

  bool _isValidMatric(String matric) {
    final regExp = RegExp(r'^\d{8,12}$');
    return regExp.hasMatch(matric.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final matric = _matricController.text.trim();

    if (!_isUitmEmail(email)) {
      _showSnackbar(
        'Please use your UiTM email (@student.uitm.edu.my or @uitm.edu.my)',
        isError: true,
      );
      return;
    }

    if (!_isSignInMode && !_isValidMatric(matric)) {
      _showSnackbar(
        'Enter a valid matric number (8 to 12 digits)',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignInMode) {
        await _supabaseService.signIn(email: email, password: password);
        _showSnackbar('Welcome back!', isError: false);
      } else {
        await _supabaseService.signUp(
          email: email,
          password: password,
          matricNumber: matric,
          fullName: email.split('@').first,
        );
        _showSnackbar(
          'Account created! Please check your email to confirm.',
          isError: false,
        );
        setState(() => _isSignInMode = true);
      }
    } catch (e) {
      _showSnackbar(
        e.toString().replaceAll('Exception:', '').trim(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: isError
            ? AppTheme.destructiveColor
            : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    _showSnackbar(
      'Google OAuth is only available in production browser redirect.',
      isError: true,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _matricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Logo Header
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.gradientPrimary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.shadowFab,
                      ),
                      child: const Center(
                        child: Text('♻️', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Re:ttle',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        color: isDark
                            ? AppTheme.textLight
                            : AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recycle. Earn Rewards. Protect the Planet.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Form Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                  boxShadow: AppTheme.shadowCard,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Switch Toggle Tab
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131D18)
                            : AppTheme.borderLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignInMode = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isSignInMode
                                      ? (isDark
                                            ? AppTheme.cardBgDark
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: _isSignInMode
                                      ? AppTheme.shadowCard
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Center(
                                  child: Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isSignInMode
                                          ? (isDark
                                                ? AppTheme.accentLime
                                                : AppTheme.primaryDark)
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isSignInMode = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isSignInMode
                                      ? (isDark
                                            ? AppTheme.cardBgDark
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: !_isSignInMode
                                      ? AppTheme.shadowCard
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Center(
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !_isSignInMode
                                          ? (isDark
                                                ? AppTheme.accentLime
                                                : AppTheme.primaryDark)
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
                    const SizedBox(height: 24),

                    // Inputs form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isSignInMode) ...[
                            TextFormField(
                              controller: _matricController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  LucideIcons.graduationCap,
                                  size: 20,
                                ),
                                hintText: 'Matric Number (e.g. 2023239326)',
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Matric number is required';
                                }
                                if (!_isValidMatric(val)) {
                                  return 'Invalid matric (8-12 digits)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(LucideIcons.mail, size: 20),
                              hintText: 'UiTM Email',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Email is required';
                              }
                              if (!_isUitmEmail(val)) {
                                return 'Must be a UiTM email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(LucideIcons.lock, size: 20),
                              hintText: 'Password',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isSignInMode ? 'Login' : 'Create account',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google OAuth Button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        LucideIcons.chrome,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      label: Text(
                        'Continue with UiTM Google',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textLight
                              : AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Only @student.uitm.edu.my or @uitm.edu.my accounts allowed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              const Text(
                'Every bottle recycled = a greener UiTM 🌱',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
