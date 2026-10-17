import 'dart:ui';
import 'package:flutter/material.dart';

/// ゲームの状態。
enum GameStatus {
  ready,
  playing,
  paused,
  gameOver,
  gameClear,
}

/// パドル。
class Paddle {
  /// パドル中心の X 座標（可変）
  double x;

  /// パドル上面の Y 座標
  final double y;

  final double width;
  final double height;

  Paddle({
    required this.x,
    required this.y,
    this.width = 90.0,
    this.height = 16.0,
  });

  /// パドルの矩形
  Rect get rect => Rect.fromCenter(
        center: Offset(x, y + height / 2),
        width: width,
        height: height,
      );

  /// 相対量だけ移動し、範囲内にクランプする。
  void move(double deltaX, double minX, double maxX) {
    x = (x + deltaX).clamp(minX + width / 2, maxX - width / 2);
  }

  /// 目標 X 座標へ移動し、範囲内にクランプする。
  void moveTo(double targetX, double minX, double maxX) {
    x = targetX.clamp(minX + width / 2, maxX - width / 2);
  }
}

/// ボール。
class Ball {
  /// 座標 (px)
  double x;
  double y;

  /// 速度 (px/秒)
  double vx;
  double vy;

  final double radius;

  /// 残像の座標履歴
  final List<Offset> trail = [];

  /// 残像の最大件数
  static const int maxTrail = 5;

  Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = 7.0,
  });

  /// 速度の二乗値（平方根は取らない）
  double get speed => vx * vx + vy * vy;

  /// 一フレーム分更新する。
  void update(double dt) {
    // 1. 現在位置を trail の先頭に挿入
    trail.insert(0, Offset(x, y));
    // 2. 最大件数を超えたら末尾を削除
    if (trail.length > maxTrail) {
      trail.removeLast();
    }
    // 3. 位置を更新
    x += vx * dt;
    y += vy * dt;
  }
}

/// ブロック。
class Block {
  final Rect rect;
  final Color color;
  final int points;

  /// 残りヒット許容数
  int hitPoints;

  /// 破壊済みフラグ
  bool isDestroyed = false;

  Block({
    required this.rect,
    required this.color,
    required this.points,
    this.hitPoints = 1,
  });

  /// 1 回のヒット処理。破壊されれば `true` を返す。
  bool hit() {
    hitPoints--;
    if (hitPoints <= 0) {
      isDestroyed = true;
      return true;
    }
    return false;
  }
}

/// パーティクル。
class Particle {
  double x;
  double y;
  double vx;
  double vy;

  final Color color;
  final double size;

  /// 残存寿命 (1.0 → 0.0 に減少)
  double life;

  /// 寿命の減衰速度
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

  /// 一フレーム分更新し、生存していれば `true` を返す。
  bool update(double dt) {
    // 1. 位置を更新
    x += vx * dt;
    y += vy * dt;
    // 2. 重力
    vy += 300 * dt;
    // 3. 寿命を減衰
    life -= decay * dt;
    // 4. 生存判定
    return life > 0;
  }
}
