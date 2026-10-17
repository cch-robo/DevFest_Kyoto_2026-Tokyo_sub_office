import 'dart:ui';
import 'package:flutter/material.dart';

enum GameStatus {
  ready,
  playing,
  paused,
  gameOver,
  gameClear,
}

class Paddle {
  double x; // パドル中心のX座標
  final double y; // パドル上面のY座標
  final double width;
  final double height;

  Paddle({
    required this.x,
    required this.y,
    this.width = 90.0,
    this.height = 16.0,
  });

  Rect get rect => Rect.fromCenter(
        center: Offset(x, y + height / 2),
        width: width,
        height: height,
      );

  void move(double deltaX, double minX, double maxX) {
    x = (x + deltaX).clamp(minX + width / 2, maxX - width / 2);
  }

  void moveTo(double targetX, double minX, double maxX) {
    x = targetX.clamp(minX + width / 2, maxX - width / 2);
  }
}

class Ball {
  double x;
  double y;
  double vx;
  double vy;
  final double radius;
  final List<Offset> trail = [];
  static const int maxTrail = 5;

  Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = 7.0,
  });

  double get speed => (vx * vx + vy * vy);

  void update(double dt) {
    trail.insert(0, Offset(x, y));
    if (trail.length > maxTrail) {
      trail.removeLast();
    }

    x += vx * dt;
    y += vy * dt;
  }
}

class Block {
  final Rect rect;
  final Color color;
  final int points;
  int hitPoints;
  bool isDestroyed = false;

  Block({
    required this.rect,
    required this.color,
    required this.points,
    this.hitPoints = 1,
  });

  bool hit() {
    hitPoints--;
    if (hitPoints <= 0) {
      isDestroyed = true;
      return true; // 破壊された
    }
    return false;
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double life; // 1.0 -> 0.0
  final double decay;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.size = 4.0,
    this.life = 1.0,
    this.decay = 2.0,
  });

  bool update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 300 * dt; // 重力
    life -= decay * dt;
    return life > 0;
  }
}
