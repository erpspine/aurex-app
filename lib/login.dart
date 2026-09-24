import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aurex_http.dart';
import 'profile.dart';

const String aurexApiBaseUrl = String.fromEnvironment(
  'AUREX_API_BASE_URL',
  defaultValue: 'https://api.aurex-performance.com/api',
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

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const ProfilePage()));
    } on AurexAuthException catch (error) {
      if (!mounted) return;

      if (error.verificationRequired) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AurexEmailVerificationScreen(
              email: email,
              initialMessage: error.message,
              retryAfter: error.retryAfter,
            ),
          ),
        );
        return;
      }

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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AurexForgotPasswordScreen(),
                    ),
                  );
                },
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
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AurexSignUpScreen(),
                          ),
                        );
                      },
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

class AurexSignUpScreen extends StatefulWidget {
  const AurexSignUpScreen({super.key});

  @override
  State<AurexSignUpScreen> createState() => _AurexSignUpScreenState();
}

class _AurexSignUpScreenState extends State<AurexSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);
    final email = _email.text.trim();
    try {
      final result = await AurexAuthApi.register(
        name: _name.text.trim(),
        email: email,
        password: _password.text,
        confirmation: _confirmation.text,
      );
      if (!mounted) return;
      _openVerification(
        email,
        result['message'] as String?,
        result['retry_after'] as int? ?? 60,
      );
    } on AurexAuthException catch (error) {
      if (!mounted) return;
      if (error.verificationRequired) {
        _openVerification(email, error.message, error.retryAfter);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openVerification(String email, String? message, int retryAfter) {
    _password.clear();
    _confirmation.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AurexEmailVerificationScreen(
          email: email,
          initialMessage: message,
          retryAfter: retryAfter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurexLoginScreen.black,
      appBar: AppBar(
        backgroundColor: AurexLoginScreen.black,
        foregroundColor: AurexLoginScreen.softGold,
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: AurexLoginScreen.softGold,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to start your fitness journey',
                      style: TextStyle(
                        color: AurexLoginScreen.mutedText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _InputField(
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      hint: 'Full Name',
                      keyboardType: TextInputType.name,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Enter your full name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      controller: _email,
                      icon: Icons.email_outlined,
                      hint: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Enter your email address';
                        if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      controller: _password,
                      icon: Icons.lock_outline_rounded,
                      hint: 'Password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      controller: _confirmation,
                      icon: Icons.lock_outline_rounded,
                      hint: 'Confirm Password',
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your password';
                        }
                        return value != _password.text
                            ? 'Passwords do not match'
                            : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'We will email you a verification code. Verify your email before logging in.',
                      style: TextStyle(color: AurexLoginScreen.mutedText),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AurexLoginScreen.softGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? 'CREATING ACCOUNT...' : 'SIGN UP',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AurexLoginScreen.softGold,
                      ),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AurexForgotPasswordScreen extends StatefulWidget {
  const AurexForgotPasswordScreen({super.key});

  @override
  State<AurexForgotPasswordScreen> createState() =>
      _AurexForgotPasswordScreenState();
}

class _AurexForgotPasswordScreenState extends State<AurexForgotPasswordScreen> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _busy = true);
    try {
      final result = await AurexAuthApi.forgotPassword(_email.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AurexPasswordResetScreen(
            email: _email.text.trim(),
            initialMessage: result['message'] as String?,
            retryAfter: result['retry_after'] as int? ?? 60,
          ),
        ),
      );
    } on AurexAuthException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthSimpleScaffold(
    title: 'Forgot Password',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_outlined,
            color: AurexLoginScreen.softGold,
            size: 64,
          ),
          const SizedBox(height: 22),
          const Text(
            'Reset your password',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your email and we will send you a reset code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AurexLoginScreen.mutedText, fontSize: 16),
          ),
          const SizedBox(height: 28),
          _InputField(
            controller: _email,
            icon: Icons.email_outlined,
            hint: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                  ? null
                  : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _busy ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AurexLoginScreen.softGold,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(60),
            ),
            child: Text(_busy ? 'SENDING...' : 'SEND RESET CODE'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AurexLoginScreen.softGold,
            ),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    ),
  );
}

class AurexPasswordResetScreen extends StatefulWidget {
  const AurexPasswordResetScreen({
    super.key,
    required this.email,
    this.initialMessage,
    this.retryAfter = 60,
  });
  final String email;
  final String? initialMessage;
  final int retryAfter;
  @override
  State<AurexPasswordResetScreen> createState() =>
      _AurexPasswordResetScreenState();
}

class _AurexPasswordResetScreenState extends State<AurexPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  bool _busy = false;
  bool _showPassword = false;
  String? _message;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    _startCooldown(widget.retryAfter);
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().length != 6) {
      setState(() => _message = 'Enter the six-digit code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await AurexAuthApi.verifyPasswordCode(
        widget.email,
        _code.text.trim(),
      );
      if (mounted)
        setState(() {
          _resetToken = result['reset_token'] as String;
          _message = result['message'] as String?;
        });
    } on AurexAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final result = await AurexAuthApi.forgotPassword(widget.email);
      if (mounted) {
        setState(() => _message = result['message'] as String?);
        _startCooldown(result['retry_after'] as int? ?? 60);
      }
    } on AurexAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_formKey.currentState?.validate() != true || _resetToken == null)
      return;
    setState(() => _busy = true);
    try {
      await AurexAuthApi.resetPassword(
        widget.email,
        _resetToken!,
        _password.text,
        _confirmation.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed. You can now log in.'),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AurexAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthSimpleScaffold(
    title: 'Reset Password',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: AurexLoginScreen.softGold,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            _resetToken == null
                ? 'Enter your reset code'
                : 'Choose a new password',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _resetToken == null
                ? 'We sent a code to ${widget.email}'
                : 'Your reset code is verified.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AurexLoginScreen.mutedText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (_resetToken == null) ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                labelText: 'Reset code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AurexLoginScreen.softGold,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(58),
              ),
              child: const Text('VERIFY CODE'),
            ),
            TextButton(
              onPressed: _busy || _cooldown > 0 ? null : _resend,
              child: Text(
                _cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code',
              ),
            ),
          ] else ...[
            _InputField(
              controller: _password,
              icon: Icons.lock_outline,
              hint: 'New Password',
              obscureText: !_showPassword,
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: 14),
            _InputField(
              controller: _confirmation,
              icon: Icons.lock_outline,
              hint: 'Confirm Password',
              obscureText: !_showPassword,
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AurexLoginScreen.softGold,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(58),
              ),
              child: const Text('CHANGE PASSWORD'),
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                _message!,
                style: const TextStyle(color: AurexLoginScreen.mutedText),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AuthSimpleScaffold extends StatelessWidget {
  const _AuthSimpleScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AurexLoginScreen.black,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: AurexLoginScreen.black,
      foregroundColor: AurexLoginScreen.softGold,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class AurexEmailVerificationScreen extends StatefulWidget {
  const AurexEmailVerificationScreen({
    super.key,
    required this.email,
    this.initialMessage,
    this.retryAfter = 60,
  });

  final String email;
  final String? initialMessage;
  final int retryAfter;

  @override
  State<AurexEmailVerificationScreen> createState() =>
      _AurexEmailVerificationScreenState();
}

class _AurexEmailVerificationScreenState
    extends State<AurexEmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _verified = false;
  String? _message;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
    _startCooldown(widget.retryAfter);
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    _seconds = seconds;
    if (_seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _busy = true;
      _message = null;
      _hasError = false;
    });
    try {
      await AurexAuthApi.verifyEmail(widget.email, _code.text.trim());
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _verified = true;
        _code.clear();
      });
    } on AurexAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _hasError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
      _hasError = false;
    });
    try {
      final result = await AurexAuthApi.resendCode(widget.email);
      if (!mounted) return;
      setState(() {
        _message = result['message'] as String?;
        _code.clear();
        _startCooldown(result['retry_after'] as int? ?? 60);
      });
    } on AurexAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _hasError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurexLoginScreen.black,
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: AurexLoginScreen.black,
        foregroundColor: AurexLoginScreen.softGold,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _verified
                          ? Icons.verified_outlined
                          : Icons.mark_email_unread_outlined,
                      color: AurexLoginScreen.softGold,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _verified ? 'Email verified!' : 'Verify your email',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _verified
                          ? 'Your email is confirmed. You can now log in.'
                          : 'Enter the six-digit code sent to ${widget.email}. The code expires in 10 minutes.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AurexLoginScreen.mutedText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_verified) ...[
                      TextFormField(
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          letterSpacing: 8,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          labelStyle: TextStyle(
                            color: AurexLoginScreen.softGold,
                            letterSpacing: 0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')
                            ? null
                            : 'Enter the six-digit code',
                        onFieldSubmitted: (_) {
                          if (!_busy) _verify();
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_message != null) ...[
                        Text(
                          _message!,
                          style: TextStyle(
                            color: _hasError
                                ? const Color(0xFFFFB4AB)
                                : AurexLoginScreen.mutedText,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      ElevatedButton(
                        onPressed: _busy ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AurexLoginScreen.softGold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(60),
                        ),
                        child: Text(_busy ? 'PLEASE WAIT...' : 'VERIFY EMAIL'),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _busy || _seconds > 0 ? null : _resend,
                        style: TextButton.styleFrom(
                          foregroundColor: AurexLoginScreen.softGold,
                          disabledForegroundColor: AurexLoginScreen.mutedText,
                        ),
                        child: Text(
                          _seconds > 0
                              ? 'Resend code in ${_seconds}s'
                              : 'Resend code',
                        ),
                      ),
                      const Text(
                        'Check your spam folder if you do not see the email.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AurexLoginScreen.mutedText),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AurexLoginScreen.softGold,
                      ),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  bool get isMember {
    final role = '${user['role'] ?? ''}'.trim().toLowerCase();
    final userType = '${user['user_type'] ?? ''}'.trim().toLowerCase();

    return role == 'member' || userType == 'member';
  }
}

class AurexAuthApi {
  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      _post('/password/forgot', {'email': email});

  static Future<Map<String, dynamic>> verifyPasswordCode(
    String email,
    String code,
  ) => _post('/password/verify', {'email': email, 'code': code});

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String password,
    String confirmation,
  ) => _post('/password/reset', {
    'email': email,
    'reset_token': token,
    'password': password,
    'password_confirmation': confirmation,
  });

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) => _post('/register', {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': confirmation,
  });

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) =>
      _post('/email/verify', {'email': email, 'code': code});

  static Future<Map<String, dynamic>> resendCode(String email) =>
      _post('/email/resend', {'email': email});

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final response = await aurexPostJson(
        Uri.parse('$aurexApiBaseUrl$path'),
        headers: const {'Accept': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));
      final payload = _payloadFrom(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AurexAuthException(
          _messageFrom(payload),
          verificationRequired: payload['verification_required'] == true,
          retryAfter: payload['retry_after'] is int
              ? payload['retry_after'] as int
              : 0,
        );
      }
      return payload;
    } on TimeoutException {
      throw const AurexAuthException(
        'The request timed out. Please try again. If your account was created, log in to continue verification.',
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

  static Future<AurexSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final payload = await _post('/login', {
        'email': email,
        'password': password,
      });

      final token = payload['token'];
      final user = payload['user'];

      if (token is! String || token.isEmpty || user is! Map) {
        throw const AurexAuthException(
          'The server returned an incomplete login response.',
        );
      }

      return AurexSession(
        token: token,
        user: Map<String, dynamic>.from(user),
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

  static Map<String, dynamic> _payloadFrom(AurexHttpResponse response) {
    final responseBody = response.body.trim();

    if (responseBody.isEmpty) {
      if (response.statusCode >= 500) {
        throw AurexAuthException(
          'Server error ${response.statusCode}. Please contact support.',
        );
      }

      throw const FormatException();
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      if (response.statusCode >= 500) {
        throw AurexAuthException(
          'Server error ${response.statusCode}. Please contact support.',
        );
      }

      rethrow;
    }

    throw const FormatException();
  }

  static String _messageFrom(Map<String, dynamic> payload) {
    final errors = payload['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return payload['message']?.toString() ?? 'Unable to complete the request.';
  }
}

class AurexAuthException implements Exception {
  const AurexAuthException(
    this.message, {
    this.verificationRequired = false,
    this.retryAfter = 0,
  });

  final String message;
  final bool verificationRequired;
  final int retryAfter;
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
