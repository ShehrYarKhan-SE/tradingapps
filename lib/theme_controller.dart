import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

class AppColors {
  const AppColors(this.dark);

  final bool dark;

  static AppColors of(BuildContext context) {
    return AppColors(Theme.of(context).brightness == Brightness.dark);
  }

  Color get scaffold => dark ? const Color(0xFF09090B) : const Color(0xFFF4F6FB);
  Color get surface => dark ? const Color(0xFF141B2E) : Colors.white;
  Color get card =>
      dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
  Color get border =>
      dark ? Colors.white.withValues(alpha: 0.08) : const Color(0x1A0F172A);
  Color get text => dark ? Colors.white : const Color(0xFF0F172A);
  Color get muted => dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get nav => dark ? const Color(0xF2141B2E) : const Color(0xF2FFFFFF);
  Color get header => dark ? const Color(0xFF0D0D0F) : const Color(0xFFF4F6FB);
  Color get sheet => dark ? const Color(0xFF1A1A1F) : Colors.white;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB),
        secondary: Color(0xFF7C3AED),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F6FB),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF7C3AED)
              : const Color(0xFFE2E8F0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFFC4B5FD)
              : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09090B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFFA855F7),
        surface: Color(0xFF141B2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static void setUiOverlay(bool dark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
