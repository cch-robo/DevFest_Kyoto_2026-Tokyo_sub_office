import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';
import '../levels/stage_data.dart';

class BreakoutGameController extends ChangeNotifier {
  static const double fieldWidth = StageBuilder.fieldWidth;
  static const double fieldHeight = StageBuilder.fieldHeight;

  // Game Progression
  GameStatus status = GameStatus.title;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  int currentStage = 1;
  int combo = 0;

  // Entities
  late Paddle paddle;
  final List<Ball> balls = [];
  final List<Block> blocks = [];
  final List<DroppingPowerUp> droppingPowerUps = [];
  final List<ActivePowerUp> activePowerUps = [];
  final List<Particle> particles = [];
  final List<FloatingText> floatingTexts = [];

  // Power-up States
  bool hasShield = false;
  double defaultPaddleWidth = 85.0;
  double defaultBallSpeed = 330.0;
  double currentBallSpeed = 330.0;

  // Screen shake
  double screenShake = 0.0;
  final Random _rng = Random();

  // Keyboard movement flags
  bool moveLeft = false;
  bool moveRight = false;
  final double keyboardPaddleSpeed = 480.0;

  BreakoutGameController() {
    _initPaddle();
    _loadStage(1);
  }

  void _initPaddle() {
    paddle = Paddle(
      x: fieldWidth / 2,
      y: fieldHeight - 55,
      width: defaultPaddleWidth,
      height: 14.0,
      color: const Color(0xFF00F5FF),
    );
  }

  /// Start a fresh new game from stage 1
  void startNewGame() {
    score = 0;
    lives = 3;
    currentStage = 1;
    combo = 0;
    _initPaddle();
    activePowerUps.clear();
    droppingPowerUps.clear();
    hasShield = false;
    currentBallSpeed = defaultBallSpeed;

    _loadStage(1);
    _spawnReadyBall();
    status = GameStatus.ready;
    notifyListeners();
  }

  /// Advance to the next stage
  void nextStage() {
    if (currentStage >= StageBuilder.totalStages) {
      status = GameStatus.gameComplete;
      notifyListeners();
      return;
    }

    currentStage++;
    combo = 0;
    activePowerUps.clear();
    droppingPowerUps.clear();
    currentBallSpeed = defaultBallSpeed + (currentStage - 1) * 20.0;
    _initPaddle();
    _loadStage(currentStage);
    _spawnReadyBall();
    status = GameStatus.ready;
    notifyListeners();
  }

  /// Load level blocks
  void _loadStage(int stageNum) {
    blocks.clear();
    final stageConfig = StageBuilder.getStage(stageNum);
    blocks.addAll(stageConfig.blocks);
  }

  /// Spawn ball stuck to paddle ready for launch
  void _spawnReadyBall() {
    balls.clear();
    balls.add(Ball(
      position: Offset(paddle.x, paddle.y - paddle.height / 2 - 7.5),
      velocity: const Offset(0, 0),
      isStuckToPaddle: true,
      color: const Color(0xFFFFFFFF),
    ));
  }

  /// Launch the ball from paddle
  void launchBall() {
    if (status != GameStatus.ready && status != GameStatus.playing) return;

    for (final ball in balls) {
      if (ball.isStuckToPaddle) {
        ball.isStuckToPaddle = false;
        // Launch upwards with a slight random or paddle-biased horizontal angle
        final angleOffset = (_rng.nextDouble() - 0.5) * 0.5; // ~ -15 to +15 deg
        final speed = currentBallSpeed;
        ball.velocity = Offset(speed * sin(angleOffset), -speed * cos(angleOffset));
      }
    }
    status = GameStatus.playing;
    notifyListeners();
  }

  /// Toggle pause / resume
  void togglePause() {
    if (status == GameStatus.playing) {
      status = GameStatus.paused;
      notifyListeners();
    } else if (status == GameStatus.paused) {
      status = GameStatus.playing;
      notifyListeners();
    }
  }

  /// Update paddle target position from touch/mouse
  void setPaddleTargetX(double x) {
    paddle.targetX = x.clamp(paddle.width / 2, fieldWidth - paddle.width / 2);
  }

  /// Main Game Loop Step
  void update(double dt) {
    if (status != GameStatus.playing && status != GameStatus.ready) return;

    // Clamp delta time to avoid large jumps
    final clampedDt = dt.clamp(0.0, 0.033);

    // 1. Handle Paddle Movement
    _updatePaddle(clampedDt);

    // 2. Update Active Power-ups
    _updateActivePowerUps(clampedDt);

    // 3. Update Screen Shake
    if (screenShake > 0) {
      screenShake = max(0.0, screenShake - clampedDt * 8.0);
    }

    // 4. Update Visual Effects (Particles, Floating Texts)
    _updateEffects(clampedDt);

    // If ready, ball simply follows paddle
    if (status == GameStatus.ready) {
      for (final ball in balls) {
        if (ball.isStuckToPaddle) {
          ball.position = Offset(paddle.x, paddle.y - paddle.height / 2 - ball.radius);
        }
      }
      notifyListeners();
      return;
    }

    // 5. Update Dropping Power-up capsules
    _updateDroppingPowerUps(clampedDt);

    // 6. Substep physics for balls to prevent tunneling
    const int subSteps = 3;
    final subDt = clampedDt / subSteps;
    for (int step = 0; step < subSteps; step++) {
      _updateBallsPhysics(subDt);
    }

    // 7. Check if all balls lost
    if (balls.isEmpty) {
      _handleLifeLost();
      notifyListeners();
      return;
    }

    // 8. Check Stage Clear condition
    if (blocks.every((b) => b.isDestroyed)) {
      _handleStageClear();
    }

    notifyListeners();
  }

  void _updatePaddle(double dt) {
    // Keyboard steering
    if (moveLeft && !moveRight) {
      paddle.targetX -= keyboardPaddleSpeed * dt;
    } else if (moveRight && !moveLeft) {
      paddle.targetX += keyboardPaddleSpeed * dt;
    }
    paddle.targetX = paddle.targetX.clamp(paddle.width / 2, fieldWidth - paddle.width / 2);

    // Smooth lerp to targetX
    final oldX = paddle.x;
    paddle.x += (paddle.targetX - paddle.x) * (1.0 - exp(-22.0 * dt));
    paddle.x = paddle.x.clamp(paddle.width / 2, fieldWidth - paddle.width / 2);
    paddle.speed = (paddle.x - oldX) / dt;
  }

  void _updateActivePowerUps(double dt) {
    for (int i = activePowerUps.length - 1; i >= 0; i--) {
      final ap = activePowerUps[i];
      ap.remainingSeconds -= dt;
      if (ap.remainingSeconds <= 0) {
        // Expired
        if (ap.type == PowerUpType.widePaddle) {
          paddle.width = defaultPaddleWidth;
        } else if (ap.type == PowerUpType.slowBall) {
          currentBallSpeed = defaultBallSpeed + (currentStage - 1) * 20.0;
        }
        activePowerUps.removeAt(i);
      }
    }
  }

  bool isPowerUpActive(PowerUpType type) {
    return activePowerUps.any((p) => p.type == type);
  }

  void _updateDroppingPowerUps(double dt) {
    final paddleRect = paddle.rect;

    for (int i = droppingPowerUps.length - 1; i >= 0; i--) {
      final p = droppingPowerUps[i];
      p.position = Offset(p.position.dx, p.position.dy + p.speed * dt);

      // Check collision with paddle
      if (paddleRect.overlaps(p.hitBox)) {
        _applyPowerUp(p.type, p.position);
        droppingPowerUps.removeAt(i);
        continue;
      }

      // Fell off screen
      if (p.position.dy > fieldHeight + 20) {
        droppingPowerUps.removeAt(i);
      }
    }
  }

  void _applyPowerUp(PowerUpType type, Offset position) {
    _haptic(HapticFeedbackType.medium);
    _addFloatingText(position, type.label, type.color, fontSize: 16.0);
    _spawnBurstParticles(position, type.color, count: 18);
    score += 250;

    switch (type) {
      case PowerUpType.multiBall:
        final currentBalls = List<Ball>.from(balls);
        for (final b in currentBalls) {
          final speed = b.velocity.distance;
          final angle = atan2(b.velocity.dy, b.velocity.dx);
          // Spawn two extra balls split by +- 30 degrees
          balls.add(Ball(
            position: b.position,
            velocity: Offset(speed * cos(angle + 0.5), speed * sin(angle + 0.5)),
            color: type.color,
          ));
          balls.add(Ball(
            position: b.position,
            velocity: Offset(speed * cos(angle - 0.5), speed * sin(angle - 0.5)),
            color: type.color,
          ));
        }
        break;

      case PowerUpType.widePaddle:
        paddle.width = defaultPaddleWidth * 1.5;
        _addOrResetActivePowerUp(type, 14.0);
        break;

      case PowerUpType.fireBall:
        _addOrResetActivePowerUp(type, 10.0);
        break;

      case PowerUpType.shield:
        hasShield = true;
        _addFloatingText(
          Offset(fieldWidth / 2, fieldHeight - 25),
          'SHIELD ACTIVE',
          type.color,
        );
        break;

      case PowerUpType.slowBall:
        currentBallSpeed = max(240.0, defaultBallSpeed * 0.75);
        for (final b in balls) {
          b.velocity = (b.velocity / b.velocity.distance) * currentBallSpeed;
        }
        _addOrResetActivePowerUp(type, 12.0);
        break;

      case PowerUpType.extraLife:
        lives = min(5, lives + 1);
        break;
    }
  }

  void _addOrResetActivePowerUp(PowerUpType type, double duration) {
    final existing = activePowerUps.where((p) => p.type == type).firstOrNull;
    if (existing != null) {
      existing.remainingSeconds = duration;
    } else {
      activePowerUps.add(ActivePowerUp(type: type, totalSeconds: duration));
    }
  }

  void _updateBallsPhysics(double dt) {
    final isFire = isPowerUpActive(PowerUpType.fireBall);
    final paddleRect = paddle.rect;

    for (int bIdx = balls.length - 1; bIdx >= 0; bIdx--) {
      final ball = balls[bIdx];
      if (ball.isStuckToPaddle) continue;

      ball.position += ball.velocity * dt;
      ball.recordTrail();

      // Wall Collisions
      // Left Wall
      if (ball.position.dx - ball.radius <= 0) {
        ball.position = Offset(ball.radius, ball.position.dy);
        ball.velocity = Offset(ball.velocity.dx.abs(), ball.velocity.dy);
        _spawnWallHitParticles(ball.position, const Color(0xFF00E5FF));
      }
      // Right Wall
      else if (ball.position.dx + ball.radius >= fieldWidth) {
        ball.position = Offset(fieldWidth - ball.radius, ball.position.dy);
        ball.velocity = Offset(-ball.velocity.dx.abs(), ball.velocity.dy);
        _spawnWallHitParticles(ball.position, const Color(0xFF00E5FF));
      }

      // Top Wall
      if (ball.position.dy - ball.radius <= 0) {
        ball.position = Offset(ball.position.dx, ball.radius);
        ball.velocity = Offset(ball.velocity.dx, ball.velocity.dy.abs());
        _spawnWallHitParticles(ball.position, const Color(0xFF00E5FF));
      }

      // Bottom / Shield Collision
      if (ball.position.dy + ball.radius >= fieldHeight - 12) {
        if (hasShield) {
          // Bounce on shield!
          hasShield = false;
          ball.position = Offset(ball.position.dx, fieldHeight - 13 - ball.radius);
          ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy.abs());
          screenShake = 0.6;
          _spawnBurstParticles(ball.position, const Color(0xFF2979FF), count: 25);
          _addFloatingText(ball.position, 'SHIELD SAVED!', const Color(0xFF2979FF));
          _haptic(HapticFeedbackType.heavy);
        } else if (ball.position.dy >= fieldHeight + 20) {
          // Ball lost
          balls.removeAt(bIdx);
          continue;
        }
      }

      // Paddle Collision
      if (ball.velocity.dy > 0 &&
          ball.position.dy + ball.radius >= paddleRect.top &&
          ball.position.dy - ball.radius <= paddleRect.bottom &&
          ball.position.dx >= paddleRect.left - ball.radius &&
          ball.position.dx <= paddleRect.right + ball.radius) {
        
        // Reset combo when paddle catches the ball
        combo = 0;

        // Position adjustment to not sink into paddle
        ball.position = Offset(ball.position.dx, paddleRect.top - ball.radius);

        // Calculate bounce angle based on hit location relative to paddle center
        final hitFactor = ((ball.position.dx - paddle.x) / (paddle.width / 2)).clamp(-1.0, 1.0);
        // Max angle: 65 degrees
        final maxAngle = 65.0 * (pi / 180.0);
        final bounceAngle = hitFactor * maxAngle;

        // Add subtle slice effect from paddle speed
        final speedBonus = (paddle.speed * 0.05).clamp(-50.0, 50.0);
        double speed = ball.velocity.distance + 4.0; // slight gradual acceleration
        speed = speed.clamp(280.0, 620.0);

        var vx = speed * sin(bounceAngle) + speedBonus;
        var vy = -speed * cos(bounceAngle);

        // Ensure vertical speed is never too flat
        if (vy.abs() < speed * 0.35) {
          vy = -speed * 0.35;
        }

        final newVelocity = Offset(vx, vy);
        ball.velocity = (newVelocity / newVelocity.distance) * speed;

        _spawnBurstParticles(ball.position, paddle.color, count: 12);
        _haptic(HapticFeedbackType.light);
      }

      // Block Collisions
      for (final block in blocks) {
        if (block.isDestroyed) continue;

        if (_checkBallBlockCollision(ball, block.rect)) {
          // Block hit!
          _hitBlock(block, ball, isFire);
          if (!isFire) {
            // Normal bounce
            _reflectBallOffRect(ball, block.rect);
            break; // Stop hitting multiple blocks in a single substep
          }
        }
      }
    }
  }

  bool _checkBallBlockCollision(Ball ball, Rect rect) {
    // Find closest point on rectangle to circle center
    final closestX = ball.position.dx.clamp(rect.left, rect.right);
    final closestY = ball.position.dy.clamp(rect.top, rect.bottom);

    final distanceX = ball.position.dx - closestX;
    final distanceY = ball.position.dy - closestY;
    final distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);

    return distanceSquared <= (ball.radius * ball.radius);
  }

  void _reflectBallOffRect(Ball ball, Rect rect) {
    final overlapLeft = (ball.position.dx + ball.radius) - rect.left;
    final overlapRight = rect.right - (ball.position.dx - ball.radius);
    final overlapTop = (ball.position.dy + ball.radius) - rect.top;
    final overlapBottom = rect.bottom - (ball.position.dy - ball.radius);

    final minOverlapX = min(overlapLeft, overlapRight);
    final minOverlapY = min(overlapTop, overlapBottom);

    if (minOverlapX < minOverlapY) {
      // Horizontal bounce
      ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
    } else {
      // Vertical bounce
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
    }
  }

  void _hitBlock(Block block, Ball ball, bool isFireball) {
    final damage = isFireball ? block.health : 1;
    block.health -= damage;

    if (block.isDestroyed) {
      combo++;
      final comboMultiplier = 1.0 + (combo - 1) * 0.25;
      final pointsEarned = (block.scoreValue * comboMultiplier).toInt();
      score += pointsEarned;
      if (score > highScore) {
        highScore = score;
      }

      final label = combo > 1 ? '+$pointsEarned\nx$combo!' : '+$pointsEarned';
      _addFloatingText(block.rect.center, label, block.displayColor);
      _spawnBurstParticles(block.rect.center, block.baseColor, count: 20);
      _haptic(HapticFeedbackType.medium);

      // Explosive block triggers adjacent destruction
      if (block.type == BlockType.bomb) {
        _triggerBombExplosion(block.rect.center);
      }

      // Check drop powerup
      if (block.dropPowerUp != null) {
        droppingPowerUps.add(DroppingPowerUp(
          position: block.rect.center,
          type: block.dropPowerUp!,
        ));
      }
    } else {
      // Just damaged
      _spawnBurstParticles(block.rect.center, block.displayColor, count: 8);
      _haptic(HapticFeedbackType.light);
    }
  }

  void _triggerBombExplosion(Offset bombCenter) {
    screenShake = 1.0;
    _spawnBurstParticles(bombCenter, const Color(0xFFFF1744), count: 40);
    _spawnBurstParticles(bombCenter, const Color(0xFFFFD600), count: 25);
    _addFloatingText(bombCenter, 'BOOM!!', const Color(0xFFFF3D00), fontSize: 20.0);

    const explosionRadius = 75.0;
    for (final other in blocks) {
      if (other.isDestroyed) continue;
      if ((other.rect.center - bombCenter).distance <= explosionRadius) {
        other.health = 0;
        score += other.scoreValue;
        _spawnBurstParticles(other.rect.center, other.baseColor, count: 12);
        if (other.dropPowerUp != null) {
          droppingPowerUps.add(DroppingPowerUp(
            position: other.rect.center,
            type: other.dropPowerUp!,
          ));
        }
      }
    }
  }

  void _handleLifeLost() {
    lives--;
    combo = 0;
    screenShake = 0.8;
    _haptic(HapticFeedbackType.heavy);

    if (lives <= 0) {
      status = GameStatus.gameOver;
    } else {
      _initPaddle();
      _spawnReadyBall();
      status = GameStatus.ready;
    }
  }

  void _handleStageClear() {
    status = GameStatus.stageClear;
    _spawnBurstParticles(Offset(fieldWidth / 2, fieldHeight / 3), const Color(0xFF00E5FF), count: 50);
    _spawnBurstParticles(Offset(fieldWidth / 2, fieldHeight / 3), const Color(0xFFFF007F), count: 50);
    _haptic(HapticFeedbackType.heavy);
  }

  void _updateEffects(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.update(dt);
      if (!p.isAlive) particles.removeAt(i);
    }

    for (int i = floatingTexts.length - 1; i >= 0; i--) {
      final t = floatingTexts[i];
      t.update(dt);
      if (!t.isAlive) floatingTexts.removeAt(i);
    }
  }

  void _spawnBurstParticles(Offset center, Color color, {int count = 15}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60.0 + _rng.nextDouble() * 160.0;
      final size = 2.0 + _rng.nextDouble() * 3.5;
      final life = 0.4 + _rng.nextDouble() * 0.4;

      particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        size: size,
        life: life,
      ));
    }
  }

  void _spawnWallHitParticles(Offset position, Color color) {
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 40.0 + _rng.nextDouble() * 80.0;
      particles.add(Particle(
        position: position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        size: 2.0,
        life: 0.25,
      ));
    }
  }

  void _addFloatingText(Offset position, String text, Color color, {double fontSize = 14.0}) {
    floatingTexts.add(FloatingText(
      position: position,
      text: text,
      color: color,
      fontSize: fontSize,
    ));
  }

  void _haptic(HapticFeedbackType type) {
    try {
      Future<void>? future;
      switch (type) {
        case HapticFeedbackType.light:
          future = HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          future = HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          future = HapticFeedback.heavyImpact();
          break;
      }
      future.catchError((_) {});
    } catch (_) {
      // Haptics not available on desktop or web, silently ignore
    }
  }
}

enum HapticFeedbackType { light, medium, heavy }
