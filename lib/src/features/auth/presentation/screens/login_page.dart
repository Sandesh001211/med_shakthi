import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:med_shakthi/src/core/widgets/app_logo.dart';
import 'package:med_shakthi/src/core/utils/custom_snackbar.dart';
import 'package:med_shakthi/src/features/auth/presentation/screens/role_selection_page.dart';

import 'forgot_password_page.dart';

// ── Email regex (rejects @gmail.com, user@, .com etc.) ────────────────────────
final _emailRegExp = RegExp(r'^[\w\-\.+]+@[\w\-]+\.[a-zA-Z]{2,}$');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _resendLoading = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Track whether last login error was "email not confirmed"
  bool _showResendSection = false;

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _onResendEmailPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegExp.hasMatch(email)) {
      showCustomSnackBar(
        context,
        'Enter your valid email address above first.',
        isError: true,
      );
      return;
    }
    if (_resendCooldown > 0) return; // guard against double-tap
    setState(() => _resendLoading = true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);
      if (!mounted) return;
      showCustomSnackBar(context, 'Verification email sent! Check your inbox.');
      _startResendCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Could not resend: $e', isError: true);
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showResendSection = false;
    });

    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        if (!mounted) return;
        showCustomSnackBar(context, 'Login successful');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        setState(() => _showResendSection = true);
        showCustomSnackBar(
          context,
          'Please verify your email address to log in.',
          isError: true,
        );
      } else if (msg.contains('invalid_credentials') ||
          msg.contains('invalid login credentials') ||
          e.statusCode == '400') {
        // Supabase gives same error for wrong password AND unknown email.
        // Distinguish by checking if the email actually exists.
        bool emailExists = true; // assume exists if check fails
        try {
          emailExists = await Supabase.instance.client.rpc(
            'check_email_exists',
            params: {'p_email': _emailController.text.trim()},
          );
        } catch (_) {}

        if (!mounted) return;

        if (!emailExists) {
          // Email not registered → prompt to create account
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Account Not Found'),
              content: const Text(
                'No account found with this email address.\n\nWould you like to create a new account?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8077),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionPage(),
                      ),
                    );
                  },
                  child: const Text('Create Account'),
                ),
              ],
            ),
          );
        } else {
          // Email exists but wrong password
          showCustomSnackBar(
            context,
            'Incorrect password. Please try again or use "Forgot Password".',
            isError: true,
          );
        }
      } else {
        showCustomSnackBar(context, e.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Error: \$e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _isLoading || _resendLoading;
    return Scaffold(
      body: Stack(
        children: [
          // ── Background + form ───────────────────────────────────────────
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                    : [const Color(0xFFEAF4F2), const Color(0xFFF6FBFA)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Center(child: AppLogo(size: 100)),
                      const SizedBox(height: 40),

                      _label('Email'),
                      _textField(
                        controller: _emailController,
                        hint: 'emailaddress@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        // MED-002: proper regex, rejects "@gmail.com" style
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!_emailRegExp.hasMatch(value.trim())) {
                            return 'Enter a valid email (e.g. name@domain.com)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _label('Password'),
                      _textField(
                        controller: _passwordController,
                        hint: 'Password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Minimum 6 characters',
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: busy ? null : _onLoginPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6AA39B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RoleSelectionPage(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    color: Color(0xFF6AA39B),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Resend verification — only shown after "email not confirmed" error
                      if (_showResendSection) ...[
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Didn\'t receive a verification email?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 40,
                                child: _resendCooldown > 0
                                    ? Text(
                                        'Resend available in ${_resendCooldown}s',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6AA39B),
                                        ),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: _resendLoading
                                            ? null
                                            : _onResendEmailPressed,
                                        icon: _resendLoading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF6AA39B),
                                                    ),
                                              )
                                            : const Icon(
                                                Icons
                                                    .mark_email_unread_outlined,
                                                size: 16,
                                              ),
                                        label: const Text(
                                          'Resend Verification Email',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF6AA39B,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF6AA39B),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── MED-001: Full-screen loading overlay ────────────────────────
          if (busy)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6AA39B),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
