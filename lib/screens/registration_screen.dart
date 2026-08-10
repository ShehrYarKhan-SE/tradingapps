import 'package:flutter/material.dart';
import 'trading_screen.dart';
import 'login_screen.dart';
import '../service/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.register(
      username: _usernameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {

      _showMessage("Registration Successful", isError: false);

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TradingScreen(),
        ),
      );

    } else {
      _showMessage(result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF05060B)),
          Positioned.fill(child: CustomPaint(painter: StreakPainter())),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B1B5C), Color(0xFF160B2E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB259FF).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFB259FF).withOpacity(0.25), blurRadius: 30, spreadRadius: 2),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Register', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Create Your Account', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 28),
                      AuthInputField(
                        hint: 'Username',
                        icon: Icons.person,
                        controller: _usernameCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter username';
                          if (v.trim().length < 4) return 'Username must be 4 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthInputField(
                        hint: 'Email Address',
                        icon: Icons.email,
                        controller: _emailCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your email address ';
                          if (!_emailRegex.hasMatch(v.trim())) return ' please enter valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AuthInputField(
                        hint: 'Password',
                        icon: Icons.lock,
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter Password';
                          if (v.length < 6) return 'Enter 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      AuthSubmitButton(
                        text: 'Sign Up',
                        gradient: const [Color(0xFFB259FF), Color(0xFF7A2CD9)],
                        isLoading: _isLoading,
                        onTap: _handleRegister,
                      ),
                      const SizedBox(height: 22),
                      const SocialRow(label: 'Or Sign up with'),
                      const SizedBox(height: 22),
                      Column(
                        children: [
                          Text('Already have an account?', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Color(0xFFB259FF), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}