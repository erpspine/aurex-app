import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import 'providers.dart';
import 'router.dart';
import 'toast.dart';

/// Shown while the saved session is checked when the app starts.
class AurexSplashScreen extends ConsumerWidget {
  const AurexSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(sessionProvider).error;

    return Scaffold(
      backgroundColor: AurexLoginScreen.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/placeholder.png', width: 200),
              const SizedBox(height: 32),
              if (error == null)
                const CircularProgressIndicator(color: AurexLoginScreen.gold)
              else ...[
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(sessionProvider),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AurexLoginScreen extends ConsumerStatefulWidget {
  const AurexLoginScreen({super.key});

  static const Color black = Color(0xFF030303);
  static const Color panel = Color(0xF2111111);
  static const Color gold = Color(0xFFCBA436);
  static const Color softGold = Color(0xFFE9C460);
  static const Color border = Color(0xFF343434);
  static const Color mutedText = Color(0xFFA6A6A6);

  @override
  ConsumerState<AurexLoginScreen> createState() => _AurexLoginScreenState();
}

class _AurexLoginScreenState extends ConsumerState<AurexLoginScreen> {
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
      final session = await ref
          .read(apiClientProvider)
          .login(email: email, password: password);

      // The router redirects to the home tab once the session is stored.
      await ref.read(sessionProvider.notifier).signIn(session);
    } on AurexApiException catch (error) {
      if (!mounted) return;

      if (error.verificationRequired) {
        await context.push(
          AurexRoutes.withEmail(AurexRoutes.verifyEmail, email),
          extra: AuthScreenExtra(
            message: error.message,
            retryAfter: error.retryAfter,
          ),
        );
        return;
      }

      showAuthErrorToast(context, error);
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
                onPressed: () => context.push(AurexRoutes.forgotPassword),
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
                    : () => context.push(AurexRoutes.signUp),
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

class AurexSignUpScreen extends ConsumerStatefulWidget {
  const AurexSignUpScreen({super.key});

  @override
  ConsumerState<AurexSignUpScreen> createState() => _AurexSignUpScreenState();
}

class _AurexSignUpScreenState extends ConsumerState<AurexSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);
    final email = _email.text.trim();
    try {
      final result = await ref
          .read(apiClientProvider)
          .register(
            name: _name.text.trim(),
            email: email,
            phone: _phone.text.trim(),
            password: _password.text,
            confirmation: _confirmation.text,
          );
      if (!mounted) return;
      _openVerification(
        email,
        result['message'] as String?,
        result['retry_after'] as int? ?? 60,
      );
    } on AurexApiException catch (error) {
      if (!mounted) return;
      if (error.verificationRequired) {
        _openVerification(email, error.message, error.retryAfter);
      } else {
        showAuthErrorToast(context, error, title: 'Sign up failed');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openVerification(String email, String? message, int retryAfter) {
    _password.clear();
    _confirmation.clear();
    context.pushReplacement(
      AurexRoutes.withEmail(AurexRoutes.verifyEmail, email),
      extra: AuthScreenExtra(message: message, retryAfter: retryAfter),
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
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      hint: 'Phone (WhatsApp)',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (phone.isEmpty) return 'Enter your phone number';
                        if (!RegExp(
                          r'^\+?[0-9\s\-()]{9,20}$',
                        ).hasMatch(phone)) {
                          return 'Enter a valid phone number, e.g. 0712 345 678';
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
                          : () => popOrGo(context, AurexRoutes.login),
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

class AurexForgotPasswordScreen extends ConsumerStatefulWidget {
  const AurexForgotPasswordScreen({super.key});

  @override
  ConsumerState<AurexForgotPasswordScreen> createState() =>
      _AurexForgotPasswordScreenState();
}

class _AurexForgotPasswordScreenState
    extends ConsumerState<AurexForgotPasswordScreen> {
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
      final email = _email.text.trim();
      final result = await ref.read(apiClientProvider).forgotPassword(email);
      if (!mounted) return;
      context.pushReplacement(
        AurexRoutes.withEmail(AurexRoutes.resetPassword, email),
        extra: AuthScreenExtra(
          message: result['message'] as String?,
          retryAfter: result['retry_after'] as int? ?? 60,
        ),
      );
    } on AurexApiException catch (error) {
      if (mounted) {
        showAuthErrorToast(context, error, title: 'Could not send code');
      }
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
            'Enter your email and we will send you a reset code by email '
            'and WhatsApp.',
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
            onPressed: _busy ? null : () => popOrGo(context, AurexRoutes.login),
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

class AurexPasswordResetScreen extends ConsumerStatefulWidget {
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
  ConsumerState<AurexPasswordResetScreen> createState() =>
      _AurexPasswordResetScreenState();
}

class _AurexPasswordResetScreenState
    extends ConsumerState<AurexPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  bool _busy = false;
  final bool _showPassword = false;
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
      final result = await ref
          .read(apiClientProvider)
          .verifyPasswordCode(widget.email, _code.text.trim());
      if (mounted) {
        setState(() {
          _resetToken = result['reset_token'] as String?;
          _message = _resetToken == null
              ? 'The server did not return a reset token. Request a new code.'
              : result['message'] as String?;
        });
      }
    } on AurexApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .forgotPassword(widget.email);
      if (mounted) {
        setState(() => _message = result['message'] as String?);
        _startCooldown(result['retry_after'] as int? ?? 60);
      }
    } on AurexApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_formKey.currentState?.validate() != true || _resetToken == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .resetPassword(
            widget.email,
            _resetToken!,
            _password.text,
            _confirmation.text,
          );
      if (mounted) {
        showAurexToast(
          context,
          title: 'Password changed',
          message: 'You can now log in with your new password.',
          type: AurexToastType.success,
        );
        context.go(AurexRoutes.login);
      }
    } on AurexApiException catch (error) {
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
                ? 'Check ${widget.email} and your WhatsApp for the code.'
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

class AurexEmailVerificationScreen extends ConsumerStatefulWidget {
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
  ConsumerState<AurexEmailVerificationScreen> createState() =>
      _AurexEmailVerificationScreenState();
}

class _AurexEmailVerificationScreenState
    extends ConsumerState<AurexEmailVerificationScreen> {
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
      await ref
          .read(apiClientProvider)
          .verifyEmail(widget.email, _code.text.trim());
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _verified = true;
        _code.clear();
      });
    } on AurexApiException catch (error) {
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
      final result = await ref.read(apiClientProvider).resendCode(widget.email);
      if (!mounted) return;
      setState(() {
        _message = result['message'] as String?;
        _code.clear();
        _startCooldown(result['retry_after'] as int? ?? 60);
      });
    } on AurexApiException catch (error) {
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
                          : () => context.go(AurexRoutes.login),
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
