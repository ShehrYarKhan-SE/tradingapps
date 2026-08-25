import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../service/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.onSwitchToLogin});

  final VoidCallback? onSwitchToLogin;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  bool get _passwordLongEnough => _passwordCtrl.text.length >= 8;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showMessage('Please agree to the Terms of Service and Privacy Policy');
      return;
    }
    setState(() => _isLoading = true);

    final result = await AuthService.register(
      username: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      _showMessage(result.message);
    }
  }

  Future<void> _handleGoogle() async {
    if (_googleLoading || _isLoading) return;
    if (!_agreedToTerms) {
      _showMessage('Please agree to the Terms of Service and Privacy Policy');
      return;
    }
    setState(() => _googleLoading = true);
    final result = await AuthService.googleLogin();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (!result.success) _showMessage(result.message);
  }

  void _openLogin() {
    if (widget.onSwitchToLogin != null) {
      widget.onSwitchToLogin!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      backgroundAsset: 'assets/branding/register_bg.jpg',
      child: Column(
        children: [
          const AuthBrandHeader(),
          const SizedBox(height: 18),
          AuthGlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your trading practice journey',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthInputField(
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                    controller: _nameCtrl,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your full name';
                      if (v.trim().length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    label: 'Email address',
                    icon: Icons.mail_outline_rounded,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
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
                      if (v.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    label: 'Confirm password',
                    icon: Icons.lock_outline_rounded,
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your password';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _CheckLine(
                    checked: _passwordLongEnough,
                    interactive: false,
                    child: Text(
                      'Password must be at least 8 characters',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _CheckLine(
                    checked: _agreedToTerms,
                    interactive: true,
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                        children: const [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF7DD3FC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF7DD3FC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthSubmitButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onTap: _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  const AuthOrDivider(),
                  const SizedBox(height: 12),
                  GoogleContinueButton(
                    isLoading: _googleLoading,
                    onTap: _handleGoogle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          AuthSwitchRow(
            prompt: 'Already have an account?',
            action: 'Sign In',
            onTap: _openLogin,
          ),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  final bool checked;
  final bool interactive;
  final VoidCallback? onTap;
  final Widget child;

  const _CheckLine({
    required this.checked,
    required this.interactive,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Icon(
      checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
      size: 22,
      color: checked ? kAuthAccent : Colors.white38,
    );

    return GestureDetector(
      onTap: interactive ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: box,
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
