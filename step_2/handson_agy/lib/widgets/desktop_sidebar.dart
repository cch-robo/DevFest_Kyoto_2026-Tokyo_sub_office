import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../game/breakout_game_controller.dart';

class DesktopLeftSidebar extends StatelessWidget {
  final BreakoutGameController controller;

  const DesktopLeftSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF00E5FF).withAlpha(40),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 26),
              SizedBox(width: 6),
              Text(
                'SYSTEM HUD',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 28),

          // Stage Info
          _buildInfoTile(
            label: 'STAGE',
            value: '${controller.currentStage} / 5',
            valueColor: const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 16),

          // Score
          _buildInfoTile(
            label: 'SCORE',
            value: '${controller.score}',
            valueColor: Colors.white,
          ),
          const SizedBox(height: 16),

          // High Score
          _buildInfoTile(
            label: 'TOP SCORE',
            value: '${controller.highScore}',
            valueColor: const Color(0xFFFFD600),
          ),
          const SizedBox(height: 16),

          // Lives
          const Text(
            'LIVES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              final isAlive = index < controller.lives;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  Icons.favorite,
                  size: 20,
                  color: isAlive ? const Color(0xFFFF1744) : Colors.white12,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Active Power-ups
          const Text(
            'ACTIVE BUFFS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: controller.activePowerUps.isEmpty && !controller.hasShield
                ? const Text(
                    'No active buffs',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  )
                : ListView(
                    children: [
                      if (controller.hasShield)
                        _buildBuffItem(
                          'LASER SHIELD',
                          const Color(0xFF2979FF),
                          Icons.shield,
                          null,
                        ),
                      ...controller.activePowerUps.map((ap) => _buildBuffItem(
                            ap.type.label,
                            ap.type.color,
                            ap.type.icon,
                            ap.progress,
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBuffItem(String label, Color color, IconData icon, double? progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DesktopRightSidebar extends StatelessWidget {
  const DesktopRightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF00E5FF).withAlpha(40),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFFFF007F), size: 24),
              SizedBox(width: 6),
              Text(
                'GUIDE & POWER-UPS',
                style: TextStyle(
                  color: Color(0xFFFF007F),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 28),

          // Key shortcuts
          _buildShortcutRow('[←] / [A]', 'Move Left'),
          const SizedBox(height: 6),
          _buildShortcutRow('[→] / [D]', 'Move Right'),
          const SizedBox(height: 6),
          _buildShortcutRow('[Space]', 'Launch / Pause'),
          const SizedBox(height: 6),
          _buildShortcutRow('Mouse Drag', 'Smooth Follow'),

          const Divider(color: Color(0xFF1E293B), height: 28),

          const Text(
            'POWER-UP CAPSULES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              children: [
                _buildPowerUpDoc('M - Multi Ball', 'Splits ball into 3', const Color(0xFF00E5FF)),
                _buildPowerUpDoc('W - Wide Paddle', 'Expands paddle width', const Color(0xFF76FF03)),
                _buildPowerUpDoc('F - Fire Ball', 'Penetrates all blocks', const Color(0xFFFF3D00)),
                _buildPowerUpDoc('L - Laser Shield', 'Blocks 1 bottom fall', const Color(0xFF2979FF)),
                _buildPowerUpDoc('S - Slow Motion', 'Calms ball speed', const Color(0xFFFFD600)),
                _buildPowerUpDoc('+ - Extra Life', 'Grants +1 Life', const Color(0xFFFF1744)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keyStr, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPowerUpDoc(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
