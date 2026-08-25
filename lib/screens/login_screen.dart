import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart';
import '../service/auth_service.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSwitchToRegister});

  final VoidCallback? onSwitchToRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _emailAuthError;
  String? _passwordAuthError;
  late final AnimationController _shake;

  final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _restoreRememberedEmail();
  }

  Future<void> _restoreRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('auth_remember_me') ?? true;
    final email = prefs.getString('auth_remember_email') ?? '';
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email.isNotEmpty) _emailCtrl.text = email;
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _clearAuthErrors() {
    if (_emailAuthError == null && _passwordAuthError == null) return;
    setState(() {
      _emailAuthError = null;
      _passwordAuthError = null;
    });
  }

  Future<void> _playShake() async {
    _shake.forward(from: 0);
  }

  void _showMessage(String message, {bool isError = true}) {
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('auth_remember_email', _emailCtrl.text.trim());
    } else {
      await prefs.remove('auth_remember_email');
    }
  }

  Future<void> _handleLogin() async {
    _clearAuthErrors();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      await _saveRememberedEmail();
      return;
    }

    final code = result.code ?? '';
    setState(() {
      if (code == 'user-not-found' || code == 'invalid-email') {
        _emailAuthError = 'No account found with this email';
      } else if (code == 'too-many-requests') {
        _passwordAuthError = 'Too many attempts. Try again later.';
      } else if (code == 'user-disabled') {
        _emailAuthError = 'This account has been disabled';
      } else {
        _passwordAuthError = 'Wrong password';
      }
    });
    await _playShake();
  }

  Future<void> _handleGoogle() async {
    if (_googleLoading || _isLoading) return;
    setState(() => _googleLoading = true);
    final result = await AuthService.googleLogin();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!result.success) _showMessage(result.message);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      _showMessage('Enter a valid email address first');
      return;
    }
    final result = await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    _showMessage(result.message, isError: !result.success);
  }

  void _openRegister() {
    if (widget.onSwitchToRegister != null) {
      widget.onSwitchToRegister!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      backgroundAsset: 'assets/branding/login_bg.jpg',
      child: Column(
        children: [
          const AuthBrandHeader(),
          const SizedBox(height: 22),
          AuthGlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue your trading journey',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthInputField(
                    label: 'Email address',
                    icon: Icons.mail_outline_rounded,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailAuthError,
                    onChanged: (_) => _clearAuthErrors(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final t = _shake.value;
                      final dx = math.sin(t * math.pi * 8) * 8 * (1 - t);
                      return Transform.translate(offset: Offset(dx, 0), child: child);
                    },
                    child: AuthInputField(
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      errorText: _passwordAuthError,
                      onChanged: (_) => _clearAuthErrors(),
                      onEditingComplete: _handleLogin,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        if (v.length < 6) return 'Enter at least 6 characters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: kAuthAccent,
                          checkColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Text(
                          'Remember me',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: kAuthAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AuthSubmitButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onTap: _handleLogin,
                  ),
                  const SizedBox(height: 18),
                  const AuthOrDivider(),
                  const SizedBox(height: 14),
                  GoogleContinueButton(
                    isLoading: _googleLoading,
                    onTap: _handleGoogle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthSwitchRow(
            prompt: "Don't have an account?",
            action: 'Register',
            onTap: _openRegister,
          ),
        ],
      ),
    );
  }
}
