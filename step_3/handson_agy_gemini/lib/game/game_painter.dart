import 'package:flutter/material.dart';
import 'game_models.dart';

class GamePainter extends CustomPainter {
  final List<Block> blocks;
  final Paddle? paddle;
  final Ball? ball;
  final List<Particle> particles;
  final double gameWidth;
  final double gameHeight;

  GamePainter({
    required this.blocks,
    required this.paddle,
    required this.ball,
    required this.particles,
    required this.gameWidth,
    required this.gameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / gameWidth;
    final scaleY = size.height / gameHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    _drawBackground(canvas);
    _drawWalls(canvas);
    _drawBlocks(canvas);
    _drawPaddle(canvas);
    _drawBall(canvas);
    _drawParticles(canvas);

    canvas.restore();
  }

  void _drawBackground(Canvas canvas) {
    // サイバーパンク・ネオン風のダーク背景
    final rect = Rect.fromLTWH(0, 0, gameWidth, gameHeight);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A), // Slate 900
          Color(0xFF0B0F19), // Darker slate
          Color(0xFF030712), // Deep black
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // うっすらグリッド線を描画してレトロアーケード感を演出
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const gridStep = 40.0;
    for (double x = 0; x <= gameWidth; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, gameHeight), gridPaint);
    }
    for (double y = 0; y <= gameHeight; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(gameWidth, y), gridPaint);
    }
  }

  void _drawWalls(Canvas canvas) {
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 上・左・右の壁のガイドライン
    final path = Path()
      ..moveTo(0, gameHeight)
      ..lineTo(0, 0)
      ..lineTo(gameWidth, 0)
      ..lineTo(gameWidth, gameHeight);
    canvas.drawPath(path, borderPaint);
  }

  void _drawBlocks(Canvas canvas) {
    for (final block in blocks) {
      if (block.isDestroyed) continue;

      final rrect = RRect.fromRectAndRadius(
        block.rect,
        const Radius.circular(5.0),
      );

      // ブロック本体のグラデーション塗りつぶし
      final blockGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          block.color,
          block.color.withValues(alpha: 0.75),
        ],
      );

      final fillPaint = Paint()
        ..shader = blockGradient.createShader(block.rect);
      canvas.drawRRect(rrect, fillPaint);

      // ハイライト線 (上端に光沢を付ける)
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final highlightPath = Path()
        ..moveTo(block.rect.left + 4, block.rect.top + 2)
        ..lineTo(block.rect.right - 4, block.rect.top + 2);
      canvas.drawPath(highlightPath, highlightPaint);

      // 外枠
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  void _drawPaddle(Canvas canvas) {
    if (paddle == null) return;

    final rrect = RRect.fromRectAndRadius(
      paddle!.rect,
      const Radius.circular(8.0),
    );

    // ネオングロー効果
    final glowPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, glowPaint);

    // パドル本体グラデーション
    final paddlePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF67E8F9), // Light cyan
          Color(0xFF06B6D4), // Cyan
          Color(0xFF0891B2), // Dark cyan
        ],
      ).createShader(paddle!.rect);
    canvas.drawRRect(rrect, paddlePaint);

    // パドル中央ライン（ターゲットの目安）
    final centerMarkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(paddle!.x, paddle!.y + 3),
      Offset(paddle!.x, paddle!.y + paddle!.height - 3),
      centerMarkPaint,
    );
  }

  void _drawBall(Canvas canvas) {
    if (ball == null) return;

    // トレイル（残像）の描画
    for (int i = 0; i < ball!.trail.length; i++) {
      final trailPos = ball!.trail[i];
      final trailFactor = 1.0 - (i / ball!.trail.length);
      final trailPaint = Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.25 * trailFactor)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(trailPos, ball!.radius * trailFactor, trailPaint);
    }

    // ボールのグロー
    final glowPaint = Paint()
      ..color = const Color(0xFFFB7185).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(ball!.x, ball!.y), ball!.radius + 2, glowPaint);

    // ボール本体
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Colors.white,
          Color(0xFFFB7185),
          Color(0xFFE11D48),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(ball!.x, ball!.y),
          radius: ball!.radius,
        ),
      );
    canvas.drawCircle(Offset(ball!.x, ball!.y), ball!.radius, ballPaint);
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
