import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'models/game_models.dart';
import 'game/breakout_game_controller.dart';
import 'game/neon_painter.dart';
import 'widgets/game_overlay.dart';
import 'widgets/virtual_controller.dart';
import 'widgets/desktop_sidebar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const NeonBreakoutApp());
}

class NeonBreakoutApp extends StatelessWidget {
  const NeonBreakoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Breakout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF04060F),
        fontFamily: 'Roboto',
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final BreakoutGameController _controller;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode();
  bool _showVirtualControls = true;
  double _animationValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = BreakoutGameController();

    // Game loop via Ticker
    _ticker = createTicker((elapsed) {
      if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
      }
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      _animationValue = (_animationValue + dt) % 100.0;
      _controller.update(dt);
    });

    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _controller.moveLeft = isDown;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _controller.moveRight = isDown;
    } else if (event.logicalKey == LogicalKeyboardKey.space && isDown) {
      if (_controller.status == GameStatus.ready) {
        _controller.launchBall();
      } else if (_controller.status == GameStatus.playing) {
        _controller.togglePause();
      } else if (_controller.status == GameStatus.paused) {
        _controller.togglePause();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyP && isDown) {
      _controller.togglePause();
    } else if (event.logicalKey == LogicalKeyboardKey.keyR && isDown) {
      _controller.startNewGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth >= 840;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return isWideScreen
                      ? _buildWideScreenLayout()
                      : _buildMobileLayout(constraints);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Large Desktop / Web display with cyberpunk sidebars
  Widget _buildWideScreenLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left HUD sidebar
        DesktopLeftSidebar(controller: _controller),

        // Center Arcade Game Canvas
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: BreakoutGameController.fieldWidth /
                  BreakoutGameController.fieldHeight,
              child: _buildGameField(),
            ),
          ),
        ),

        // Right Guide sidebar
        const DesktopRightSidebar(),
      ],
    );
  }

  /// Mobile & Portrait layout with top status header and optional virtual controls
  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Column(
      children: [
        // Top Compact HUD
        _buildMobileHUD(),

        // Game Arena
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: BreakoutGameController.fieldWidth /
                  BreakoutGameController.fieldHeight,
              child: _buildGameField(),
            ),
          ),
        ),

        // Bottom Virtual Controls for Mobile Touch
        if (_showVirtualControls)
          VirtualController(controller: _controller),
      ],
    );
  }

  /// Compact HUD for Mobile screens
  Widget _buildMobileHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00E5FF).withAlpha(40),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stage & Score
          Row(
            children: [
              Text(
                'ST.${_controller.currentStage}',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PTS: ${_controller.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Lives & Toggle Controls
          Row(
            children: [
              ...List.generate(5, (index) {
                final isAlive = index < _controller.lives;
                return Padding(
                  padding: const EdgeInsets.only(right: 3.0),
                  child: Icon(
                    Icons.favorite,
                    size: 16,
                    color: isAlive ? const Color(0xFFFF1744) : Colors.white12,
                  ),
                );
              }),
              const SizedBox(width: 8),
              // Virtual control toggle button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _showVirtualControls
                      ? Icons.gamepad_rounded
                      : Icons.gamepad_outlined,
                  color: _showVirtualControls
                      ? const Color(0xFF00E5FF)
                      : Colors.white38,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showVirtualControls = !_showVirtualControls;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The interactive game canvas with touch / mouse tracking
  Widget _buildGameField() {
    return LayoutBuilder(
      builder: (context, fieldConstraints) {
        final scaleX =
            fieldConstraints.maxWidth / BreakoutGameController.fieldWidth;
        final scaleY =
            fieldConstraints.maxHeight / BreakoutGameController.fieldHeight;

        void updatePaddleFromOffset(Offset localPos) {
          final gameX = localPos.dx / scaleX;
          _controller.setPaddleTargetX(gameX);
        }

        return Listener(
          onPointerDown: (event) {
            updatePaddleFromOffset(event.localPosition);
            if (_controller.status == GameStatus.ready) {
              _controller.launchBall();
            }
          },
          onPointerMove: (event) {
            updatePaddleFromOffset(event.localPosition);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Custom Painted Neon Canvas
              ClipRect(
                child: CustomPaint(
                  size: Size(
                    fieldConstraints.maxWidth,
                    fieldConstraints.maxHeight,
                  ),
                  painter: _ScaledNeonPainter(
                    controller: _controller,
                    animationValue: _animationValue,
                    scaleX: scaleX,
                    scaleY: scaleY,
                  ),
                ),
              ),

              // UI Overlays (Title, Game Over, Stage Clear, Pause)
              GameOverlay(controller: _controller),
            ],
          ),
        );
      },
    );
  }
}

/// Scaled wrapper around NeonPainter to map virtual coordinates to rendered pixels
class _ScaledNeonPainter extends CustomPainter {
  final BreakoutGameController controller;
  final double animationValue;
  final double scaleX;
  final double scaleY;

  _ScaledNeonPainter({
    required this.controller,
    required this.animationValue,
    required this.scaleX,
    required this.scaleY,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scaleX, scaleY);
    final painter = NeonPainter(
      controller: controller,
      animationValue: animationValue,
    );
    painter.paint(
      canvas,
      const Size(
        BreakoutGameController.fieldWidth,
        BreakoutGameController.fieldHeight,
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScaledNeonPainter oldDelegate) {
    return true;
  }
}
