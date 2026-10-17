import 'package:flutter/material.dart';
import '../models/game_models.dart';

class StageConfig {
  final int stageNumber;
  final String title;
  final String subtitle;
  final List<Block> blocks;

  StageConfig({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.blocks,
  });
}

class StageBuilder {
  static const double fieldWidth = 400.0;
  static const double fieldHeight = 700.0;

  static const int totalStages = 5;

  static StageConfig getStage(int stageNumber) {
    switch (stageNumber) {
      case 1:
        return _buildStage1();
      case 2:
        return _buildStage2();
      case 3:
        return _buildStage3();
      case 4:
        return _buildStage4();
      case 5:
        return _buildStage5();
      default:
        return _buildStage1();
    }
  }

  // Helper to create grid-based blocks
  static Block _createBlock({
    required int id,
    required double x,
    required double y,
    required double width,
    required double height,
    required Color color,
    BlockType type = BlockType.normal,
    PowerUpType? dropPowerUp,
    int score = 100,
    int health = 1,
  }) {
    return Block(
      id: id,
      rect: Rect.fromLTWH(x, y, width, height),
      baseColor: color,
      type: type,
      dropPowerUp: dropPowerUp,
      scoreValue: score,
      health: health,
      maxHealth: health,
    );
  }

  /// Stage 1: Classic Rows
  static StageConfig _buildStage1() {
    final blocks = <Block>[];
    int id = 0;
    const cols = 8;
    const rows = 5;
    const blockWidth = 42.0;
    const blockHeight = 18.0;
    const spacingX = 4.0;
    const spacingY = 5.0;
    const startX = (fieldWidth - (cols * blockWidth + (cols - 1) * spacingX)) / 2;
    const startY = 85.0;

    final rowColors = [
      const Color(0xFFFF007F), // Neon Pink
      const Color(0xFFFF5252), // Neon Coral
      const Color(0xFFFFD600), // Neon Yellow
      const Color(0xFF00E676), // Neon Green
      const Color(0xFF00E5FF), // Neon Cyan
    ];

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = startX + c * (blockWidth + spacingX);
        final y = startY + r * (blockHeight + spacingY);

        PowerUpType? powerUp;
        if (r == 2 && c == 3) powerUp = PowerUpType.multiBall;
        if (r == 3 && c == 6) powerUp = PowerUpType.widePaddle;
        if (r == 1 && c == 1) powerUp = PowerUpType.shield;

        blocks.add(_createBlock(
          id: id++,
          x: x,
          y: y,
          width: blockWidth,
          height: blockHeight,
          color: rowColors[r],
          score: (5 - r) * 100,
          dropPowerUp: powerUp,
          type: powerUp != null ? BlockType.powerup : BlockType.normal,
        ));
      }
    }

    return StageConfig(
      stageNumber: 1,
      title: 'STAGE 1: CYBER DAWN',
      subtitle: 'Classic Neon Grid',
      blocks: blocks,
    );
  }

  /// Stage 2: Pyramid
  static StageConfig _buildStage2() {
    final blocks = <Block>[];
    int id = 0;
    const blockWidth = 38.0;
    const blockHeight = 18.0;
    const spacingX = 4.0;
    const spacingY = 5.0;
    const startY = 80.0;

    final colors = [
      const Color(0xFFD500F9), // Neon Purple
      const Color(0xFFFF1744), // Crimson
      const Color(0xFFFF9100), // Orange
      const Color(0xFFFFEA00), // Gold
      const Color(0xFF00E676), // Green
      const Color(0xFF00B0FF), // Light Blue
      const Color(0xFF00E5FF), // Cyan
    ];

    for (int r = 0; r < 7; r++) {
      final colsInRow = r + 2;
      final rowWidth = colsInRow * blockWidth + (colsInRow - 1) * spacingX;
      final rowStartX = (fieldWidth - rowWidth) / 2;
      final y = startY + r * (blockHeight + spacingY);

      for (int c = 0; c < colsInRow; c++) {
        final x = rowStartX + c * (blockWidth + spacingX);
        final isHard = (r == 2 && (c == 0 || c == colsInRow - 1)) || (r == 4 && (c == 1 || c == colsInRow - 2));

        PowerUpType? powerUp;
        if (r == 0 && c == 0) powerUp = PowerUpType.fireBall;
        if (r == 4 && c == colsInRow ~/ 2) powerUp = PowerUpType.multiBall;
        if (r == 6 && c == 2) powerUp = PowerUpType.slowBall;

        blocks.add(_createBlock(
          id: id++,
          x: x,
          y: y,
          width: blockWidth,
          height: blockHeight,
          color: colors[r % colors.length],
          type: isHard
              ? BlockType.hard
              : (powerUp != null ? BlockType.powerup : BlockType.normal),
          health: isHard ? 2 : 1,
          score: isHard ? 300 : 150,
          dropPowerUp: powerUp,
        ));
      }
    }

    return StageConfig(
      stageNumber: 2,
      title: 'STAGE 2: NEON PYRAMID',
      subtitle: 'Reinforced Apex',
      blocks: blocks,
    );
  }

  /// Stage 3: Fortress with Explosive Bombs
  static StageConfig _buildStage3() {
    final blocks = <Block>[];
    int id = 0;
    const cols = 8;
    const rows = 6;
    const blockWidth = 42.0;
    const blockHeight = 18.0;
    const spacingX = 4.0;
    const spacingY = 5.0;
    const startX = (fieldWidth - (cols * blockWidth + (cols - 1) * spacingX)) / 2;
    const startY = 80.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = startX + c * (blockWidth + spacingX);
        final y = startY + r * (blockHeight + spacingY);

        // Center 2 blocks are BOMBS!
        final isBomb = (r == 2 || r == 3) && (c == 3 || c == 4);
        final isIron = (r == 0 && (c == 0 || c == 7)) || (r == 5 && (c == 0 || c == 7));
        final isHard = (r == 0 || r == 5) && !isIron;

        PowerUpType? powerUp;
        if (r == 1 && c == 2) powerUp = PowerUpType.extraLife;
        if (r == 4 && c == 5) powerUp = PowerUpType.fireBall;
        if (r == 3 && c == 1) powerUp = PowerUpType.widePaddle;

        BlockType type = BlockType.normal;
        int health = 1;
        Color color = const Color(0xFF00E5FF);

        if (isBomb) {
          type = BlockType.bomb;
          color = const Color(0xFFFF1744);
        } else if (isIron) {
          type = BlockType.iron;
          health = 3;
          color = const Color(0xFFB0BEC5);
        } else if (isHard) {
          type = BlockType.hard;
          health = 2;
          color = const Color(0xFFFF9100);
        } else {
          color = (r % 2 == 0) ? const Color(0xFF76FF03) : const Color(0xFFD500F9);
          if (powerUp != null) type = BlockType.powerup;
        }

        blocks.add(_createBlock(
          id: id++,
          x: x,
          y: y,
          width: blockWidth,
          height: blockHeight,
          color: color,
          type: type,
          health: health,
          score: isBomb ? 500 : (health * 150),
          dropPowerUp: powerUp,
        ));
      }
    }

    return StageConfig(
      stageNumber: 3,
      title: 'STAGE 3: FORTRESS',
      subtitle: 'Chain Reaction Explosives',
      blocks: blocks,
    );
  }

  /// Stage 4: Alien Swarm (Space Invaders motif)
  static StageConfig _buildStage4() {
    final blocks = <Block>[];
    int id = 0;

    // 9x8 matrix for alien sprite
    final alienPattern = [
      [0, 0, 1, 0, 0, 0, 1, 0, 0],
      [0, 0, 0, 1, 0, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 0, 1, 0, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 1, 1, 1, 1, 1, 0, 1],
      [1, 0, 1, 0, 0, 0, 1, 0, 1],
      [0, 0, 0, 1, 1, 1, 0, 0, 0],
    ];

    const blockWidth = 36.0;
    const blockHeight = 16.0;
    const spacingX = 4.0;
    const spacingY = 5.0;
    const cols = 9;
    const startX = (fieldWidth - (cols * blockWidth + (cols - 1) * spacingX)) / 2;
    const startY = 80.0;

    for (int r = 0; r < alienPattern.length; r++) {
      for (int c = 0; c < alienPattern[r].length; c++) {
        if (alienPattern[r][c] == 1) {
          final x = startX + c * (blockWidth + spacingX);
          final y = startY + r * (blockHeight + spacingY);

          final isCore = (r == 4 && (c >= 3 && c <= 5));
          final isHard = isCore || (r == 2 && c == 4);

          PowerUpType? powerUp;
          if (r == 3 && c == 4) powerUp = PowerUpType.multiBall;
          if (r == 6 && c == 2) powerUp = PowerUpType.shield;
          if (r == 7 && c == 4) powerUp = PowerUpType.widePaddle;

          blocks.add(_createBlock(
            id: id++,
            x: x,
            y: y,
            width: blockWidth,
            height: blockHeight,
            color: isCore
                ? const Color(0xFFFF007F)
                : (r < 3 ? const Color(0xFF00E5FF) : const Color(0xFF76FF03)),
            type: isHard
                ? BlockType.hard
                : (powerUp != null ? BlockType.powerup : BlockType.normal),
            health: isHard ? 2 : 1,
            score: isHard ? 350 : 200,
            dropPowerUp: powerUp,
          ));
        }
      }
    }

    return StageConfig(
      stageNumber: 4,
      title: 'STAGE 4: ALIEN MATRIX',
      subtitle: 'Space Invader Formation',
      blocks: blocks,
    );
  }

  /// Stage 5: Quantum Core (Boss Stage)
  static StageConfig _buildStage5() {
    final blocks = <Block>[];
    int id = 0;
    const cols = 9;
    const rows = 8;
    const blockWidth = 38.0;
    const blockHeight = 17.0;
    const spacingX = 3.5;
    const spacingY = 4.5;
    const startX = (fieldWidth - (cols * blockWidth + (cols - 1) * spacingX)) / 2;
    const startY = 75.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = startX + c * (blockWidth + spacingX);
        final y = startY + r * (blockHeight + spacingY);

        // Core cluster in the center
        final isSuperCore = (r == 3 || r == 4) && (c == 4);
        final isIronCore = (r >= 2 && r <= 5) && (c >= 3 && c <= 5) && !isSuperCore;
        final isBomb = (r == 1 && c == 1) || (r == 1 && c == 7) || (r == 6 && c == 1) || (r == 6 && c == 7);

        PowerUpType? powerUp;
        if (r == 0 && c == 4) powerUp = PowerUpType.fireBall;
        if (r == 2 && c == 1) powerUp = PowerUpType.multiBall;
        if (r == 5 && c == 7) powerUp = PowerUpType.extraLife;
        if (r == 7 && c == 4) powerUp = PowerUpType.shield;

        BlockType type = BlockType.normal;
        int health = 1;
        Color color = const Color(0xFF00E5FF);

        if (isSuperCore) {
          type = BlockType.iron;
          health = 4;
          color = const Color(0xFFFFD600);
        } else if (isIronCore) {
          type = BlockType.hard;
          health = 2;
          color = const Color(0xFFFF1744);
        } else if (isBomb) {
          type = BlockType.bomb;
          color = const Color(0xFFFF3D00);
        } else {
          color = (r + c) % 2 == 0 ? const Color(0xFFD500F9) : const Color(0xFF00E5FF);
          if (powerUp != null) type = BlockType.powerup;
        }

        blocks.add(_createBlock(
          id: id++,
          x: x,
          y: y,
          width: blockWidth,
          height: blockHeight,
          color: color,
          type: type,
          health: health,
          score: isSuperCore ? 1000 : (health * 200),
          dropPowerUp: powerUp,
        ));
      }
    }

    return StageConfig(
      stageNumber: 5,
      title: 'FINAL STAGE: QUANTUM CORE',
      subtitle: 'Break the Hyper-Core',
      blocks: blocks,
    );
  }
}
