import 'dart:convert';

import 'package:flutter/material.dart';

import 'aurex_http.dart';
import 'landing.dart';

const String aurexApiBaseUrl = String.fromEnvironment(
  'AUREX_API_BASE_URL',
  defaultValue: 'https://api.aurex-performance.com',
);

class AurexLoginScreen extends StatefulWidget {
  const AurexLoginScreen({super.key});

  static const Color black = Color(0xFF030303);
  static const Color panel = Color(0xF2111111);
  static const Color gold = Color(0xFFCBA436);
  static const Color softGold = Color(0xFFE9C460);
  static const Color border = Color(0xFF343434);
  static const Color mutedText = Color(0xFFA6A6A6);

  @override
  State<AurexLoginScreen> createState() => _AurexLoginScreenState();
}

class _AurexLoginScreenState extends State<AurexLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final session = await AurexAuthApi.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      AurexSession.current = session;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AurexLandingScreen()),
      );
    } on AurexAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurexLoginScreen.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final heroHeight = (width * 0.98).clamp(390.0, 520.0);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  _HeroArtwork(height: heroHeight),
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - 18),
                    child: _LoginPanel(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isSubmitting: _isSubmitting,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onSubmit: _submit,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        'assets/images/login_hero.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSubmitting;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 18),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        color: AurexLoginScreen.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              const TextSpan(
                text: 'Welcome ',
                children: [
                  TextSpan(
                    text: 'Back!',
                    style: TextStyle(color: AurexLoginScreen.gold),
                  ),
                ],
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login to continue your fitness journey',
              style: TextStyle(
                color: AurexLoginScreen.mutedText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),
            _InputField(
              controller: emailController,
              icon: Icons.person_outline_rounded,
              hint: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Enter your email address';
                }
                if (!email.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _InputField(
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              hint: 'Password',
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AurexLoginScreen.gold,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 66,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AurexLoginScreen.softGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isSubmitting ? null : () => onSubmit(),
                child: Text(
                  isSubmitting ? 'SIGNING IN...' : 'LOGIN',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const _DividerLabel(),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    mark: 'G',
                    markColor: Color(0xFF4285F4),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    mark: '●',
                    markColor: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SocialButton(
                    label: 'Facebook',
                    mark: 'f',
                    markColor: Color(0xFF1877F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AurexLoginScreen.mutedText,
                ),
                child: const Text.rich(
                  TextSpan(
                    text: "Don't have an account?  ",
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: AurexLoginScreen.softGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AurexSession {
  const AurexSession({required this.token, required this.user, this.member});

  final String token;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? member;

  static AurexSession? current;
}

class AurexAuthApi {
  static Future<AurexSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$aurexApiBaseUrl/login');
      final response = await aurexPostJson(
        uri,
        headers: const {'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseBody = response.body;
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AurexAuthException(_messageFrom(payload));
      }

      return AurexSession(
        token: payload['token'] as String,
        user: Map<String, dynamic>.from(payload['user'] as Map),
        member: payload['member'] is Map
            ? Map<String, dynamic>.from(payload['member'] as Map)
            : null,
      );
    } on AurexNetworkException {
      throw const AurexAuthException(
        'Unable to reach the AUREX server. Check your connection.',
      );
    } on FormatException {
      throw const AurexAuthException(
        'The server returned an invalid response.',
      );
    }
  }

  static String _messageFrom(Map<String, dynamic> payload) {
    final errors = payload['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return payload['message']?.toString() ?? 'Unable to sign in.';
  }
}

class AurexAuthException implements Exception {
  const AurexAuthException(this.message);

  final String message;
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      cursorColor: AurexLoginScreen.gold,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 16),
          child: Icon(icon, color: AurexLoginScreen.gold, size: 30),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 72),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AurexLoginScreen.mutedText,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AurexLoginScreen.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AurexLoginScreen.gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.38))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: AurexLoginScreen.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.38))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.mark,
    required this.markColor,
  });

  final String label;
  final String mark;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: AurexLoginScreen.gold.withValues(alpha: 0.75)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mark,
              style: TextStyle(
                color: markColor,
                fontSize: mark == '●' ? 22 : 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
