# Antigarvity テクニック2026年秋版

このドキュメンは、`Anthropic の資料から抜粋された 2026年代の Claude Code 向けプロンプト技法についてのブログ記事` を参考に、
Google 公式の開発者ブログや Antigravity 公式ドキュメントを一次資料としてまとめた **2026年秋版のプロンプトテクニック** です。

Antigravity テクニックとなっていますが、Anthropic の Claude Code や OpenAI の Codex など、フロンティアモデルを利用するコーディングエージェントにも適用できると思います。

- ブログ記事
  - [5 Claude Tricks That Give You an Unfair Advantage (Most People Still Use the Old Way)](https://medium.com/ai-engineering-simplified/5-claude-tricks-that-give-you-an-unfair-advantage-most-people-still-use-the-old-way-0385a58057c7)

- **全体雑感**  
  - 基本的に **「開発者自身が、何のために何をするには、どのような制限があるので、どのように克服するのかを理解している」** ことを前提とする。  
  - 2025年までのようにプロンプトに具体的に詳細に手順（解法方法論の実現法）を書かない。
  - AI｜LLM 自体が解法方法論を学習したので、それらの **「専門知識の選択・コードへの適用・検証・評価・問題収束のための反復」が組み込まれたツールやスキル** を作る｜探す。
  - スキルやツールが適用されるよう連想させるキーワードを使って、かつ、AIの注意を散漫にさせないよう **短い言葉に圧縮** して伝える。
  - _具体的で詳細な手順（解法方法論の実現法）を記述するのは、AI｜LLMが学習していないことや領域であることが解ったときのみでよい。_

_本ドキュメントは、Geminiを使って調査｜生成されたドキュメントをベースに作成しました。_

---

#### 1. 指示を「禁止」ではなく「検証可能な成果物・肯定形」で制御する
* **概要:**  
  Claude における「何をしてはいけないかではなく、何をすべきかを指示する」という思想は、Antigravity ではさらに進み、**「検証可能なアクションとアーティファクト（成果物）の提出を義務付ける」** という形へ進化しています。「間違った変更をするな」と指示する代わりに、エージェントに対してテスト実行やブラウザ操作のエビデンス提出を肯定的に義務付けます。
* **参照URL:** [Build with Google Antigravity, our new agentic development platform](https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/)
* **記述箇所:**  
  * *"Agents communicate progress via Artifacts (screenshots, recordings) for easy verification."*（エージェントは容易な検証のために成果物〈スクリーンショットや画面録画〉を通じて進捗を報告する）
  * エージェントの挙動を否定形のプロンプトで縛るのではなく、完了条件（テスト通過やUIスナップショット）を明示して自律的に検証ループを回させる設計が標準となっています。

---

#### 2. 単純なプロンプトへの過剰な装飾・コンテキストの廃止（ピンポイント指定への転換）
* **概要:**  
  従来の「プロンプトに大量の前提ルールやXMLなどの複雑な構文を毎回詰め込む」手法から、**必要なコンテキストのみを明示的にアタッチする（Slash Commands / Target File Autocompletion）** 方式へと移行しています。CLI では不要なコンテキストを削ぎ落とし、最小限の入力で最速に動かすことが推奨されています。
* **参照URL:** [Google Antigravity CLI](https://antigravity.google/blog/introducing-google-antigravity-cli) / [Google Antigravity CLI Product Page](https://antigravity.google/product/antigravity-cli/)
* **記述箇所:**  
  * *"The Antigravity CLI is the most lightweight way to invoke, monitor, and interact with Antigravity agents, directly from your terminal... Snappy Experience: A minimal resource footprint designed for speed."*
  * *"Slash Commands. Access plugins, MCP, skills, and hooks configurations instantly via slash commands, quickly enhancing your workflow."*
  * 会話ごとに長い説明を書くのではなく、スラッシュコマンドや設定済みの Hooks・MCP を通じて最小限のプロンプトでエージェントを動かすスタイルが常識になっています。

---

#### 3. 「勝手に察してくれる」を排し、計画・承認フェーズを明確に分離する
* **概要:**  
  Claudeの「文脈を補完してくれると思い込まず、具体的に要件を指定する」という課題に対し、Antigravity 2.0 は **「いきなりコードを書かせず、探索と計画（Plan）を立てさせてユーザーが承認する」** アーキテクチャをOS・UIレベルで標準化しています。
* **参照URL:** [Introducing Google Antigravity 2.0](https://antigravity.google/blog/introducing-google-antigravity-2) / [Build with Google Antigravity, our new agentic development platform](https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/)
* **記述箇所:**  
  * *"You can synchronously have a conversation with an agent, view the artifacts it produces, and provide feedback directly on the artifacts to guide towards your desired outcomes."*
  * *"Deploy agents that autonomously plan, execute, and verify complex tasks across your editor, terminal, and browser."*
  * エージェントの暗黙的な推測に任せるのではなく、タスクリストや変更計画（Artifacts）を出力させ、人間が介入して要件のギャップを埋めてから実行させるプロセスが基本原則となっています。

---

#### 4. プロンプトの「think step by step」を手動で書く時代の終了（ネイティブ思考と非同期タスク管理）
* **概要:**  
  Claude がモデルのネイティブ思考（Extended / Adaptive Thinking）へ移行したのと同様に、Antigravity 2.0 でもプロンプトに呪文のようにステップ思考を指示する必要はありません。最新の Gemini モデルの思考能力と、Antigravity の **Asynchronous Task Management（非同期タスク管理）** によって、システム側で自律的にタスクを分解・並列実行します。
* **参照URL:** [Introducing Google Antigravity 2.0](https://antigravity.google/blog/introducing-google-antigravity-2)
* **記述箇所:**  
  * *"Asynchronous task management: Tasks and commands are managed and can run asynchronously to not block the main agent from continuing its work."*
  * *"The product, agent harness, and model layers all had to be co-optimized and co-developed..."*
  * モデルとエージェントハーネスが一体化してタスク分解や思考を行うため、プロンプトの工夫（プロンプトハック）ではなく、プラットフォームの自律実行エンジンに委ねることが常識となっています。

---

#### 5. 「分からない・勝手に動く」を防ぐための明示的なツール権限とフォールバック
* **概要:**  
  Claude の「分からないと言う許可を与える」というハルシネーション対策と同様、Antigravity 2.0 では **「エージェントが勝手な判断でツールを乱用したり推測で進めたりしないよう、境界線を明示する」** ための機能（明示的コマンドやJSONフック）が導入されています。
* **参照URL:** [Introducing Google Antigravity 2.0](https://antigravity.google/blog/introducing-google-antigravity-2)
* **記述箇所:**  
  * *"JSON hooks: You can now define hooks in a simple JSON format, allowing you to intercept and control the Antigravity agent's behavior."*
  * *"`/browser` : We heard the feedback that the agents were still not capable enough to determine exactly when to be using the browser. So for now, we've made it such that an explicit slash command controls these behaviors. When used, the agent diligently uses the browser primitives, and when not, it ignores them."*
  * エージェントの自律性にすべてを任せて暴走・推測させるのではなく、ブラウザ操作などの強力なツールは明示的なスラッシュコマンド（`/browser`）やインターセプト用の JSON フックで厳格に制御する思想へシフトしています。

---

#### 6. 【従来の常識からの変化】「IDEの中のAI」から「IDEの外で自律稼働するスタンドアロン・エージェント」へ
* **概要:**  
  これまでのコーディング支援AI（GitHub Copilot や従来のIDE統合型プラグイン）は「エディタの横に常駐するアシスタント」でした。しかし Antigravity 2.0 は **「エディタの枠を超えた独立したデスクトップアプリケーション（No IDE）」** として再設計され、ターミナル重視のユーザーには Antigravity CLI という別形態で提供されるなど、開発スタイルの常識が大きく変わっています。
* **参照URL:** [Introducing Google Antigravity 2.0](https://antigravity.google/blog/introducing-google-antigravity-2)
* **記述箇所:**  
  * *"Google Antigravity 2.0 is a new, standalone desktop application that fully delivers on a truly agent-optimized experience... and there is no IDE."*
  * *"Rearchitect the product to be agent-first from the ground up, independent of an IDE or other dev-specific concepts such as repositories."*
  * *"We recommend dual-wielding Antigravity 2.0 with your IDE of choice... Compatible extensions and plugins for other popular IDEs are coming shortly."*
  * AIにエディタの中だけで補完させるのではなく、独立したエージェント管理アプリ（Antigravity 2.0）や CLI から指示を出し、好みの IDE と「二刀流（dual-wielding）」で並行利用する運用が推奨されています。