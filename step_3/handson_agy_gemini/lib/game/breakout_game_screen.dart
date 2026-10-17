import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'game_models.dart';
import 'game_painter.dart';

class BreakoutGameScreen extends StatefulWidget {
  const BreakoutGameScreen({super.key});

  @override
  State<BreakoutGameScreen> createState() => _BreakoutGameScreenState();
}

class _BreakoutGameScreenState extends State<BreakoutGameScreen>
    with SingleTickerProviderStateMixin {
  // ゲームの仮想画面サイズ
  static const double gameWidth = 400.0;
  static const double gameHeight = 650.0;

  // ゲーム状態
  GameStatus _status = GameStatus.ready;
  int _score = 0;
  int _highScore = 0;
  int _lives = 3;

  // ゲームエンティティ
  late Paddle _paddle;
  Ball? _ball;
  final List<Block> _blocks = [];
  final List<Particle> _particles = [];

  // Ticker (ゲームループ)
  late final Ticker _ticker;
  Duration _lastDuration = Duration.zero;

  // キーボード操作用の状態
  final FocusNode _focusNode = FocusNode();
  bool _isLeftPressed = false;
  bool _isRightPressed = false;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initGame(fullReset: true);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame({required bool fullReset}) {
    if (fullReset) {
      _score = 0;
      _lives = 3;
      _createBlocks();
    }

    _paddle = Paddle(
      x: gameWidth / 2,
      y: gameHeight - 50.0,
      width: 90.0,
      height: 16.0,
    );

    // ボールをパドルの上に配置
    _ball = Ball(
      x: _paddle.x,
      y: _paddle.y - 12.0,
      vx: 180.0 * (_random.nextBool() ? 1 : -1),
      vy: -280.0,
      radius: 7.0,
    );

    _particles.clear();
    _status = GameStatus.ready;
  }

  void _createBlocks() {
    _blocks.clear();
    const int rows = 5;
    const int cols = 6;
    const double blockMargin = 6.0;
    const double paddingX = 16.0;
    const double paddingTop = 50.0;
    const double blockHeight = 22.0;

    final double blockWidth =
        (gameWidth - (paddingX * 2) - (blockMargin * (cols - 1))) / cols;

    final colors = [
      const Color(0xFFF43F5E), // 赤 (Rose) - 50点
      const Color(0xFFFB923C), // 橙 (Orange) - 40点
      const Color(0xFFFBBF24), // 黄 (Amber) - 30点
      const Color(0xFF34D399), // 緑 (Emerald) - 20点
      const Color(0xFF38BDF8), // 青 (Sky) - 10点
    ];

    final points = [50, 40, 30, 20, 10];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = paddingX + c * (blockWidth + blockMargin);
        final top = paddingTop + r * (blockHeight + blockMargin);
        _blocks.add(
          Block(
            rect: Rect.fromLTWH(left, top, blockWidth, blockHeight),
            color: colors[r % colors.length],
            points: points[r % points.length],
          ),
        );
      }
    }
  }

  void _startGame() {
    if (_status == GameStatus.ready) {
      _status = GameStatus.playing;
      _lastDuration = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      setState(() {});
    } else if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      _lastDuration = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      setState(() {});
    }
  }

  void _pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _ticker.stop();
      setState(() {});
    }
  }

  void _onTick(Duration elapsed) {
    if (_status != GameStatus.playing) return;

    if (_lastDuration == Duration.zero) {
      _lastDuration = elapsed;
      return;
    }

    double dt = (elapsed - _lastDuration).inMicroseconds / 1000000.0;
    _lastDuration = elapsed;

    // フレームドロップ対策（最大0.033秒に制限）
    dt = dt.clamp(0.0, 0.033);

    // キーボード操作によるパドルの移動
    if (_isLeftPressed) {
      _paddle.move(-380.0 * dt, 0, gameWidth);
    }
    if (_isRightPressed) {
      _paddle.move(380.0 * dt, 0, gameWidth);
    }

    // パーティクルの更新
    _particles.removeWhere((p) => !p.update(dt));

    // 高速移動時の壁抜け/ブロックすり抜けを防ぐためサブステップで分割シミュレーション
    const int subSteps = 2;
    final double subDt = dt / subSteps;
    for (int step = 0; step < subSteps; step++) {
      _updatePhysics(subDt);
      if (_status != GameStatus.playing) break;
    }

    setState(() {});
  }

  void _updatePhysics(double dt) {
    final ball = _ball;
    if (ball == null) return;

    ball.update(dt);

    // 左右の壁との衝突
    if (ball.x - ball.radius <= 0) {
      ball.x = ball.radius;
      ball.vx = ball.vx.abs();
    } else if (ball.x + ball.radius >= gameWidth) {
      ball.x = gameWidth - ball.radius;
      ball.vx = -ball.vx.abs();
    }

    // 天井との衝突
    if (ball.y - ball.radius <= 0) {
      ball.y = ball.radius;
      ball.vy = ball.vy.abs();
    }

    // パドルとの衝突
    final paddleRect = _paddle.rect;
    if (ball.vy > 0 &&
        ball.y + ball.radius >= paddleRect.top &&
        ball.y - ball.radius <= paddleRect.bottom &&
        ball.x + ball.radius >= paddleRect.left &&
        ball.x - ball.radius <= paddleRect.right) {
      // パドル上面で反射
      ball.y = paddleRect.top - ball.radius;

      // パドルの中心からの当たり位置によって反射角度を決定
      final hitOffset = (ball.x - _paddle.x) / (_paddle.width / 2);
      final clampedOffset = hitOffset.clamp(-0.95, 0.95);

      // 最大角度 ±65度
      final angle = clampedOffset * (math.pi / 2.7);
      final currentSpeed =
          math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
      final newSpeed = (currentSpeed * 1.01).clamp(320.0, 520.0);

      ball.vx = newSpeed * math.sin(angle);
      ball.vy = -newSpeed * math.cos(angle);

      // パドルヒット時の小さな火花パーティクル
      _spawnParticles(ball.x, paddleRect.top, const Color(0xFF67E8F9), count: 5);
    }

    // ブロックとの衝突
    for (final block in _blocks) {
      if (block.isDestroyed) continue;

      if (_checkBallBlockCollision(ball, block)) {
        final destroyed = block.hit();
        if (destroyed) {
          _score += block.points;
          if (_score > _highScore) {
            _highScore = _score;
          }
          _spawnParticles(
            block.rect.center.dx,
            block.rect.center.dy,
            block.color,
            count: 10,
          );
        }

        // 全ブロック破壊チェック
        if (_blocks.every((b) => b.isDestroyed)) {
          _status = GameStatus.gameClear;
          _ticker.stop();
          return;
        }
        break; // 1サブステップで1ブロック衝突処理
      }
    }

    // 底面に落ちた場合（ミス判定）
    if (ball.y - ball.radius >= gameHeight) {
      _lives--;
      if (_lives <= 0) {
        _status = GameStatus.gameOver;
        _ticker.stop();
      } else {
        _initGame(fullReset: false);
        _ticker.stop();
      }
    }
  }

  bool _checkBallBlockCollision(Ball ball, Block block) {
    final rect = block.rect;

    // 最も近い点を計算
    final closestX = ball.x.clamp(rect.left, rect.right);
    final closestY = ball.y.clamp(rect.top, rect.bottom);

    final distanceX = ball.x - closestX;
    final distanceY = ball.y - closestY;
    final distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);

    if (distanceSquared <= (ball.radius * ball.radius)) {
      // 侵入量を計算して反射方向を決定
      final overlapLeft = (ball.x + ball.radius) - rect.left;
      final overlapRight = rect.right - (ball.x - ball.radius);
      final overlapTop = (ball.y + ball.radius) - rect.top;
      final overlapBottom = rect.bottom - (ball.y - ball.radius);

      final minOverlapX = math.min(overlapLeft, overlapRight);
      final minOverlapY = math.min(overlapTop, overlapBottom);

      if (minOverlapX < minOverlapY) {
        // 横からの衝突
        ball.vx = -ball.vx;
        if (overlapLeft < overlapRight) {
          ball.x = rect.left - ball.radius;
        } else {
          ball.x = rect.right + ball.radius;
        }
      } else {
        // 上下からの衝突
        ball.vy = -ball.vy;
        if (overlapTop < overlapBottom) {
          ball.y = rect.top - ball.radius;
        } else {
          ball.y = rect.bottom + ball.radius;
        }
      }
      return true;
    }
    return false;
  }

  void _spawnParticles(double x, double y, Color color, {int count = 8}) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 60.0 + _random.nextDouble() * 140.0;
      _particles.add(
        Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          color: color,
          size: 3.0 + _random.nextDouble() * 3.0,
          decay: 1.8 + _random.nextDouble() * 1.2,
        ),
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double scale) {
    final deltaX = details.delta.dx / scale;
    setState(() {
      _paddle.move(deltaX, 0, gameWidth);
      if (_status == GameStatus.ready && _ball != null) {
        _ball!.x = _paddle.x;
      }
    });
  }

  void _onTapField(TapDownDetails details, double scale) {
    if (_status == GameStatus.ready) {
      _startGame();
    } else if (_status == GameStatus.playing) {
      final localX = details.localPosition.dx / scale;
      setState(() {
        _paddle.moveTo(localX, 0, gameWidth);
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      if (isDown) _isLeftPressed = true;
      if (isUp) _isLeftPressed = false;
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      if (isDown) _isRightPressed = true;
      if (isUp) _isRightPressed = false;
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space && isDown) {
      if (_status == GameStatus.ready) {
        _startGame();
      } else if (_status == GameStatus.playing) {
        _pauseGame();
      } else if (_status == GameStatus.paused) {
        _startGame();
      } else if (_status == GameStatus.gameOver || _status == GameStatus.gameClear) {
        _initGame(fullReset: true);
        _startGame();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF030712),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 画面内にアスペクト比を維持して最大化して収める
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;

                      final scale = math.min(
                        availableWidth / gameWidth,
                        availableHeight / gameHeight,
                      );

                      final renderWidth = gameWidth * scale;
                      final renderHeight = gameHeight * scale;

                      return SizedBox(
                        width: renderWidth,
                        height: renderHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTapDown: (details) =>
                                  _onTapField(details, scale),
                              onPanUpdate: (details) =>
                                  _onPanUpdate(details, scale),
                              child: CustomPaint(
                                size: Size(renderWidth, renderHeight),
                                painter: GamePainter(
                                  blocks: _blocks,
                                  paddle: _paddle,
                                  ball: _ball,
                                  particles: _particles,
                                  gameWidth: gameWidth,
                                  gameHeight: gameHeight,
                                ),
                              ),
                            ),
                            if (_status != GameStatus.playing)
                              _buildOverlay(context),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // スコア
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // ハイスコア
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HIGH SCORE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '$_highScore',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          // ライフ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LIVES',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final active = index < _lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.favorite,
                      size: 20,
                      color: active
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF334155),
                    ),
                  );
                }),
              ),
            ],
          ),
          // 一時停止 / 再開ボタン
          IconButton(
            icon: Icon(
              _status == GameStatus.playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: const Color(0xFF38BDF8),
              size: 30,
            ),
            tooltip: _status == GameStatus.playing ? '一時停止' : '再開',
            onPressed: () {
              if (_status == GameStatus.playing) {
                _pauseGame();
              } else if (_status == GameStatus.paused) {
                _startGame();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    String title = '';
    String subtitle = '';
    String buttonText = '';
    Color accentColor = const Color(0xFF38BDF8);
    VoidCallback onButtonPressed = () {};

    switch (_status) {
      case GameStatus.ready:
        title = 'BLOCK BREAKER';
        subtitle = '画面をタップまたはドラッグしてスタート\n(矢印キー / A, D キーでも操作可能)';
        buttonText = 'GAME START';
        accentColor = const Color(0xFF38BDF8);
        onButtonPressed = _startGame;
        break;
      case GameStatus.paused:
        title = 'PAUSED';
        subtitle = 'ゲーム一時停止中';
        buttonText = 'RESUME';
        accentColor = const Color(0xFFFBBF24);
        onButtonPressed = _startGame;
        break;
      case GameStatus.gameOver:
        title = 'GAME OVER';
        subtitle = '最終スコア: $_score 点';
        buttonText = 'RETRY';
        accentColor = const Color(0xFFF43F5E);
        onButtonPressed = () {
          _initGame(fullReset: true);
          _startGame();
        };
        break;
      case GameStatus.gameClear:
        title = 'STAGE CLEAR!';
        subtitle = 'おめでとうございます！全ブロックを破壊しました！\nスコア: $_score 点';
        buttonText = 'PLAY AGAIN';
        accentColor = const Color(0xFF34D399);
        onButtonPressed = () {
          _initGame(fullReset: true);
          _startGame();
        };
        break;
      case GameStatus.playing:
        return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: accentColor,
                  shadows: [
                    Shadow(
                      color: accentColor.withValues(alpha: 0.6),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onButtonPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFF0B132B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 左移動ボタン (長押し対応)
          GestureDetector(
            onTapDown: (_) => setState(() => _isLeftPressed = true),
            onTapUp: (_) => setState(() => _isLeftPressed = false),
            onTapCancel: () => setState(() => _isLeftPressed = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.arrow_left,
                color: Color(0xFF38BDF8),
                size: 36,
              ),
            ),
          ),
          // リセットボタン
          IconButton(
            tooltip: '最初からやり直す',
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 28),
            onPressed: () {
              _ticker.stop();
              setState(() {
                _initGame(fullReset: true);
              });
            },
          ),
          // 右移動ボタン (長押し対応)
          GestureDetector(
            onTapDown: (_) => setState(() => _isRightPressed = true),
            onTapUp: (_) => setState(() => _isRightPressed = false),
            onTapCancel: () => setState(() => _isRightPressed = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.arrow_right,
                color: Color(0xFF38BDF8),
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
