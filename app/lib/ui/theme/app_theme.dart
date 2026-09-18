import 'package:flutter/material.dart';

/// 现代化高质感极客深色设计规范
class AppTheme {
  // 主色调
  static const Color background = Color(0xFF0B0F17);
  static const Color surface = Color(0xFF131B26);
  static const Color surfaceHighlight = Color(0xFF1C2736);
  static const Color primary = Color(0xFF6366F1); // 电光紫蓝
  static const Color primaryGlow = Color(0x666366F1);
  static const Color secondary = Color(0xFF10B981); // 赛博青绿 (连接成功/好延迟)
  static const Color secondaryGlow = Color(0x6610B981);
  static const Color warning = Color(0xFFF59E0B); // 暖黄
  static const Color error = Color(0xFFEF4444); // 珊瑚红 (超时/断开)

  // 文本颜色
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 边框与毛玻璃背景
  static const Color borderLight = Color(0x1FFFFFFF);
  static const Color borderGlow = Color(0x336366F1);
  static const Color glassFill = Color(0x0AFFFFFF);
  static const Color glassCardFill = Color(0x141E293B);

  // 渐变方案
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0B0F17), Color(0xFF0F172A), Color(0xFF070A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
