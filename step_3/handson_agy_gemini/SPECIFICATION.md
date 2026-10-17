# ブロック崩しゲーム アプリケーション仕様書 (SPECIFICATION.md)

本仕様書は、本プロジェクトの `pubspec.yaml`・`lib/`・`test/` 配下のソースコードから抽出した、
Flutter 製「ブロック崩しゲーム（Breakout Game）」のコードを再現するための要件一覧です。

---

## 1. プロジェクト・パッケージ要件 (`pubspec.yaml`)

- パッケージ名: `handson_2026_breakout`
- 説明: `"A new Flutter project."`
- 公開設定: `publish_to: 'none'`
- バージョン: `1.0.0+1`
- Dart SDK 制約: `^3.13.4`
- `dependencies`:
  - `flutter` (sdk: flutter)
  - `cupertino_icons: ^1.0.8`
- `dev_dependencies`:
  - `flutter_test` (sdk: flutter)
  - `flutter_lints: ^6.0.0`
- `flutter` セクション: `uses-material-design: true`
- 外部アセット・フォント・追加パッケージは使用しないこと（描画はすべて `CustomPainter` で行う）。

## 2. ファイル構成要件

| ファイル | 役割 |
| --- | --- |
| `lib/main.dart` | エントリポイント、画面向き固定、`MyApp`（テーマ設定） |
| `lib/game/game_models.dart` | `GameStatus` enum とエンティティクラス（`Paddle` / `Ball` / `Block` / `Particle`） |
| `lib/game/game_painter.dart` | `GamePainter`（`CustomPainter`）によるゲーム画面描画 |
| `lib/game/breakout_game_screen.dart` | `BreakoutGameScreen`（ゲーム状態・ゲームループ・物理/衝突判定・入力処理・UI） |
| `test/widget_test.dart` | 起動時 UI のスモークテスト |

- コードコメントおよび UI 文言の一部は日本語で記述すること。

---

## 3. エントリポイント & アプリ設定要件 (`lib/main.dart`)

### 3.1 `main()`
- `WidgetsFlutterBinding.ensureInitialized()` を呼び出すこと。
- `SystemChrome.setPreferredOrientations` で `DeviceOrientation.portraitUp` と `DeviceOrientation.portraitDown` に固定すること。
- `runApp(const MyApp())` で起動すること。

### 3.2 `MyApp`（`StatelessWidget`、`const` コンストラクタ、`super.key`）
- `MaterialApp` を返すこと:
  - `title`: `'ブロック崩しゲーム'`
  - `debugShowCheckedModeBanner: false`
  - `home: const BreakoutGameScreen()`
- `theme: ThemeData(...)`:
  - `brightness: Brightness.dark`
  - `scaffoldBackgroundColor: Color(0xFF030712)`
  - `colorScheme: ColorScheme.dark(primary: Color(0xFF38BDF8), secondary: Color(0xFFF43F5E), surface: Color(0xFF0F172A))`
  - `useMaterial3: true`

---

## 4. データモデル要件 (`lib/game/game_models.dart`)

- `dart:ui` と `package:flutter/material.dart` を import すること。

### 4.1 `GameStatus`（enum）
- 値は次の順序で定義すること: `ready`, `playing`, `paused`, `gameOver`, `gameClear`

### 4.2 `Paddle`
- フィールド:
  - `double x` … パドル中心の X 座標（可変）
  - `final double y` … パドル上面の Y 座標
  - `final double width`（既定値 `90.0`）
  - `final double height`（既定値 `16.0`）
- コンストラクタ: `x`, `y` は `required`、`width`, `height` は名前付き省略可能引数。
- `Rect get rect` … `Rect.fromCenter(center: Offset(x, y + height / 2), width: width, height: height)`
- `void move(double deltaX, double minX, double maxX)` … `x = (x + deltaX).clamp(minX + width / 2, maxX - width / 2)`
- `void moveTo(double targetX, double minX, double maxX)` … `x = targetX.clamp(minX + width / 2, maxX - width / 2)`

### 4.3 `Ball`
- フィールド:
  - `double x`, `double y`, `double vx`, `double vy`（速度の単位は px/秒）
  - `final double radius`（既定値 `7.0`）
  - `final List<Offset> trail = []` … 残像の座標履歴
  - `static const int maxTrail = 5`
- コンストラクタ: `x`, `y`, `vx`, `vy` は `required`、`radius` は省略可能。
- `double get speed` … `vx * vx + vy * vy`（速度の **二乗値**、平方根は取らない）
- `void update(double dt)`:
  1. 現在位置 `Offset(x, y)` を `trail` の先頭（index 0）に挿入
  2. `trail.length > maxTrail` なら末尾を削除
  3. `x += vx * dt`, `y += vy * dt`

### 4.4 `Block`
- フィールド:
  - `final Rect rect`, `final Color color`, `final int points`
  - `int hitPoints`（既定値 `1`）
  - `bool isDestroyed = false`
- コンストラクタ: `rect`, `color`, `points` は `required`、`hitPoints` は省略可能。
- `bool hit()` … `hitPoints--` を行い、`hitPoints <= 0` なら `isDestroyed = true` として `true` を返す。それ以外は `false`。

### 4.5 `Particle`
- フィールド:
  - `double x`, `double y`, `double vx`, `double vy`
  - `final Color color`
  - `final double size`（既定値 `4.0`）
  - `double life`（既定値 `1.0`、1.0 → 0.0 に減少）
  - `final double decay`（既定値 `2.0`）
- コンストラクタ: `x`, `y`, `vx`, `vy`, `color` は `required`、`size`, `life`, `decay` は省略可能。
- `bool update(double dt)`:
  1. `x += vx * dt`, `y += vy * dt`
  2. 重力: `vy += 300 * dt`
  3. `life -= decay * dt`
  4. `life > 0` を返す（生存判定）

---

## 5. 描画要件 (`lib/game/game_painter.dart`)

### 5.1 `GamePainter extends CustomPainter`
- コンストラクタ引数（すべて `required`）:
  - `List<Block> blocks`, `Paddle? paddle`, `Ball? ball`, `List<Particle> particles`, `double gameWidth`, `double gameHeight`
- `shouldRepaint` は常に `true` を返すこと。

### 5.2 座標スケーリング（`paint`）
- `scaleX = size.width / gameWidth`、`scaleY = size.height / gameHeight` を求める。
- `canvas.save()` → `canvas.scale(scaleX, scaleY)` → 以下の順で描画 → `canvas.restore()`:
  1. 背景 (`_drawBackground`)
  2. 壁 (`_drawWalls`)
  3. ブロック (`_drawBlocks`)
  4. パドル (`_drawPaddle`)
  5. ボール (`_drawBall`)
  6. パーティクル (`_drawParticles`)

### 5.3 背景
- `Rect.fromLTWH(0, 0, gameWidth, gameHeight)` を `LinearGradient`（`topCenter` → `bottomCenter`、色: `0xFF0F172A` → `0xFF0B0F19` → `0xFF030712`）で塗りつぶす。
- グリッド線: 色 `Color(0xFF1E293B)` 不透明度 `0.4`、`strokeWidth 1.0`、間隔 `40.0`。
  - 縦線: `x = 0` から `gameWidth` 以下まで 40 刻み
  - 横線: `y = 0` から `gameHeight` 以下まで 40 刻み

### 5.4 壁ガイドライン
- 色 `Color(0xFF38BDF8)` 不透明度 `0.3`、`PaintingStyle.stroke`、`strokeWidth 2.0`。
- パス: `(0, gameHeight)` → `(0, 0)` → `(gameWidth, 0)` → `(gameWidth, gameHeight)`（左・上・右のコの字）。

### 5.5 ブロック
- `isDestroyed == true` のブロックはスキップ。
- 形状: `RRect.fromRectAndRadius(block.rect, Radius.circular(5.0))`
- 塗り: `LinearGradient`（`topLeft` → `bottomRight`、`block.color` → `block.color` 不透明度 `0.75`）を `block.rect` でシェーダ化。
- ハイライト線: 白 不透明度 `0.45`、stroke、`strokeWidth 1.5`、`(left + 4, top + 2)` → `(right - 4, top + 2)`。
- 外枠: 白 不透明度 `0.25`、stroke、`strokeWidth 1.0` で RRect を描画。

### 5.6 パドル（`paddle == null` なら描画しない）
- 形状: `RRect.fromRectAndRadius(paddle.rect, Radius.circular(8.0))`
- グロー: `Color(0xFF06B6D4)` 不透明度 `0.4`、`MaskFilter.blur(BlurStyle.normal, 8)` で RRect を描画。
- 本体: `LinearGradient`（`topCenter` → `bottomCenter`、`0xFF67E8F9` → `0xFF06B6D4` → `0xFF0891B2`）を `paddle.rect` でシェーダ化して RRect を描画。
- センターマーカー: 白 不透明度 `0.7`、`strokeWidth 2.0`、`(x, y + 3)` → `(x, y + height - 3)` の縦線。

### 5.7 ボール（`ball == null` なら描画しない）
- 残像: `trail` の各要素 `i` について `trailFactor = 1.0 - (i / trail.length)` とし、
  色 `Color(0xFFF43F5E)` 不透明度 `0.25 * trailFactor`、半径 `radius * trailFactor` の塗りつぶし円を描画。
- グロー: 中心 `(x, y)`、半径 `radius + 2`、色 `Color(0xFFFB7185)` 不透明度 `0.6`、`MaskFilter.blur(BlurStyle.normal, 6)`。
- 本体: `RadialGradient`（色 `Colors.white` → `0xFFFB7185` → `0xFFE11D48`、`stops: [0.0, 0.5, 1.0]`）を
  `Rect.fromCircle(center: (x, y), radius: radius)` でシェーダ化し、半径 `radius` の円を描画。

### 5.8 パーティクル
- 各パーティクルを中心 `(x, y)`、半径 `size * life`、色 `color` 不透明度 `life.clamp(0.0, 1.0)` の塗りつぶし円で描画。

---

## 6. ゲーム状態・ロジック要件 (`lib/game/breakout_game_screen.dart`)

- `dart:math`（`as math`）、`material.dart`、`scheduler.dart`、`services.dart`、`game_models.dart`、`game_painter.dart` を import すること。

### 6.1 ウィジェット構成
- `BreakoutGameScreen`（`StatefulWidget`、`const` コンストラクタ）と `_BreakoutGameScreenState`（`SingleTickerProviderStateMixin` 付き）。

### 6.2 定数・状態フィールド
- 仮想画面サイズ: `static const double gameWidth = 400.0`、`gameHeight = 650.0`
- 状態: `GameStatus _status = ready`、`int _score = 0`、`int _highScore = 0`、`int _lives = 3`
- エンティティ: `late Paddle _paddle`、`Ball? _ball`、`final List<Block> _blocks`、`final List<Particle> _particles`
- ループ: `late final Ticker _ticker`、`Duration _lastDuration = Duration.zero`
- 入力: `FocusNode _focusNode`、`bool _isLeftPressed = false`、`bool _isRightPressed = false`
- 乱数: `math.Random _random`

### 6.3 ライフサイクル
- `initState`: `_initGame(fullReset: true)` を実行後、`_ticker = createTicker(_onTick)` を生成（この時点では開始しない）。
- `dispose`: `_ticker` と `_focusNode` を破棄。

### 6.4 ゲーム初期化 `_initGame({required bool fullReset})`
- `fullReset == true` の場合のみ: `_score = 0`、`_lives = 3`、`_createBlocks()`（ハイスコアは保持）。
- 常に実行:
  - パドル生成: `x = gameWidth / 2 (200)`、`y = gameHeight - 50 (600)`、`width 90`、`height 16`
  - ボール生成: `x = paddle.x`、`y = paddle.y - 12`、`vx = 180 × (ランダムに +1 / -1)`、`vy = -280`、`radius 7`
  - `_particles.clear()`、`_status = GameStatus.ready`

### 6.5 ブロック生成 `_createBlocks()`
- 既存ブロックをクリア後、`rows = 5`、`cols = 6`（計 30 個）を生成。
- `blockMargin = 6.0`、`paddingX = 16.0`、`paddingTop = 50.0`、`blockHeight = 22.0`
- `blockWidth = (gameWidth - paddingX * 2 - blockMargin * (cols - 1)) / cols`
- 位置: `left = paddingX + c * (blockWidth + blockMargin)`、`top = paddingTop + r * (blockHeight + blockMargin)`
- 行ごとの色と配点（`hitPoints` は既定値 1）:

| 行 | 色 | 配点 |
| --- | --- | --- |
| 0 | `0xFFF43F5E`（Rose） | 50 |
| 1 | `0xFFFB923C`（Orange） | 40 |
| 2 | `0xFFFBBF24`（Amber） | 30 |
| 3 | `0xFF34D399`（Emerald） | 20 |
| 4 | `0xFF38BDF8`（Sky） | 10 |

### 6.6 状態遷移
- `_startGame()`:
  - `ready` または `paused` のときのみ `_status = playing`、`_lastDuration = Duration.zero` とし、Ticker が非アクティブなら `start()`、`setState`。
- `_pauseGame()`:
  - `playing` のときのみ `_status = paused`、`_ticker.stop()`、`setState`。
- 状態遷移図:
  - `ready` →(開始)→ `playing`
  - `playing` ⇄(一時停止/再開)⇄ `paused`
  - `playing` →(ミス・残機あり)→ `ready`（ブロック・スコア維持）
  - `playing` →(ミス・残機 0)→ `gameOver`
  - `playing` →(全ブロック破壊)→ `gameClear`
  - `gameOver` / `gameClear` →(リトライ)→ 完全リセット → `playing`
  - 任意の状態 →(リセットボタン)→ 完全リセット → `ready`

### 6.7 ゲームループ `_onTick(Duration elapsed)`
1. `_status != playing` なら何もしない。
2. `_lastDuration == Duration.zero` なら `_lastDuration = elapsed` として return（再開直後の初回フレームはスキップ）。
3. `dt = (elapsed - _lastDuration).inMicroseconds / 1000000.0`、`_lastDuration = elapsed`。
4. `dt` を `0.0`〜`0.033` にクランプ。
5. キー押下フラグに応じてパドル移動: `_isLeftPressed` なら `move(-380 * dt, 0, gameWidth)`、`_isRightPressed` なら `move(380 * dt, 0, gameWidth)`。
6. パーティクル更新: `update(dt)` が `false` のものを削除。
7. サブステップ物理: `subSteps = 2`、`subDt = dt / 2` で `_updatePhysics(subDt)` を 2 回実行。途中で `playing` 以外になったら中断。
8. `setState` で再描画。

### 6.8 物理更新 `_updatePhysics(double dt)`（ボールが null なら何もしない）
1. `ball.update(dt)`
2. 左右の壁:
   - `x - radius <= 0` → `x = radius`、`vx = |vx|`
   - それ以外で `x + radius >= gameWidth` → `x = gameWidth - radius`、`vx = -|vx|`
3. 天井: `y - radius <= 0` → `y = radius`、`vy = |vy|`
4. パドル衝突（`paddleRect = _paddle.rect`）:
   - 条件: `vy > 0` かつ `y + radius >= top` かつ `y - radius <= bottom` かつ `x + radius >= left` かつ `x - radius <= right`
   - 処理:
     - `y = paddleRect.top - radius`
     - `hitOffset = (ball.x - paddle.x) / (paddle.width / 2)` を `-0.95`〜`0.95` にクランプ
     - `angle = clampedOffset * (π / 2.7)`
     - `currentSpeed = sqrt(vx² + vy²)`、`newSpeed = (currentSpeed * 1.01).clamp(320.0, 520.0)`
     - `vx = newSpeed * sin(angle)`、`vy = -newSpeed * cos(angle)`
     - `(ball.x, paddleRect.top)` にシアン `0xFF67E8F9` のパーティクルを 5 個生成
5. ブロック衝突:
   - 未破壊ブロックを順に走査し、最初に衝突したブロック 1 つだけを処理して `break`（1 サブステップにつき 1 ブロック）。
   - 衝突時 `block.hit()` が `true`（破壊）なら:
     - `_score += block.points`、`_score > _highScore` なら `_highScore = _score`
     - ブロック中心にブロック色のパーティクルを 10 個生成
   - 全ブロックが破壊済みなら `_status = gameClear`、`_ticker.stop()` して即 return。
6. 落下（ミス）: `y - radius >= gameHeight` のとき
   - `_lives--`
   - `_lives <= 0` → `_status = gameOver`、`_ticker.stop()`
   - それ以外 → `_initGame(fullReset: false)`（`ready` に戻る）、`_ticker.stop()`

### 6.9 ボールとブロックの衝突判定 `_checkBallBlockCollision(Ball, Block)` → `bool`
- 矩形上の最近傍点 `closestX = x.clamp(left, right)`、`closestY = y.clamp(top, bottom)` を求め、
  距離の二乗が `radius²` 以下なら衝突。
- 侵入量:
  - `overlapLeft = (x + r) - left`、`overlapRight = right - (x - r)`
  - `overlapTop = (y + r) - top`、`overlapBottom = bottom - (y - r)`
  - `minOverlapX = min(overlapLeft, overlapRight)`、`minOverlapY = min(overlapTop, overlapBottom)`
- `minOverlapX < minOverlapY` → 横衝突: `vx = -vx`。`overlapLeft < overlapRight` なら `x = left - r`、それ以外は `x = right + r`。
- それ以外 → 上下衝突: `vy = -vy`。`overlapTop < overlapBottom` なら `y = top - r`、それ以外は `y = bottom + r`。
- 衝突時 `true`、非衝突時 `false` を返す。

### 6.10 パーティクル生成 `_spawnParticles(double x, double y, Color color, {int count = 8})`
- `count` 個生成し、各パーティクルは:
  - 角度 `angle = random * 2π`、速さ `speed = 60 + random * 140`（60〜200 px/s）
  - `vx = cos(angle) * speed`、`vy = sin(angle) * speed`
  - `size = 3.0 + random * 3.0`（3〜6）
  - `decay = 1.8 + random * 1.2`（1.8〜3.0）
  - `life` は既定値 `1.0`

---

## 7. 入力操作要件 (`lib/game/breakout_game_screen.dart`)

### 7.1 ドラッグ `_onPanUpdate(DragUpdateDetails, double scale)`
- `deltaX = details.delta.dx / scale`（画面座標 → 仮想座標）でパドルを `move(deltaX, 0, gameWidth)`。
- `ready` 状態かつボールが存在する場合、`ball.x = paddle.x` としてボールをパドルに追従させる。
- `setState` 内で実行すること。

### 7.2 タップ `_onTapField(TapDownDetails, double scale)`
- `ready` → `_startGame()`
- `playing` → `localX = details.localPosition.dx / scale` へパドルを `moveTo`（`setState` 内）。

### 7.3 キーボード `_handleKeyEvent(FocusNode, KeyEvent)` → `KeyEventResult`
- 押下判定: `KeyDownEvent` または `KeyRepeatEvent`、解放判定: `KeyUpEvent`。
- `arrowLeft` / `keyA`: 押下で `_isLeftPressed = true`、解放で `false`。`handled` を返す。
- `arrowRight` / `keyD`: 押下で `_isRightPressed = true`、解放で `false`。`handled` を返す。
- `space`（押下時のみ）: `handled` を返す。
  - `ready` → 開始、`playing` → 一時停止、`paused` → 再開
  - `gameOver` / `gameClear` → `_initGame(fullReset: true)` 後に `_startGame()`
- その他のキーは `ignored` を返す。
- 左右フラグは Ticker 稼働中（`playing`）にのみ反映される。

---

## 8. UI レイアウト要件 (`lib/game/breakout_game_screen.dart`)

### 8.1 全体構成 (`build`)
- `Focus`（`focusNode: _focusNode`、`autofocus: true`、`onKeyEvent: _handleKeyEvent`）
  - `Scaffold`（`backgroundColor: Color(0xFF030712)`）
    - `SafeArea` → `Column`:
      1. `_buildTopBar()`
      2. `Expanded` → `Center` → `LayoutBuilder`（メインゲーム領域）
      3. `_buildBottomControls()`

### 8.2 メインゲーム領域
- `scale = min(maxWidth / gameWidth, maxHeight / gameHeight)` でアスペクト比 400:650 を維持。
- `renderWidth = gameWidth * scale`、`renderHeight = gameHeight * scale` の `SizedBox` 内に `Stack`（`clipBehavior: Clip.none`）を配置:
  1. `GestureDetector`（`onTapDown` → `_onTapField`、`onPanUpdate` → `_onPanUpdate`）
     → `CustomPaint`（`size: Size(renderWidth, renderHeight)`、`painter: GamePainter(...)`）
  2. `_status != playing` のとき `_buildOverlay(context)` を前面に重ねる。

### 8.3 トップバー `_buildTopBar()`
- `Container`: padding 横 `20` / 縦 `12`、背景 `Color(0xFF0B132B)`、下線 `Color(0xFF1E293B)` 幅 `1.5`。
- `Row`（`MainAxisAlignment.spaceBetween`）で以下 4 要素を配置:
  1. **SCORE**（左寄せ Column）
     - ラベル `'SCORE'`: 色 `0xFF94A3B8`、11pt、bold、`letterSpacing 1.2`
     - 値 `'$_score'`: 白、22pt、`FontWeight.w900`、`FontFeature.tabularFigures()`
  2. **HIGH SCORE**（中央 Column）
     - ラベル `'HIGH SCORE'`: ラベル共通スタイル
     - 値 `'$_highScore'`: 色 `0xFFFBBF24`、22pt、`w900`、`tabularFigures`
  3. **LIVES**（右寄せ Column）
     - ラベル `'LIVES'`: ラベル共通スタイル、下に `SizedBox(height: 4)`
     - `Icons.favorite`（サイズ 20、左右 padding 2）を 3 個並べ、`index < _lives` は `0xFFF43F5E`、それ以外は `0xFF334155`
  4. **一時停止/再開 `IconButton`**
     - アイコン: `playing` 時 `Icons.pause_circle_filled`、それ以外 `Icons.play_circle_filled`（色 `0xFF38BDF8`、サイズ 30）
     - tooltip: `playing` 時 `'一時停止'`、それ以外 `'再開'`
     - 押下: `playing` → 一時停止、`paused` → 再開、その他の状態では何もしない

### 8.4 オーバーレイ `_buildOverlay(BuildContext)`
- 状態ごとの表示内容:

| 状態 | タイトル | 説明文 | ボタン | アクセント色 | ボタン動作 |
| --- | --- | --- | --- | --- | --- |
| `ready` | `BLOCK BREAKER` | `画面をタップまたはドラッグしてスタート\n(矢印キー / A, D キーでも操作可能)` | `GAME START` | `0xFF38BDF8` | `_startGame` |
| `paused` | `PAUSED` | `ゲーム一時停止中` | `RESUME` | `0xFFFBBF24` | `_startGame` |
| `gameOver` | `GAME OVER` | `最終スコア: $_score 点` | `RETRY` | `0xFFF43F5E` | 完全リセット → 開始 |
| `gameClear` | `STAGE CLEAR!` | `おめでとうございます！全ブロックを破壊しました！\nスコア: $_score 点` | `PLAY AGAIN` | `0xFF34D399` | 完全リセット → 開始 |
| `playing` | — | — | — | — | `SizedBox.shrink()` を返す |

- レイアウト:
  - `Container`（`Colors.black` 不透明度 `0.75`）→ `Center` → `Padding(24)` → `Column(mainAxisSize: min)`
  - タイトル: 中央揃え、32pt、`w900`、`letterSpacing 2.0`、アクセント色、`Shadow`（アクセント色 不透明度 0.6、`blurRadius 16`）
  - `SizedBox(height: 16)`
  - 説明文: 中央揃え、色 `0xFFCBD5E1`、14pt、`height 1.5`
  - `SizedBox(height: 28)`
  - `ElevatedButton`: 背景アクセント色、前景 `Colors.black`、`elevation 8`、padding 横 36 / 縦 14、角丸 30。
    ラベル 16pt、bold、`letterSpacing 1.0`

### 8.5 ボトムコントロール `_buildBottomControls()`
- `Container`: padding 横 `24` / 縦 `12`、背景 `Color(0xFF0B132B)`
- `Row`（`MainAxisAlignment.spaceEvenly`）:
  1. **左移動ボタン**: `GestureDetector`
     - `onTapDown` → `_isLeftPressed = true`、`onTapUp` / `onTapCancel` → `false`（いずれも `setState`）
     - 外観: padding 横 32 / 縦 12、背景 `0xFF1E293B`、角丸 16、枠線 `0xFF38BDF8` 不透明度 0.5 幅 1.5、`Icons.arrow_left`（色 `0xFF38BDF8`、サイズ 36）
  2. **リセットボタン**: `IconButton`
     - tooltip `'最初からやり直す'`、`Icons.refresh`（色 `0xFF94A3B8`、サイズ 28）
     - 押下: `_ticker.stop()` 後、`setState` 内で `_initGame(fullReset: true)`（`ready` 状態に戻る）
  3. **右移動ボタン**: 左ボタンと同じ外観で `Icons.arrow_right`、`_isRightPressed` を操作

---

## 9. テスト要件 (`test/widget_test.dart`)

- `package:flutter_test/flutter_test.dart` と `package:handson_2026_breakout/main.dart` を import すること。
- テスト名 `'Breakout game smoke test'` の `testWidgets` を 1 件定義すること:
  1. `await tester.pumpWidget(const MyApp())`
  2. `find.text('BLOCK BREAKER')` が `findsOneWidget`
  3. `find.text('GAME START')` が `findsOneWidget`
  4. `find.text('SCORE')` が `findsOneWidget`
- 実行コマンド: `flutter test`
