import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../game/breakout_game_controller.dart';

class VirtualController extends StatelessWidget {
  final BreakoutGameController controller;

  const VirtualController({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00E5FF).withAlpha(50),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Steering Button (Holdable)
          _HoldableButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressStart: () => controller.moveLeft = true,
            onPressEnd: () => controller.moveLeft = false,
          ),

          // Center Action: Launch or Pause
          Row(
            children: [
              if (controller.status == GameStatus.ready)
                ElevatedButton.icon(
                  onPressed: controller.launchBall,
                  icon: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 18),
                  label: const Text(
                    'LAUNCH',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )
              else if (controller.status == GameStatus.playing || controller.status == GameStatus.paused)
                IconButton(
                  onPressed: controller.togglePause,
                  icon: Icon(
                    controller.status == GameStatus.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: const Color(0xFF00E5FF),
                    size: 28,
                  ),
                ),
            ],
          ),

          // Right Steering Button (Holdable)
          _HoldableButton(
            icon: Icons.arrow_forward_ios_rounded,
            onPressStart: () => controller.moveRight = true,
            onPressEnd: () => controller.moveRight = false,
          ),
        ],
      ),
    );
  }
}

class _HoldableButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const _HoldableButton({
    required this.icon,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: () => onPressEnd(),
      child: Container(
        width: 64,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF10192A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00E5FF).withAlpha(120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withAlpha(40),
              blurRadius: 8,
            )
          ],
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF00E5FF), size: 22),
        ),
      ),
    );
  }
}
