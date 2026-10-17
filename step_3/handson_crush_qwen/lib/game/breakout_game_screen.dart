import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game_models.dart';
import 'game_painter.dart';

/// ブロック崩しゲームのメイン画面。
class BreakoutGameScreen extends StatefulWidget {
  /// 既定コンストラクタ。
  const BreakoutGameScreen({super.key});

  @override
  State<BreakoutGameScreen> createState() => _BreakoutGameScreenState();
}

class _BreakoutGameScreenState extends State<BreakoutGameScreen>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // 定数
  // ---------------------------------------------------------------------------

  /// 仮想画面サイズ（アスペクト比 400:650 を維持）
  static const double gameWidth = 400.0;
  static const double gameHeight = 650.0;

  /// トップバーのラベル共通スタイル
  static const TextStyle _labelStyle = TextStyle(
    color: Color(0xFF94A3B8),
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  // ---------------------------------------------------------------------------
  // 状態フィールド
  // ---------------------------------------------------------------------------

  /// ゲーム状態
  GameStatus _status = GameStatus.ready;

  /// スコア / ハイスコア / 残機
  int _score = 0;
  int _highScore = 0;
  int _lives = 3;

  /// エンティティ
  late Paddle _paddle;
  Ball? _ball;
  final List<Block> _blocks = [];
  final List<Particle> _particles = [];

  /// ゲームループ
  late final Ticker _ticker;
  Duration _lastDuration = Duration.zero;

  /// 入力
  final FocusNode _focusNode = FocusNode();
  bool _isLeftPressed = false;
  bool _isRightPressed = false;

  /// 乱数生成器
  final math.Random _random = math.Random();

  // ---------------------------------------------------------------------------
  // ライフサイクル
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // ゲームを初期化（Ticker はこの時点では開始しない）
    _initGame(fullReset: true);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ゲーム初期化
  // ---------------------------------------------------------------------------

  /// ゲーム初期化。
  /// [fullReset] が true のときのみスコア・残機・ブロックをリセットする。
  void _initGame({required bool fullReset}) {
    if (fullReset) {
      // ハイスコアは保持する
      _score = 0;
      _lives = 3;
      _createBlocks();
    }

    // パドル生成
    _paddle = Paddle(
      x: gameWidth / 2, // 200
      y: gameHeight - 50, // 600
      width: 90,
      height: 16,
    );

    // ボール生成（水平方向はランダム）
    final direction = _random.nextDouble() < 0.5 ? 1.0 : -1.0;
    _ball = Ball(
      x: _paddle.x,
      y: _paddle.y - 12,
      vx: 180 * direction,
      vy: -280,
      radius: 7,
    );

    // パーティクルをクリアし、ready 状態で再開
    _particles.clear();
    _status = GameStatus.ready;
  }

  /// ブロックを生成する（5 行 × 6 列 = 30 個）。
  void _createBlocks() {
    _blocks.clear();

    const rows = 5;
    const cols = 6;
    const blockMargin = 6.0;
    const paddingX = 16.0;
    const paddingTop = 50.0;
    const blockHeight = 22.0;

    const blockWidth =
        (gameWidth - paddingX * 2 - blockMargin * (cols - 1)) / cols;

    // 行ごとの色と配点
    final rowColors = <int>[
      0xFFF43F5E, // Rose
      0xFFFB923C, // Orange
      0xFFFBBF24, // Amber
      0xFF34D399, // Emerald
      0xFF38BDF8, // Sky
    ];
    final rowPoints = <int>[50, 40, 30, 20, 10];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final left = paddingX + c * (blockWidth + blockMargin);
        final top = paddingTop + r * (blockHeight + blockMargin);
        _blocks.add(Block(
          rect: Rect.fromLTWH(left, top, blockWidth, blockHeight),
          color: Color(rowColors[r]),
          points: rowPoints[r],
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 状態遷移
  // ---------------------------------------------------------------------------

  /// ゲームを開始（または一時停止から再開）する。
  void _startGame() {
    if (_status == GameStatus.ready || _status == GameStatus.paused) {
      _status = GameStatus.playing;
      // 再開直後の初回フレームはスキップするためリセット
      _lastDuration = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
      setState(() {});
    }
  }

  /// ゲームを一時停止する。
  void _pauseGame() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _ticker.stop();
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // ゲームループ
  // ---------------------------------------------------------------------------

  /// Ticker によるゲームループ。
  void _onTick(Duration elapsed) {
    // 1. 稼働中のみ処理
    if (_status != GameStatus.playing) {
      return;
    }

    // 2. 再開直後の初回フレームはスキップ
    if (_lastDuration == Duration.zero) {
      _lastDuration = elapsed;
      return;
    }

    // 3. dt を秒単位で算出
    var dt = (elapsed - _lastDuration).inMicroseconds / 1000000.0;
    _lastDuration = elapsed;

    // 4. dt を 0.0〜0.033 秒にクランプ（フレームスキップ対策）
    dt = dt.clamp(0.0, 0.033);

    // 5. キー押下状態に応じてパドルを移動
    if (_isLeftPressed) {
      _paddle.move(-380 * dt, 0, gameWidth);
    }
    if (_isRightPressed) {
      _paddle.move(380 * dt, 0, gameWidth);
    }

    // 6. パーティクルを更新（消えたものを削除）
    _particles.removeWhere((p) => !p.update(dt));

    // 7. サブステップ物理更新
    const subSteps = 2;
    final subDt = dt / subSteps;
    for (int i = 0; i < subSteps; i++) {
      _updatePhysics(subDt);
      if (_status != GameStatus.playing) {
        break;
      }
    }

    // 8. 再描画
    setState(() {});
  }

  /// 一サブステップ分の物理更新。
  void _updatePhysics(double dt) {
    final ball = _ball;
    if (ball == null) {
      return;
    }

    // 1. ボールを移動
    ball.update(dt);

    // 2. 左右の壁との衝突
    if (ball.x - ball.radius <= 0) {
      ball.x = ball.radius;
      ball.vx = ball.vx.abs();
    } else if (ball.x + ball.radius >= gameWidth) {
      ball.x = gameWidth - ball.radius;
      ball.vx = -ball.vx.abs();
    }

    // 3. 天井との衝突
    if (ball.y - ball.radius <= 0) {
      ball.y = ball.radius;
      ball.vy = ball.vy.abs();
    }

    // 4. パドルとの衝突
    final paddleRect = _paddle.rect;
    if (ball.vy > 0 &&
        ball.y + ball.radius >= paddleRect.top &&
        ball.y - ball.radius <= paddleRect.bottom &&
        ball.x + ball.radius >= paddleRect.left &&
        ball.x - ball.radius <= paddleRect.right) {
      ball.y = paddleRect.top - ball.radius;
      // パドル上の当たり位置による反射角 (-0.95〜0.95 にクランプ)
      final hitOffset =
          ((ball.x - _paddle.x) / (_paddle.width / 2)).clamp(-0.95, 0.95);
      final angle = hitOffset * (math.pi / 2.7);
      // 速度を微増速して 320〜520 px/s にクランプ
      final currentSpeed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
      final newSpeed = (currentSpeed * 1.01).clamp(320.0, 520.0);
      ball.vx = newSpeed * math.sin(angle);
      ball.vy = -newSpeed * math.cos(angle);
      // シアンのエフェクト
      _spawnParticles(
        ball.x,
        paddleRect.top,
        const Color(0xFF67E8F9),
        count: 5,
      );
    }

    // 5. ブロックとの衝突（サブステップにつき最大 1 個だけ処理）
    for (final block in _blocks) {
      if (block.isDestroyed) {
        continue;
      }
      if (_checkBallBlockCollision(ball, block)) {
        if (block.hit()) {
          // 破壊された場合のみ加点・エフェクト
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
        break;
      }
    }

    // 全ブロック破壊 → ステージクリア
    if (_blocks.every((b) => b.isDestroyed)) {
      _status = GameStatus.gameClear;
      _ticker.stop();
      return;
    }

    // 6. 落下（ミス）
    if (ball.y - ball.radius >= gameHeight) {
      _lives--;
      if (_lives <= 0) {
        _status = GameStatus.gameOver;
      } else {
        // ブロック・スコアを維持したまま ready に戻る
        _initGame(fullReset: false);
      }
      _ticker.stop();
    }
  }

  /// ボールとブロックの衝突判定（衝突すれば `true`、当たり角度に応じて反射）。
  bool _checkBallBlockCollision(Ball ball, Block block) {
    final rect = block.rect;
    final r = ball.radius;

    // 矩形上の最近傍点との距離の二乗で判定
    final closestX = ball.x.clamp(rect.left, rect.right);
    final closestY = ball.y.clamp(rect.top, rect.bottom);
    final dx = ball.x - closestX;
    final dy = ball.y - closestY;
    if (dx * dx + dy * dy > r * r) {
      return false;
    }

    // 侵入量から当たり方向を決定
    final overlapLeft = (ball.x + r) - rect.left;
    final overlapRight = rect.right - (ball.x - r);
    final overlapTop = (ball.y + r) - rect.top;
    final overlapBottom = rect.bottom - (ball.y - r);
    final minOverlapX = math.min(overlapLeft, overlapRight);
    final minOverlapY = math.min(overlapTop, overlapBottom);

    if (minOverlapX < minOverlapY) {
      // 横からの当たり
      ball.vx = -ball.vx;
      if (overlapLeft < overlapRight) {
        ball.x = rect.left - r;
      } else {
        ball.x = rect.right + r;
      }
    } else {
      // 上下からの当たり
      ball.vy = -ball.vy;
      if (overlapTop < overlapBottom) {
        ball.y = rect.top - r;
      } else {
        ball.y = rect.bottom + r;
      }
    }
    return true;
  }

  /// [count] 個のパーティクルを生成する。
  void _spawnParticles(
    double x,
    double y,
    Color color, {
    int count = 8,
  }) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 60 + _random.nextDouble() * 140; // 60〜200 px/s
      _particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: color,
        size: 3.0 + _random.nextDouble() * 3.0, // 3〜6
        decay: 1.8 + _random.nextDouble() * 1.2, // 1.8〜3.0
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // 入力操作
  // ---------------------------------------------------------------------------

  /// ドラッグ入力（画面座標を [scale] で仮想座標へ変換してパドルを移動）。
  void _onPanUpdate(DragUpdateDetails details, double scale) {
    setState(() {
      final deltaX = details.delta.dx / scale;
      _paddle.move(deltaX, 0, gameWidth);
      // ready 状態でボールが存在する場合はパドルに追従させる
      if (_status == GameStatus.ready && _ball != null) {
        _ball!.x = _paddle.x;
      }
    });
  }

  /// フィールド上のタップ入力。
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

  /// キーボード入力（左右矢印 / A・D で移動、Space で状態遷移）。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isLeftKey = event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA;
    final isRightKey = event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // 押下（または連打）
      if (isLeftKey) {
        _isLeftPressed = true;
        return KeyEventResult.handled;
      }
      if (isRightKey) {
        _isRightPressed = true;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        switch (_status) {
          case GameStatus.ready:
            _startGame();
            break;
          case GameStatus.playing:
            _pauseGame();
            break;
          case GameStatus.paused:
            _startGame();
            break;
          case GameStatus.gameOver:
          case GameStatus.gameClear:
            _initGame(fullReset: true);
            _startGame();
            break;
        }
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      // 解放
      if (isLeftKey) {
        _isLeftPressed = false;
        return KeyEventResult.handled;
      }
      if (isRightKey) {
        _isRightPressed = false;
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

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
              // 1. トップバー
              _buildTopBar(),
              // 2. メインゲーム領域
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // アスペクト比 400:650 を維持するスケール
                      final scale = math.min(
                        constraints.maxWidth / gameWidth,
                        constraints.maxHeight / gameHeight,
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
                            // 3. playing 以外でオーバーレイを表示
                            if (_status != GameStatus.playing)
                              _buildOverlay(context),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 3. ボトムコントロール
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  /// トップバー（スコア・ハイスコア・残機・一時停止/再開）。
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
          // SCORE
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SCORE', style: _labelStyle),
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
          // HIGH SCORE
          Column(
            children: [
              const Text('HIGH SCORE', style: _labelStyle),
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
          // LIVES
          Column(
            children: [
              const Text('LIVES', style: _labelStyle),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.favorite,
                      size: 20,
                      color: index < _lives
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 一時停止/再開ボタン
          IconButton(
            tooltip: _status == GameStatus.playing ? '一時停止' : '再開',
            icon: Icon(
              _status == GameStatus.playing
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: const Color(0xFF38BDF8),
              size: 30,
            ),
            onPressed: () {
              if (_status == GameStatus.playing) {
                _pauseGame();
              } else if (_status == GameStatus.paused) {
                _startGame();
              }
              // その他の状態では何もしない
            },
          ),
        ],
      ),
    );
  }

  /// ゲームオーバーレイ（ready / paused / gameOver / gameClear 用）。
  Widget _buildOverlay(BuildContext context) {
    // playing 中はオーバーレイを表示しない
    if (_status == GameStatus.playing) {
      return const SizedBox.shrink();
    }

    String title;
    String description;
    String buttonLabel;
    final Color accent;
    final VoidCallback onPressed;

    switch (_status) {
      case GameStatus.ready:
        title = 'BLOCK BREAKER';
        description =
            '画面をタップまたはドラッグしてスタート\n(矢印キー / A, D キーでも操作可能)';
        buttonLabel = 'GAME START';
        accent = const Color(0xFF38BDF8);
        onPressed = _startGame;
        break;
      case GameStatus.paused:
        title = 'PAUSED';
        description = 'ゲーム一時停止中';
        buttonLabel = 'RESUME';
        accent = const Color(0xFFFBBF24);
        onPressed = _startGame;
        break;
      case GameStatus.gameOver:
        title = 'GAME OVER';
        description = '最終スコア: $_score 点';
        buttonLabel = 'RETRY';
        accent = const Color(0xFFF43F5E);
        onPressed = () {
          _initGame(fullReset: true);
          _startGame();
        };
        break;
      case GameStatus.gameClear:
        title = 'STAGE CLEAR!';
        description =
            'おめでとうございます！全ブロックを破壊しました！\nスコア: $_score 点';
        buttonLabel = 'PLAY AGAIN';
        accent = const Color(0xFF34D399);
        onPressed = () {
          _initGame(fullReset: true);
          _startGame();
        };
        break;
      case GameStatus.playing:
        // playing 中は到達しない（関数先頭で早期 return 済み）
        title = '';
        description = '';
        buttonLabel = '';
        accent = const Color(0xFF38BDF8);
        onPressed = () {};
        break;
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトル
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 説明文
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // アクションボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  buttonLabel,
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

  /// ボトムコントロール（左右移動ボタン・リセットボタン）。
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFF0B132B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 左移動ボタン
          GestureDetector(
            onTapDown: (_) => setState(() => _isLeftPressed = true),
            onTapUp: (_) => setState(() => _isLeftPressed = false),
            onTapCancel: () => setState(() => _isLeftPressed = false),
            child: _buildDirectionButton(icon: Icons.arrow_left),
          ),
          // リセットボタン
          IconButton(
            tooltip: '最初からやり直す',
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
            onPressed: () {
              _ticker.stop();
              setState(() {
                _initGame(fullReset: true);
              });
            },
          ),
          // 右移動ボタン
          GestureDetector(
            onTapDown: (_) => setState(() => _isRightPressed = true),
            onTapUp: (_) => setState(() => _isRightPressed = false),
            onTapCancel: () => setState(() => _isRightPressed = false),
            child: _buildDirectionButton(icon: Icons.arrow_right),
          ),
        ],
      ),
    );
  }

  /// 左右移動ボタンの外観を生成する。
  Widget _buildDirectionButton({required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF38BDF8),
        size: 36,
      ),
    );
  }
}
