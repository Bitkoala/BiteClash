import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/traffic.dart';
import '../theme/app_theme.dart';

/// 60fps 实时流量波形贝塞尔图表
class TrafficChart extends StatelessWidget {
  final List<Traffic> history; // 过去 30~60 个周期的上行与下行数据
  final double height;

  const TrafficChart({
    super.key,
    required this.history,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrafficChartPainter(history: history),
      ),
    );
  }
}

class _TrafficChartPainter extends CustomPainter {
  final List<Traffic> history;

  _TrafficChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) {
      // 数据不足时画轻量网格占位
      _drawGrid(canvas, size, 0);
      return;
    }

    // 找出历史最大值，用于 Y 轴归一化缩放
    int maxVal = 1024 * 100; // 最低 100 KB/s 基准线
    for (final t in history) {
      maxVal = max(maxVal, max(t.up, t.down));
    }

    _drawGrid(canvas, size, maxVal);

    // 绘制下行速率曲线 (绿色)
    _drawCurve(
      canvas: canvas,
      size: size,
      values: history.map((t) => t.down).toList(),
      maxVal: maxVal,
      lineColor: AppTheme.secondary,
      fillGradient: LinearGradient(
        colors: [
          AppTheme.secondary.withValues(alpha: 0.35),
          AppTheme.secondary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    // 绘制上行速率曲线 (紫色)
    _drawCurve(
      canvas: canvas,
      size: size,
      values: history.map((t) => t.up).toList(),
      maxVal: maxVal,
      lineColor: AppTheme.primary,
      fillGradient: LinearGradient(
        colors: [
          AppTheme.primary.withValues(alpha: 0.25),
          AppTheme.primary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  void _drawGrid(Canvas canvas, Size size, int maxVal) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 水平分割线 3 条
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawCurve({
    required Canvas canvas,
    required Size size,
    required List<int> values,
    required int maxVal,
    required Color lineColor,
    required Gradient fillGradient,
  }) {
    if (values.length < 2) return;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      // 归一化 Y 轴高度 (留出 10% 顶部间距)
      final normalized = values[i] / maxVal;
      final y = size.height - (normalized * size.height * 0.85);
      points.add(Offset(x, y));
    }

    // 构造平滑贝塞尔曲线路径
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 绘制底部闭合填充渐变
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 绘制曲折发光线条
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // 发光外描边
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) => true;
}
