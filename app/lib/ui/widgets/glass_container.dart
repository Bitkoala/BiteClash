import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 现代化毛玻璃亚克力质感容器组件
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final bool glow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.border,
    this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.glassCardFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: glow ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.borderLight,
              width: glow ? 1.5 : 1,
            ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: AppTheme.primary.withValues(alpha: 0.08),
          splashColor: AppTheme.primary.withValues(alpha: 0.15),
          child: content,
        ),
      );
    }

    Widget blurred = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: content,
      ),
    );

    if (margin != null) {
      blurred = Padding(padding: margin!, child: blurred);
    }

    return blurred;
  }
}
