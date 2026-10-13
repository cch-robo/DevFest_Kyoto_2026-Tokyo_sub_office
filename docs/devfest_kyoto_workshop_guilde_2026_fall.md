# [DevFest Kyoto 2026 - 東京出張所](https://gdgkyoto.connpass.com/event/408828/)

## AI × Flutter ミニアプリ開発ワークショップ 環境設定ガイド (2026)

本ドキュメントは、AIツールおよびエージェントを活用してFlutterミニアプリを開発するワークショップ参加者向けの開発環境セットアップ・管理マニュアルです。

- ワークショップでは、Google アカウントを使った Gemini 無料枠を利用します。  
  ワークショップに関心を持った方々に幅広く参加していただけるよう、Google アカウントの Gemini 無料枠を利用します。  
  参加者ご自身の Google アカウントを使いますが、AI利用のためだけの新規アカウント作成やクレジットカード登録は不要です。

  - Google アカウントの [Gemini 無料枠には、利用可能モデルや使用量制限がある](https://support.google.com/gemini/answer/17004136?hl=ja&sjid=9846380269382269129-NC)ことに注意してください。  
    ①無料枠で使えるモデルは、Gemini Flash-Lite のみです。  
    ②無料枠の使用量上限のリセットは週単位です。（**上限になれば翌週まで使えません**）  
    ③無料枠のコンテキストサイズは、1M(100万)トークンです。（推論力に制限があります）  
    ④プロンプトの複雑度や会話の長さにより使用量の消費が増大します。  

  - Antigravity 無料枠と Gemini web Apps 無料枠は分かれています。  
    このため Antigravity 無料枠の上限になっても、Gemini Web Apps は利用できます。  
    **無料枠の方は、ワークショプ前の数日間の Anitigravity 利用を控えていただくよう願います。**

_本ドキュメントは、Geminiを使って調査｜生成されたドキュメントをベースに作成しました。_

---

## 目次

1. [Flutter SDK ＆ Dart SDK](#1-flutter-sdk--dart-sdk)
2. [Antigravity CLI](#2-antigravity-cli)
3. [Ollama (ローカルLLM実行基盤)](#3-ollama-ローカルllm実行基盤)
4. [Crush CLI](#4-crush-cli)
5. [その他 (お好みの IDE を用意してください)](#5-その他)

---

## 1. Flutter SDK ＆ Dart SDK

### 概要説明

* **Flutter / Dart SDK とは**: 単一コードからマルチプラットフォームアプリを構築するフレームワーク（Flutter）とプログラミング言語（Dart）です。
* **Dart SDKの同梱仕様**: Dart SDK は Flutter SDK の `bin/cache/dart-sdk` 内に同梱されています。Flutter SDK に PATH を通せば個別に Dart をインストールする必要はありません。

### インストール・アンインストール手順

#### A. インストール

* **macOS / Linux**:
1. 依存するパッケージのインストール  
   ```bash
   # macOS ｰ Gitをインストール
   xcode-select --install
   ```
   ```bash
   # Linux ｰ 依存パッケージ一式をインストール
   sudo apt-get update -y && sudo apt-get upgrade -y
   sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
   ```
2. [Install Flutter manually](https://docs.flutter.dev/install/manual) ページから `Flutter SDK bundle (macOS|Linux)` をダウンロード  
   　
3. `~/development` に展開：  
   _ディレククトリ名は任意なので、`development`でなくても構いません。_ 　
4. シェル環境変数 `PATH` に `flutter`コマンドラインツールへのパスを追加。  
   `export PATH=$HOME/development/flutter/bin`
   ```bash
   # 3〜4手順一式
   mkdir -p ~/development && cd ~/development
   unzip ~/Downloads/flutter_macos_*.zip
   echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

* **Windows**:
1. 依存するパッケージのインストール  
   Windows版Gitの最新バージョンの [ダウンロード](https://git-scm.com/install/windows)＆[インストール](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
2. [Install Flutter manually](https://docs.flutter.dev/install/manual) ページから `Flutter SDK bundle (Windows)` をダウンロード  
   　
3. `C:\Users\<ユーザー名>\development\flutter` 等（管理者権限が不要な場所）に展開。  
   _ディレククトリ名は任意なので、`development`でなくても構いません。_  
4. システム環境変数 `Path` に`flutter`コマンドラインツールへのパスを追加。  
   `C:\Users\<ユーザー名>\development\flutter\bin`


#### B. アンインストール

* **macOS / Linux**:
   ```bash
   rm -rf ~/development/flutter
   rm -rf ~/.pub-cache ~/.flutter ~/.dart-tool ~/.dart
   # ~/.zshrc または ~/.bashrc から追加した PATH 行を削除
   ```

* **Windows (PowerShell)**:
   ```powershell
   Remove-Item -Recurse -Force "$env:USERPROFILE\development\flutter"
   Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache"
   Remove-Item -Recurse -Force "$env:USERPROFILE\.flutter"
   Remove-Item -Recurse -Force "$env:USERPROFILE\.dart-tool"
   Remove-Item -Recurse -Force "$env:USERPROFILE\.dart"
   # 環境変数 Path から flutter\bin を削除
   ```

### 実行ファイル ＆ 設定保管先一覧

| 項目 | macOS / Linux | Windows | 役割・内容 |
| --- | --- | --- | --- |
| **Flutter 実行バイナリ** | `~/development/flutter/bin/flutter` | `...\flutter\bin\flutter.bat` | Flutter CLI 本体 |
| **Dart 実行バイナリ** | `~/development/flutter/bin/dart` | `...\flutter\bin\dart.bat` | バンドル版 Dart CLI |
| **グローバル Pub キャッシュ** | `~/.pub-cache/` | `%LOCALAPPDATA%\Pub\Cache\` | ダウンロード済みパッケージ |
| **Flutter 全体設定** | `~/.flutter` | `%USERPROFILE%\.flutter` | CLIアナリティクス設定等 |
| **Dart 設定** | `~/.dart-tool/` / `~/.dart/` | `%USERPROFILE%\.dart-tool\` | ツール共通設定 |

### 動作検証

```bash
flutter doctor
```

`Flutter` および `Android toolchain` に問題がないことを確認します。

### 参考元資料

* [Flutter 公式： Install Flutter manually](https://docs.flutter.dev/install/manual)
* [Flutter 公式： Uninstall Flutter](https://docs.flutter.dev/install/uninstall)
* [Dart 公式: Dart SDK ダウンロード・仕様](https://dart.dev/get-dart)
* [Dart 公式: Pub パッケージキャッシュの管理](https://dart.dev/tools/pub/environment-variables)

---

## 2. Antigravity CLI

### 概要説明
- **Antigravity CLI (`agy`) とは**: Google Antigravityのエージェント実行基盤をターミナルから直接利用できる軽量なTUIツールです。Go言語製で高速に動作します。
- **ワークショップでの役割**: Flutterプロジェクトのコード生成、ファイル編集、静的解析・テストの自律実行、およびMCP（Model Context Protocol）経由でのエミュレータ操作やホットリロード自動化を担当します。

### インストール・アンインストール手順

#### A. インストール
- **macOS / Linux**:
```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

*(Homebrewを利用する場合: `brew install --cask antigravity-cli`)*

* **Windows (PowerShell 推奨)**:
```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

* **Windows (コマンドプロンプト)**:
```cmd
curl -fsSL https://antigravity.google/cli/install.cmd -o install.cmd && install.cmd && del install.cmd
```

#### B. 初回起動と初期設定

1. ターミナルで `agy` を実行します。
2. ブラウザが起動し、GoogleアカウントのOAuth認証画面が表示されるため、ログイン・承認を完了します。
3. ターミナル表示に従い、テーマ（Color Scheme）や描画モード（Alt-Screen推奨）を設定します。
4. プロンプト入力欄が表示されたら設定完了です（終了は `Ctrl + C` または `/exit`）。

#### C. アンインストール

* **macOS / Linux**:
```bash
rm -f ~/.local/bin/agy
rm -rf ~/.gemini/antigravity-cli
```

* **Windows (PowerShell)**:
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\agy"
Remove-Item -Recurse -Force "$env:USERPROFILE\.gemini\antigravity-cli"
```

### 実行ファイル ＆ 設定保管先一覧

| 項目 | macOS / Linux | Windows | 備考 |
| --- | --- | --- | --- |
| **実行バイナリ (`agy`)** | `~/.local/bin/agy` | `%LOCALAPPDATA%\agy\bin\agy.exe` | 要PATH設定 |
| **全体設定ファイル** | `~/.gemini/antigravity-cli/settings.json` | `%USERPROFILE%\.gemini\antigravity-cli\settings.json` | モデル選択・権限設定 |
| **キーバインド設定** | `~/.gemini/antigravity-cli/keybindings.json` | `%USERPROFILE%\.gemini\antigravity-cli\keybindings.json` | ショートカット設定 |
| **プロジェクト個別設定** | `<プロジェクトルート>/.agents/` | `<プロジェクトルート>\.agents\` | MCP・個別設定 |

### 動作検証

```bash
agy --version
```

バージョンが出力されれば正常です。

### 参考元資料

* [Google Antigravity CLI 概要（公式）](https://antigravity.google/docs/cli/overview/)
* [Antigravity CLI スタートガイド（公式）](https://antigravity.google/docs/cli/getting-started)
* [Antigravity CLI コマンド・設定リファレンス（公式）](https://antigravity.google/docs/cli/reference/)
* [Antigravity CLI - CLI reference | Google Antigravity Docs](https://antigravity.google/docs/cli/reference)
* [Flutter公式: Get started developing with AI (Antigravity CLI)](https://docs.flutter.dev/ai/get-started)

---

## 3. Ollama (ローカルLLM実行基盤)

### 概要説明

* **Ollama とは**: Gemma 3/4、Llama 3 などのオープンウェイトLLMをローカルPC上で手軽にダウンロード・実行できるランタイムです。
* **ワークショップでの役割**: クラウドAPIキーの利用制限を気にせず、ローカル完結でアプリの開発にAIを活用するためのバックエンド（REST API: ポート `11434`）として活用します。

### インストール・アンインストール手順

#### A. インストール

* **macOS / Linux (Script)**: 
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

* **Windows**:  
```bash
irm https://ollama.com/install.ps1 | iex
```

#### B. モデルのダウンロード＆チャット実行

- **`ollama pull gemma4:e4b` を実行したら削除しないでください。**  
  Gemma4:e4b モデルは、ワークショップで利用します。また小型といえどもディスクを 9.6 GB占有します。  
  このため `ollama pull gemma4:e4b` でモデルをローカルにダウンロードしたままにしてください。（削除しないでね）

  - （オプション）Qwen3.8:27B を試してみる。  
    Applie Sillicon RAM 32GB以上, DISK 30GB 以上の空きがあれば、`ollama pull qwen3.8:27b` も試してみてください。
  

```bash
# Gemma4 e4b モデルをダウンロード
ollama pull gemma4:e4b
```

```bash
# ダウンロード済みのモデル一覧確認
ollama ls
```

```bash
# ダウンロード済みのモデル削除
ollama rm gemma4:e4b
```

#### B2. CLI でのチャット＆プロセス確認（オプション）

```bash
# チャット実行（モデルが未ダウンロードだとダウンロードしてからチャット実行）
ollama run gemma4:e4b
```

- **チャット機能は、macOS ｜ Windows ならデスクトップアプリを使うほうが手軽です。**

- CLI チャットモードで利用可能なコマンド  
  `/clear`: コンテキストクリア  
  `/bye` または `Ctrl + D`: チャット終了  
  `/help`: 利用可能なコマンド一覧  

- CLI チャットモードで利用するコンテキストサイズ設定  
  モデルごとに利用可能なコンテキストサイズを環境変数に設定する必要があります。  
  Gemma4:e4bは、128Kなので以下のような設定が必要になります。  
  `export OLLAMA_CONTEXT_LENGTH=131072"`  

```bash
# 稼働中のモデルプロセス一覧を表示 （Gemma4 e4b でチャット中の場合）
ollama ps
NAME          ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
gemma4:e4b    c6eb396dbd59    3.9 GB    100% GPU     131072     llamacpp    4 minutes from now    
```

#### C. アンインストール

* **macOS**:
```bash
sudo rm -rf /Applications/Ollama.app
sudo rm /usr/local/bin/ollama
rm -rf "~/Library/Application Support/Ollama"
rm -rf "~/Library/Saved Application State/com.electron.ollama.savedState"
rm -rf ~/Library/Caches/com.electron.ollama/
rm -rf ~/Library/Caches/ollama
rm -rf ~/Library/WebKit/com.electron.ollama
rm -rf ~/.ollama
```

* **Windows (PowerShell)**:
```powershell
# タスクトレイから終了後、通常アンインストールを実行
Remove-Item -Recurse -Force "$env:USERPROFILE\.ollama"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Programs\Ollama"
```

* **Linux**:

```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm /etc/systemd/system/ollama.service

sudo rm -r $(which ollama | tr 'bin' 'lib')
sudo rm $(which ollama)

sudo userdel ollama
sudo groupdel ollama
sudo rm -r /usr/share/ollama
```

### 実行ファイル ＆ モデル保管先一覧

| 項目 | macOS | Windows | Linux | 備考 |
| --- | --- | --- | --- | --- |
| **実行バイナリ** | `/usr/local/bin/ollama` | `%LOCALAPPDATA%\Programs\Ollama\ollama.exe` | `/usr/local/bin/ollama` | CLIバイナリ |
| **モデル保管先** | `~/.ollama/models` | `%USERPROFILE%\.ollama\models` | `/usr/share/ollama/.ollama/models` | 重みデータ (`blobs/`) |
| **設定・キーペア** | `~/.ollama/` | `%USERPROFILE%\.ollama\` | `/usr/share/ollama/.ollama/` | 設定一式 |

> **ストレージ容量対策**:
> モデルの保存先を外付けドライブ等に変更したい場合は、環境変数 `OLLAMA_MODELS`（例: `D:\OllamaModels`）を設定します。

### 動作検証

```bash
ollama --version
curl http://localhost:11434/
```

`Ollama is running` と返答があれば正常稼働しています。

### 参考元資料

* [Ollama 公式Webサイト](https://ollama.com/)
* [Ollama GitHub リポジトリ（公式）](https://github.com/ollama/ollama)
* [Ollama FAQ・モデル保存先や環境変数設定ドキュメント（公式）](https://www.google.com/search?q=https://github.com/ollama/ollama/blob/main/docs/faq.md)
* [Ollama REST API ドキュメント（公式）](https://github.com/ollama/ollama/blob/main/docs/api.md)
* [Ollama macOS](https://docs.ollama.com/macos)
* [Ollama Linux](https://docs.ollama.com/linux)
* [Ollama Windows](https://docs.ollama.com/windows)
* [Download Ollama](https://ollama.com/download)

---

## 4. Crush CLI

### 概要説明

* **Crush CLI とは**: Charm社（Charmbracelet）のTUIフレームワークをベースに構築されたAIコーディングエージェントCLIです。
* **ワークショップでの役割**: ターミナル上でGeminiやローカルのOllamaと接続し、Flutterプロジェクト構造の把握、差分パッチ適用、コマンド実行支援を行います。

### インストール・アンインストール手順

#### A. インストール

* **macOS / Linux (Homebrew)**:
```bash
brew install charmbracelet/tap/crush
```

* **Windows (WinGet)**:
```powershell
winget install charmbracelet.crush
```

#### B. ワークスペース設定＆起動

`Crush CLI` は、`Calude Code` のように任意のディレクトリをワークスペース①にして、
各種構成ファイルや Agent Skills ディレクトリを設定ファイルを置くことができます。

- ワークスペース① ⇒ Flutterアプリならプロジェクトディレクトリ
- 構成ファイル②
  - コンテキストファイル ⇒ `AGENTS.md`（`CRUSH.md`）ファイル
  - Agent Skills ディレクトリ ⇒ `.agents/skills/` ディレクトリ
  - システム設定 ⇒ `.crushrc` ファイル

* `.crushrc` ファイル例

```bash
# Add Ollama.
provider add ollama --type ollama --base-url "http://localhost:11434/v1"

# Register a model on Ollama.
model add ollama/gemma4:e4b --name "Gemma4:e4b" --context-window 128000

# 32GB RAM 以上の Apple Sillicon mac ならコメントアウトをオフ
# model add ollama/qwen3.8:27b --name "Qwen3.8:27b" --context-window 256000

# Auto-approve some tools.
permissions allow view edit

# MCP（Model Context Protocol）ツールの追加
mcp add dart-mcp-server --command "dart" --args "mcp-server"

# Prompt timeout 時間をデフォルトの2分(120)から無制限にする。
option request-timeout 0
```

#### C. アンインストール

* **macOS / Linux (Homebrew)**:
```bash
brew uninstall crush 2>/dev/null || rm -f ~/.local/bin/crush

# グローバルの設定｜セッション履歴｜ログを一括削除
rm -rf ~/.config/crush ~/.local/share/crush ~/.cache/crush
```

* **Windows (WinGet)**:
```powershell
winget uninstall charmbracelet.crush --purge

# Crushが保持しているローカルの設定・データフォルダを一括削除
Remove-Item -Recurse -Force "$env:APPDATA\crush"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\crush"
```

### 実行ファイル ＆ 設定保管先一覧

| 項目 | macOS / Linux | Windows | 備考 |
| --- | --- | --- | --- |
| **実行バイナリ** | `/opt/homebrew/bin/crush` または `~/.local/bin/crush` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\crush.exe` | 実行本体 |
| **設定ファイル** | `~/.config/crush/` | `%APPDATA%\crush\` | プロバイダ・UI設定 |
| **セッション・対話ログ** | `~/.local/share/crush/` | `%LOCALAPPDATA%\crush\data\` | チャット履歴 |
| **キャッシュ** | `~/.cache/crush/` | `%LOCALAPPDATA%\crush\cache\` | 一時データ |

### 動作検証

```bash
crush --version
```

バージョン情報が出力されることを確認します。

### 参考元資料

* [Charm 公式Webサイト](https://charm.sh/)
* [Charmbracelet GitHub リポジトリ（公式）](https://github.com/charmbracelet/crush)

---

## 5. その他

Flutter アプリのコードを見るため、お好みの IDE を御自身で用意しておいてください。
* [Flutter 公式 - Android Studio and IntelliJ](https://docs.flutter.dev/tools/android-studio)  
  [Flutter 公式 - Run DevTools from Android Studio](https://docs.flutter.dev/tools/devtools/android-studio)

* [Flutter 公式 - Visual Studio Code](https://docs.flutter.dev/tools/vs-code)  
  [Flutter 公式 - Run DevTools from VS Code](https://docs.flutter.dev/tools/devtools/vscode)

---
