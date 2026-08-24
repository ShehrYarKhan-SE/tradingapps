import 'package:flutter/material.dart';
import 'registration_screen.dart';
import '../service/auth_service.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true ;

  final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.green),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
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
                    colors: [Color(0xFF12305C), Color(0xFF0A1730)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E9BFF).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2E9BFF).withOpacity(0.25), blurRadius: 30, spreadRadius: 2),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Login', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Welcome Back!', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 28),
                      AuthInputField(
                        hint: 'Email',
                        icon: Icons.person,
                        controller: _emailCtrl,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your Email';
                          if (!_emailRegex.hasMatch(v.trim())) return 'Enter Valid Email';
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Forgot Password?', style: TextStyle(color: const Color(0xFF2E9BFF), fontSize: 12)),
                      ),
                      const SizedBox(height: 18),
                      AuthSubmitButton(
                        text: 'Login',
                        gradient: const [Color(0xFF2E9BFF), Color(0xFF1657C9)],
                        isLoading: _isLoading,
                        onTap: _handleLogin,
                      ),
                      const SizedBox(height: 22),
                      const SocialRow(label: 'Or Sign in with'),
                      const SizedBox(height: 22),
                      Column(
                        children: [
                          Text("Don't have an account?", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(color: Color(0xFF2E9BFF), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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