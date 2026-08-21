import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../screens/trading_screen.dart';

/// Text field used inside the Login/Register cards.
class AuthInputField extends StatelessWidget {
  final String hint;
  final Widget? suffixIcon;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;

  const AuthInputField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54, size: 20),
          hintText: hint,
          suffixIcon:suffixIcon,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Small circular social login button (Facebook / Google / Twitter).
class SocialCircle extends StatelessWidget {
  final Color color;
  final String letter;
  final Color textColor;

  const SocialCircle({
    super.key,
    required this.color,
    required this.letter,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(letter, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

/// Row of the 3 social login circles with a divider label above it.
class SocialRow extends StatelessWidget {
  final String label;

  const SocialRow({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Facebook
            GestureDetector(
              onTap: () async {
                final user = await AuthService.facebookLogin();

                if (user != null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TradingScreen(),
                    ),
                  );
                }
              },
              child: const SocialCircle(
                color: Color(0xFF1877F2),
                letter: 'f',
              ),
            ),

            const SizedBox(width: 14),

            // Google
            GestureDetector(
              onTap: () async {
                print("Google button pressed");
                final user = await AuthService.googleLogin();

                if (user != null && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TradingScreen(),
                    ),
                  );
                }
              },
              child: const SocialCircle(
                color: Colors.white,
                letter: 'G',
                textColor: Colors.red,
              ),
            ),

            const SizedBox(width: 14),

            // Twitter (abhi inactive)
            const SocialCircle(
              color: Color(0xFF1DA1F2),
              letter: 't',
            ),
          ],
        ),
      ],
    );
  }
}
/// Gradient submit button used by both screens, with a loading spinner state.
class AuthSubmitButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final bool isLoading;
  final VoidCallback onTap;

  const AuthSubmitButton({
    super.key,
    required this.text,
    required this.gradient,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

/// Decorative diagonal streak background used behind both auth screens.
class StreakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leftPaint = Paint()
      ..color = const Color(0xFF2E9BFF).withOpacity(0.15)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rightPaint = Paint()
      ..color = const Color(0xFFB259FF).withOpacity(0.15)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final y = size.height * 0.15 + i * 40.0;
      canvas.drawLine(Offset(-40, y + 60), Offset(140, y), leftPaint);
      canvas.drawLine(Offset(size.width - 140, y), Offset(size.width + 40, y + 60), rightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

