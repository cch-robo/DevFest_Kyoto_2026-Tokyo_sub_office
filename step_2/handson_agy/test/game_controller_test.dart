import 'package:flutter_test/flutter_test.dart';
import 'package:breakout_game/models/game_models.dart';
import 'package:breakout_game/game/breakout_game_controller.dart';
import 'package:breakout_game/levels/stage_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BreakoutGameController Unit Tests', () {
    late BreakoutGameController controller;

    setUp(() {
      controller = BreakoutGameController();
    });

    test('Initial game state is title', () {
      expect(controller.status, GameStatus.title);
      expect(controller.currentStage, 1);
      expect(controller.lives, 3);
      expect(controller.score, 0);
    });

    test('startNewGame resets values and prepares ready state', () {
      controller.startNewGame();
      expect(controller.status, GameStatus.ready);
      expect(controller.lives, 3);
      expect(controller.score, 0);
      expect(controller.balls.length, 1);
      expect(controller.balls.first.isStuckToPaddle, true);
      expect(controller.blocks.isNotEmpty, true);
    });

    test('launchBall transitions state from ready to playing', () {
      controller.startNewGame();
      expect(controller.status, GameStatus.ready);

      controller.launchBall();
      expect(controller.status, GameStatus.playing);
      expect(controller.balls.first.isStuckToPaddle, false);
      expect(controller.balls.first.velocity.dy, lessThan(0)); // Moving upwards
    });

    test('togglePause toggles between playing and paused', () {
      controller.startNewGame();
      controller.launchBall();
      expect(controller.status, GameStatus.playing);

      controller.togglePause();
      expect(controller.status, GameStatus.paused);

      controller.togglePause();
      expect(controller.status, GameStatus.playing);
    });

    test('Paddle moves within screen bounds', () {
      controller.setPaddleTargetX(-100);
      expect(controller.paddle.targetX, greaterThanOrEqualTo(controller.paddle.width / 2));

      controller.setPaddleTargetX(1000);
      expect(
        controller.paddle.targetX,
        lessThanOrEqualTo(BreakoutGameController.fieldWidth - controller.paddle.width / 2),
      );
    });

    test('MultiBall power-up spawns 3 balls from 1 ball', () {
      controller.startNewGame();
      controller.launchBall();
      expect(controller.balls.length, 1);

      // Drop power-up on paddle
      controller.droppingPowerUps.add(
        DroppingPowerUp(position: controller.paddle.rect.center, type: PowerUpType.multiBall),
      );
      controller.update(0.016);

      expect(controller.balls.length, 3);
    });

    test('WidePaddle power-up increases paddle width', () {
      controller.startNewGame();
      controller.launchBall();
      final initialWidth = controller.paddle.width;

      controller.droppingPowerUps.add(
        DroppingPowerUp(position: controller.paddle.rect.center, type: PowerUpType.widePaddle),
      );
      controller.update(0.016);

      expect(controller.paddle.width, greaterThan(initialWidth));
      expect(controller.isPowerUpActive(PowerUpType.widePaddle), true);
    });

    test('All 5 stages build valid block counts', () {
      for (int stage = 1; stage <= StageBuilder.totalStages; stage++) {
        final config = StageBuilder.getStage(stage);
        expect(config.stageNumber, stage);
        expect(config.blocks.isNotEmpty, true);
        expect(config.title.isNotEmpty, true);
      }
    });
  });
}
