import 'package:flutter/material.dart';

/// Types of blocks in the game
enum BlockType {
  normal,      // Standard block, 1 hit to break
  hard,        // Reinforced block, 2 hits to break
  iron,        // Iron block, 3 hits to break
  bomb,        // Explodes and destroys adjacent blocks
  powerup,     // Always drops a power-up
}

/// Available power-up types
enum PowerUpType {
  multiBall,   // Spawns 2 additional balls
  widePaddle,  // Increases paddle width for a limited time
  fireBall,    // Ball penetrates blocks without bouncing for a limited time
  shield,      // Laser shield at the bottom prevents one ball loss
  slowBall,    // Temporarily slows down all balls
  extraLife,   // Restores 1 life
}

extension PowerUpTypeExtension on PowerUpType {
  String get label {
    switch (this) {
      case PowerUpType.multiBall:
        return 'MULTI BALL';
      case PowerUpType.widePaddle:
        return 'WIDE PADDLE';
      case PowerUpType.fireBall:
        return 'FIRE BALL';
      case PowerUpType.shield:
        return 'LASER SHIELD';
      case PowerUpType.slowBall:
        return 'SLOW MOTION';
      case PowerUpType.extraLife:
        return '+1 LIFE';
    }
  }

  IconData get icon {
    switch (this) {
      case PowerUpType.multiBall:
        return Icons.auto_awesome_motion;
      case PowerUpType.widePaddle:
        return Icons.swap_horiz;
      case PowerUpType.fireBall:
        return Icons.local_fire_department;
      case PowerUpType.shield:
        return Icons.shield;
      case PowerUpType.slowBall:
        return Icons.speed;
      case PowerUpType.extraLife:
        return Icons.favorite;
    }
  }

  Color get color {
    switch (this) {
      case PowerUpType.multiBall:
        return const Color(0xFF00E5FF); // Neon Cyan
      case PowerUpType.widePaddle:
        return const Color(0xFF76FF03); // Neon Lime
      case PowerUpType.fireBall:
        return const Color(0xFFFF3D00); // Neon Orange/Red
      case PowerUpType.shield:
        return const Color(0xFF2979FF); // Electric Blue
      case PowerUpType.slowBall:
        return const Color(0xFFFFD600); // Bright Yellow
      case PowerUpType.extraLife:
        return const Color(0xFFFF1744); // Neon Crimson
    }
  }
}

/// Ball representation
class Ball {
  Offset position;
  Offset velocity;
  double radius;
  Color color;
  bool isStuckToPaddle;
  List<Offset> trail;
  static const int maxTrailLength = 8;

  Ball({
    required this.position,
    required this.velocity,
    this.radius = 6.5,
    this.color = const Color(0xFFFFFFFF),
    this.isStuckToPaddle = false,
  }) : trail = [];

  void recordTrail() {
    trail.insert(0, position);
    if (trail.length > maxTrailLength) {
      trail.removeLast();
    }
  }
}

/// Paddle representation
class Paddle {
  double x;
  double y;
  double width;
  double height;
  Color color;
  double targetX;
  double speed;

  Paddle({
    required this.x,
    required this.y,
    this.width = 90.0,
    this.height = 14.0,
    this.color = const Color(0xFF00F5FF),
    this.speed = 0.0,
  }) : targetX = x;

  Rect get rect => Rect.fromLTWH(x - width / 2, y - height / 2, width, height);
}

/// Block representation
class Block {
  final int id;
  final Rect rect;
  final Color baseColor;
  final BlockType type;
  final PowerUpType? dropPowerUp;
  final int scoreValue;
  int health;
  final int maxHealth;

  Block({
    required this.id,
    required this.rect,
    required this.baseColor,
    this.type = BlockType.normal,
    this.dropPowerUp,
    this.scoreValue = 100,
    this.health = 1,
    this.maxHealth = 1,
  });

  bool get isDestroyed => health <= 0;

  Color get displayColor {
    if (type == BlockType.bomb) {
      return const Color(0xFFFF1744);
    }
    if (maxHealth > 1) {
      // Darken or shift brightness based on remaining health
      final factor = health / maxHealth;
      return baseColor.withAlpha((140 + (115 * factor)).toInt());
    }
    return baseColor;
  }
}

/// Dropping Power-up Capsule
class DroppingPowerUp {
  Offset position;
  final PowerUpType type;
  final double radius;
  final double speed;

  DroppingPowerUp({
    required this.position,
    required this.type,
    this.radius = 12.0,
    this.speed = 130.0,
  });

  Rect get hitBox => Rect.fromCircle(center: position, radius: radius);
}

/// Particle for visual effects
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;
  final double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  }) : maxLife = life;

  bool get isAlive => life > 0;

  void update(double dt) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * 0.98, velocity.dy * 0.98 + 40 * dt); // air drag + gravity
    life -= dt;
  }
}

/// Floating score / popup message
class FloatingText {
  Offset position;
  final String text;
  final Color color;
  double life;
  final double maxLife;
  final double fontSize;

  FloatingText({
    required this.position,
    required this.text,
    required this.color,
    this.life = 0.9,
    this.fontSize = 15.0,
  }) : maxLife = life;

  bool get isAlive => life > 0;

  void update(double dt) {
    position = Offset(position.dx, position.dy - 35 * dt); // float upward
    life -= dt;
  }
}

/// Active power-up effect with a timer
class ActivePowerUp {
  final PowerUpType type;
  double remainingSeconds;
  final double totalSeconds;

  ActivePowerUp({
    required this.type,
    required this.totalSeconds,
  }) : remainingSeconds = totalSeconds;

  double get progress => (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
}

/// Overall Game State Status
enum GameStatus {
  title,
  ready,
  playing,
  paused,
  stageClear,
  gameOver,
  gameComplete,
}
