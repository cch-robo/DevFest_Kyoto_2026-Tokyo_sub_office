import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'breakout_game_controller.dart';

class NeonPainter extends CustomPainter {
  final BreakoutGameController controller;
  final double animationValue; // For pulse / neon animations

  NeonPainter({
    required this.controller,
    required this.animationValue,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Apply screen shake
    if (controller.screenShake > 0) {
      final shake = controller.screenShake * 10.0;
      final rng = Random();
      final dx = (rng.nextDouble() - 0.5) * shake;
      final dy = (rng.nextDouble() - 0.5) * shake;
      canvas.translate(dx, dy);
    }

    _drawBackground(canvas, size);
    _drawGridLines(canvas, size);
    _drawBorders(canvas, size);
    if (controller.hasShield) {
      _drawShield(canvas, size);
    }
    _drawBlocks(canvas);
    _drawDroppingPowerUps(canvas);
    _drawPaddle(canvas);
    _drawBalls(canvas);
    _drawParticles(canvas);
    _drawFloatingTexts(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF060913),
          Color(0xFF0A0F24),
          Color(0xFF04060F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawBorders(Canvas canvas, Size size) {
    // Outer glow for side and top borders
    final borderGlow = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(60)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final borderCore = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path, borderGlow);
    canvas.drawPath(path, borderCore);
  }

  void _drawShield(Canvas canvas, Size size) {
    final pulse = 0.7 + 0.3 * sin(animationValue * 2 * pi * 3);
    final y = size.height - 10.0;

    // Glowing laser beam
    final glowPaint = Paint()
      ..color = const Color(0xFF2979FF).withAlpha((150 * pulse).toInt())
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final corePaint = Paint()
      ..color = const Color(0xFF82B1FF)
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), corePaint);
  }

  void _drawBlocks(Canvas canvas) {
    for (final block in controller.blocks) {
      if (block.isDestroyed) continue;

      final rect = block.rect;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));
      final color = block.displayColor;

      // Glow outline
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(rrect, glowPaint);

      // Block Fill with subtle vertical gradient
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withAlpha(220),
            color.withAlpha(140),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, fillPaint);

      // Inner Highlight / Border
      final coreBorder = Paint()
        ..color = Colors.white.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, coreBorder);

      // Special Block Indicators
      if (block.type == BlockType.bomb) {
        // Pulsing core for bomb
        final pulse = 0.5 + 0.5 * sin(animationValue * 2 * pi * 4);
        final bombCore = Paint()
          ..color = Colors.yellow.withAlpha((180 * pulse).toInt())
          ..style = PaintingStyle.fill;
        canvas.drawCircle(rect.center, 5.0, bombCore);
      } else if (block.type == BlockType.powerup) {
        // Diamond icon for power-up
        final iconPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        final diamond = Path()
          ..moveTo(rect.center.dx, rect.center.dy - 4.5)
          ..lineTo(rect.center.dx + 4.5, rect.center.dy)
          ..lineTo(rect.center.dx, rect.center.dy + 4.5)
          ..lineTo(rect.center.dx - 4.5, rect.center.dy)
          ..close();
        canvas.drawPath(diamond, iconPaint);
      } else if (block.type == BlockType.hard || block.type == BlockType.iron) {
        // Cracks / reinforcement lines
        final crackPaint = Paint()
          ..color = Colors.white.withAlpha(150)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(rect.left + 5, rect.top + 4),
          Offset(rect.right - 5, rect.bottom - 4),
          crackPaint,
        );
      }
    }
  }

  void _drawPaddle(Canvas canvas) {
    final paddle = controller.paddle;
    final rect = paddle.rect;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7.0));

    // Outer glow
    final glowPaint = Paint()
      ..color = paddle.color.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawRRect(rrect, glowPaint);

    // Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          paddle.color,
          paddle.color.withAlpha(160),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bodyPaint);

    // Center Energy Core Strip
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + 15, rect.center.dy),
      Offset(rect.right - 15, rect.center.dy),
      corePaint,
    );
  }

  void _drawBalls(Canvas canvas) {
    final isFire = controller.isPowerUpActive(PowerUpType.fireBall);

    for (final ball in controller.balls) {
      // Trail
      for (int i = 0; i < ball.trail.length; i++) {
        final tPos = ball.trail[i];
        final factor = (1.0 - (i / ball.trail.length));
        final trailPaint = Paint()
          ..color = (isFire ? const Color(0xFFFF3D00) : const Color(0xFF00E5FF))
              .withAlpha((140 * factor).toInt())
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tPos, ball.radius * factor * 0.8, trailPaint);
      }

      // Ball Outer Glow
      final glowColor = isFire ? const Color(0xFFFF3D00) : const Color(0xFF00E5FF);
      final glowPaint = Paint()
        ..color = glowColor.withAlpha(150)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(ball.position, ball.radius + 3.0, glowPaint);

      // Ball Core
      final coreColor = isFire ? const Color(0xFFFFD600) : Colors.white;
      final corePaint = Paint()
        ..color = coreColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ball.position, ball.radius, corePaint);
    }
  }

  void _drawDroppingPowerUps(Canvas canvas) {
    for (final p in controller.droppingPowerUps) {
      final color = p.type.color;

      // Glow circle
      final glowPaint = Paint()
        ..color = color.withAlpha(100)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(p.position, p.radius + 2, glowPaint);

      // Capsule Background
      final bgPaint = Paint()
        ..color = const Color(0xFF10192A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, bgPaint);

      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(p.position, p.radius, borderPaint);

      // Draw Letter Indicator in Capsule
      final letter = p.type.label.isNotEmpty ? p.type.label[0] : 'P';
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: color,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(p.position.dx - textPainter.width / 2, p.position.dy - textPainter.height / 2),
      );
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in controller.particles) {
      final alpha = (255 * (p.life / p.maxLife)).clamp(0, 255).toInt();
      final paint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: p.position, width: p.size, height: p.size),
        paint,
      );
    }
  }

  void _drawFloatingTexts(Canvas canvas) {
    for (final t in controller.floatingTexts) {
      final alpha = (255 * (t.life / t.maxLife)).clamp(0, 255).toInt();
      final textPainter = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            color: t.color.withAlpha(alpha),
            fontSize: t.fontSize,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: t.color.withAlpha((alpha * 0.8).toInt()),
                blurRadius: 8.0,
              ),
              const Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2.0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(t.position.dx - textPainter.width / 2, t.position.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NeonPainter oldDelegate) {
    return true;
  }
}
