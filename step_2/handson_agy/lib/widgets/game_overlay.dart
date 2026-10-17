import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../game/breakout_game_controller.dart';

class GameOverlay extends StatelessWidget {
  final BreakoutGameController controller;

  const GameOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.status) {
      case GameStatus.title:
        return _buildTitleOverlay(context);
      case GameStatus.ready:
        return _buildReadyOverlay();
      case GameStatus.paused:
        return _buildPausedOverlay();
      case GameStatus.stageClear:
        return _buildStageClearOverlay();
      case GameStatus.gameOver:
        return _buildGameOverOverlay();
      case GameStatus.gameComplete:
        return _buildGameCompleteOverlay();
      case GameStatus.playing:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTitleOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'NEON',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: Color(0xFF00E5FF),
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 20),
                      Shadow(color: Colors.white, blurRadius: 4),
                    ],
                  ),
                ),
                const Text(
                  'BREAKOUT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: Color(0xFFFF007F),
                    shadows: [
                      Shadow(color: Color(0xFFFF007F), blurRadius: 18),
                      Shadow(color: Colors.white, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10192A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00E5FF).withAlpha(100)),
                  ),
                  child: Text(
                    'HIGH SCORE: ${controller.highScore}',
                    style: const TextStyle(
                      color: Color(0xFFFFD600),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Start button
                _NeonButton(
                  text: 'START GAME',
                  color: const Color(0xFF00E676),
                  icon: Icons.play_arrow_rounded,
                  onPressed: controller.startNewGame,
                ),

                const SizedBox(height: 28),

                // Control tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090E1A).withAlpha(220),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'CONTROLS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '🖥️ Desktop: [A] [D] / [←] [→] or Mouse Drag\n'
                        '📱 Mobile: Touch Drag or On-screen Buttons\n'
                        '🚀 Launch: [Space] or Tap Screen',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withAlpha(80),
                blurRadius: 12,
              )
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TAP OR PRESS SPACE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'TO LAUNCH BALL',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Color(0xFFFFD600),
                shadows: [
                  Shadow(color: Color(0xFFFFD600), blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _NeonButton(
              text: 'RESUME',
              color: const Color(0xFF00E5FF),
              icon: Icons.play_arrow_rounded,
              onPressed: controller.togglePause,
            ),
            const SizedBox(height: 14),
            _NeonButton(
              text: 'RESTART',
              color: const Color(0xFFFF5252),
              icon: Icons.refresh_rounded,
              onPressed: controller.startNewGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageClearOverlay() {
    return Container(
      color: Colors.black.withAlpha(190),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'STAGE CLEAR!!',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFF00E676),
                shadows: [
                  Shadow(color: Color(0xFF00E676), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CURRENT SCORE: ${controller.score}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 28),
            _NeonButton(
              text: 'NEXT STAGE',
              color: const Color(0xFF00E5FF),
              icon: Icons.arrow_forward_rounded,
              onPressed: controller.nextStage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Color(0xFFFF1744),
                shadows: [
                  Shadow(color: Color(0xFFFF1744), blurRadius: 24),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'FINAL SCORE: ${controller.score}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'BEST: ${controller.highScore}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFFFD600),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 28),
            _NeonButton(
              text: 'TRY AGAIN',
              color: const Color(0xFF00E5FF),
              icon: Icons.replay_rounded,
              onPressed: controller.startNewGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCompleteOverlay() {
    return Container(
      color: Colors.black.withAlpha(210),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MISSION COMPLETE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFFFFD600),
                shadows: [
                  Shadow(color: Color(0xFFFFD600), blurRadius: 25),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ALL STAGES CLEARED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'VICTORY SCORE: ${controller.score}',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 28),
            _NeonButton(
              text: 'PLAY AGAIN',
              color: const Color(0xFF76FF03),
              icon: Icons.celebration_rounded,
              onPressed: controller.startNewGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _NeonButton({
    required this.text,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black, size: 22),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          fontSize: 15,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 10,
        shadowColor: color.withAlpha(180),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}
