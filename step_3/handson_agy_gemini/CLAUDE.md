# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter Breakout (ブロック崩し) game. `SPECIFICATION.md` (Japanese) is the authoritative spec: it pins exact constants, colors, physics formulas, UI strings, and test expectations. When changing behavior, check it first and keep code and spec consistent. Note the spec names the package `handson_2026_brekout_game`, but the actual package is `handson_2026_agy_1` (imports use `package:handson_2026_agy_1/...`).

Code comments and UI strings are in Japanese; follow that convention.

## Commands

```bash
flutter pub get                       # install dependencies
flutter run                           # run (add -d chrome / -d macos / device id)
flutter analyze                       # lint (flutter_lints; android/ios/web/build excluded)
flutter test                          # all tests
flutter test test/widget_test.dart    # single file
flutter test --plain-name "Breakout game smoke test"   # single test by name
```

## Architecture

No external state management or game engine — everything is plain Flutter in `lib/game/`:

- `breakout_game_screen.dart` — `_BreakoutGameScreenState` owns **all** mutable game state (paddle, ball, blocks, particles, score, lives, `GameStatus`) and contains the game loop, physics/collision, input handling, and UI (top bar, overlays, bottom controls).
- `game_models.dart` — plain mutable entity classes (`Paddle`, `Ball`, `Block`, `Particle`) plus the `GameStatus` enum. Models update themselves in place (`update(dt)`, `hit()`, `move()`).
- `game_painter.dart` — `GamePainter` (`CustomPainter`) is stateless rendering of the model objects passed in; `shouldRepaint` always returns `true`.

Key cross-file concepts:

- **Virtual coordinate system**: all game logic runs in a fixed 400×650 space (`gameWidth`/`gameHeight` static consts on the screen state). The screen's `LayoutBuilder` computes an aspect-preserving scale for the widget size; `GamePainter` applies `canvas.scale` to draw in virtual coords, and touch input (`onPanUpdate`, `onTapDown`) must be divided by that scale to convert back.
- **Game loop**: a `Ticker` (`SingleTickerProviderStateMixin`) drives `_onTick`, which computes `dt` (clamped to 0.033s), applies keyboard paddle movement, updates particles, then runs `_updatePhysics` in 2 sub-steps to prevent tunneling, and finally calls `setState` to repaint.
- **Ticker only runs while `playing`**: the ticker is stopped on pause, life lost (back to `ready`), game over, and clear. `_lastDuration` is reset to `Duration.zero` when (re)starting so the first tick after a restart is skipped instead of producing a huge `dt`. Any new state transition must handle the ticker and `_lastDuration` the same way.
- **Input** has three paths that all mutate the same state: gestures on the game canvas, keyboard via `Focus.onKeyEvent` (arrow/A/D set `_isLeftPressed`/`_isRightPressed` flags consumed per tick; Space toggles start/pause/restart), and on-screen bottom buttons that set the same pressed flags.

## Tests

`test/widget_test.dart` is a smoke test asserting the initial `ready` overlay shows `'BLOCK BREAKER'`, `'GAME START'`, and `'SCORE'`. Changing those strings breaks it.
