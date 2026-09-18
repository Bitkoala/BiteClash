import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 动态延迟指示徽章 (带呼吸光晕与测速动效)
class LatencyBadge extends StatelessWidget {
  final int? delay;
  final bool isTesting;
  final VoidCallback? onTap;

  const LatencyBadge({
    super.key,
    this.delay,
    this.isTesting = false,
    this.onTap,
  });

  Color get _color {
    if (delay == null || delay! <= 0) return AppTheme.textMuted;
    if (delay! <= 200) return AppTheme.secondary;
    if (delay! <= 500) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _text {
    if (isTesting) return '测速中';
    if (delay == null || delay! <= 0) return '超时';
    return '$delay ms';
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTesting)
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        const SizedBox(width: 6),
        Text(
          _text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: isTesting ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }

    return content;
  }
}
