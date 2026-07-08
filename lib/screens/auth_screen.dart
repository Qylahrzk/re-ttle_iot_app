import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _showPassword = false;

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
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed') ||
          e.code == 'email_not_confirmed') {
        _showEmailNotConfirmedDialog(email);
      } else if (e.message.contains('Invalid login credentials')) {
        _showSnackbar('Invalid email or password', isError: true);
      } else if (e.message.contains('User already registered')) {
        _showSnackbar(
          'This email is already registered. Try signing in instead.',
          isError: true,
        );
      } else {
        _showSnackbar(e.message, isError: true);
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

  void _showEmailNotConfirmedDialog(String email) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.cardBgDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text('Email Not Confirmed'),
          content: Text(
            'Your email address $email has not been verified yet. Please check your inbox for the confirmation link.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _supabaseService.resendConfirmationEmail(email);
                  _showSnackbar(
                    'Confirmation email resent successfully!',
                    isError: false,
                  );
                } catch (err) {
                  _showSnackbar(err.toString(), isError: true);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Resend Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
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
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
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
                                onTap: () =>
                                    setState(() => _isSignInMode = true),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(LucideIcons.mail, size: 20),
                                hintText:
                                    'UiTM Email (e.g. 2023239326@student.uitm.edu.my)',
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!val.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (!_isUitmEmail(val)) {
                                  return 'Must be a UiTM email (@student.uitm.edu.my)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  LucideIcons.lock,
                                  size: 20,
                                ),
                                hintText: 'Password',
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  child: Icon(
                                    _showPassword
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    size: 20,
                                  ),
                                ),
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
                                minimumSize: const Size(double.infinity, 50),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                      _isSignInMode
                                          ? 'Sign In'
                                          : 'Create Account',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _isSignInMode
                              ? 'Only @student.uitm.edu.my accounts allowed'
                              : 'Sign up with your UiTM student email',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Every bottle recycled = a greener UiTM 🌱',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
