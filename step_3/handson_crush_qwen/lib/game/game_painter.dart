import 'package:flutter/material.dart';

import 'game_models.dart';

/// ゲーム画面を描画する `CustomPainter`。
class GamePainter extends CustomPainter {
  /// 描画に使用するブロック一覧。
  final List<Block> blocks;

  /// パドル（未生成の場合は `null`）。
  final Paddle? paddle;

  /// ボール（未生成の場合は `null`）。
  final Ball? ball;

  /// パーティクル一覧。
  final List<Particle> particles;

  /// 仮想画面幅。
  final double gameWidth;

  /// 仮想画面高さ。
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
    // 座標を仮想座標系へ変換するためスケールを求める。
    final double scaleX = size.width / gameWidth;
    final double scaleY = size.height / gameHeight;

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

  /// 背景（グラデーション + グリッド線）。
  void _drawBackground(Canvas canvas) {
    final Rect bounds = Rect.fromLTWH(0, 0, gameWidth, gameHeight);

    final Paint backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F172A),
          Color(0xFF0B0F19),
          Color(0xFF030712),
        ],
      ).createShader(bounds)
    ;

    canvas.drawRect(bounds, backgroundPaint);

    // グリッド線
    final Paint gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4);

    const double step = 40.0;
    for (double x = 0; x <= gameWidth; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, gameHeight), gridPaint);
    }
    for (double y = 0; y <= gameHeight; y += step) {
      canvas.drawLine(Offset(0, y), Offset(gameWidth, y), gridPaint);
    }
  }

  /// 壁ガイドライン（左・上・右のコの字）。
  void _drawWalls(Canvas canvas) {
    final Paint wallPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3);

    final Path path = Path()
      ..moveTo(0, gameHeight)
      ..lineTo(0, 0)
      ..lineTo(gameWidth, 0)
      ..lineTo(gameWidth, gameHeight);

    canvas.drawPath(path, wallPaint);
  }

  /// ブロックを描画する。
  void _drawBlocks(Canvas canvas) {
    for (final block in blocks) {
      if (block.isDestroyed) {
        continue;
      }

      final RRect rrect = RRect.fromRectAndRadius(
          block.rect, const Radius.circular(5.0));

      // 塗りつぶし（角方向グラデーション）
      final Paint blockPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            block.color,
            block.color.withValues(alpha: 0.75),
          ],
        ).createShader(block.rect)
      ;
      canvas.drawRRect(rrect, blockPaint);

      // ハイライト線
      final Paint highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.45);
      canvas.drawLine(
        Offset(block.rect.left + 4, block.rect.top + 2),
        Offset(block.rect.right - 4, block.rect.top + 2),
        highlightPaint,
      );

      // 外枠
      final Paint borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.25);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  /// パドルを描画する。
  void _drawPaddle(Canvas canvas) {
    final Paddle? p = paddle;
    if (p == null) {
      return;
    }

    final RRect rrect =
        RRect.fromRectAndRadius(p.rect, const Radius.circular(8.0));

    // グロー
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, glowPaint);

    // 本体（縦方向グラデーション）
    final Paint bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF67E8F9),
          Color(0xFF06B6D4),
          Color(0xFF0891B2),
        ],
      ).createShader(p.rect)
    ;
    canvas.drawRRect(rrect, bodyPaint);

    // センターマーカー（縦線）
    final Paint markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawLine(
      Offset(p.x, p.y + 3),
      Offset(p.x, p.y + p.height - 3),
      markerPaint,
    );
  }

  /// ボールを描画する。
  void _drawBall(Canvas canvas) {
    final Ball? b = ball;
    if (b == null) {
      return;
    }

    // 残像
    for (int i = 0; i < b.trail.length; i++) {
      final trailFactor = 1.0 - (i / b.trail.length);
      final Paint trailPaint = Paint()
        ..color = const Color(0xFFF43F5E).withValues(alpha: 0.25 * trailFactor);
      canvas.drawCircle(b.trail[i], b.radius * trailFactor, trailPaint);
    }

    // グロー
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFB7185).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(b.x, b.y), b.radius + 2, glowPaint);

    // 本体（放射状グラデーション）
    final Paint bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.white,
          Color(0xFFFB7185),
          Color(0xFFE11D48),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(b.x, b.y), radius: b.radius))
    ;
    canvas.drawCircle(Offset(b.x, b.y), b.radius, bodyPaint);
  }

  /// パーティクルを描画する。
  void _drawParticles(Canvas canvas) {
    for (final particle in particles) {
      final Paint particlePaint = Paint()
        ..color = particle.color.withValues(alpha: particle.life.clamp(0.0, 1.0).toDouble());
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * particle.life,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
