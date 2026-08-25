import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;

  const SplashScreen({super.key, required this.next});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {});
        }
      });
    _loader.forward();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loader.status == AnimationStatus.completed) return widget.next;
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: 128,
                height: 128,
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/app_icon.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'VIRTUAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFF2E9BFF), thickness: 1.2)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'TRADING AI',
                      style: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFA855F7), thickness: 1.2)),
                ],
              ),
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  children: [
                    TextSpan(text: 'Virtual '),
                    TextSpan(
                      text: 'Trading',
                      style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '. Real '),
                    TextSpan(
                      text: 'Learning',
                      style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '. '),
                    TextSpan(
                      text: 'Smarter',
                      style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' You.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                children: const [
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.bar_chart_rounded,
                      color: Color(0xFF3B82F6),
                      title: 'PRACTICE',
                      subtitle: 'with Virtual Money',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.smart_toy_outlined,
                      color: Color(0xFFA855F7),
                      title: 'LEARN',
                      subtitle: 'with AI Coach',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.verified_user_outlined,
                      color: Color(0xFF22C55E),
                      title: 'IMPROVE',
                      subtitle: 'Your Trading Skills',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Loading your trading experience...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _loader,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 7,
                      child: Stack(
                        children: [
                          Container(color: const Color(0xFF1E293B)),
                          FractionallySizedBox(
                            widthFactor: _loader.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF22C55E)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Virtual Trading AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Risk-Free. Learn More. Trade Better.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 9, height: 1.2),
          ),
        ],
      ),
    );
  }
}
