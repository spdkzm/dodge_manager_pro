# Dodge Manager Pro

ドッジボールチームの運営を支援する、Windowsタブレット（10インチ・横画面）向け統合アプリケーションです。
チーム管理、試合のリアルタイム記録、データの永続化を一元管理します。

## ✨ 主な機能

### 1. 試合記録 (Game Record)
- **自由なボタン配置 (Layout)**:
  - ドラッグ＆ドロップでアクションボタンの配置を自由に変更可能。
  - 空白スペースの挿入や、列数の変更に対応。
- **動的アクション生成**:
  - 設定に基づき、「アタック(成功)」「アタック(失敗)」などのボタンを自動生成。
  - 「成功のみ」「失敗のみ」「結果なし」など、アクションごとの特性に合わせてボタンを出し分け。
- **誤操作防止**:
  - 「コート」タブにいる選手のみが記録対象となります（ベンチ・欠席の選手はタップ無効）。
- **運用サポート**:
  - 試合終了後も、直前の「コート/ベンチ」の配置を維持（連続した試合入力がスムーズ）。
  - タイム機能付き試合タイマー。

### 2. データ分析 (Analysis)
蓄積されたデータを集計し、選手のパフォーマンスを可視化します。
- **柔軟な期間集計**:
  - 累計、年間、月間、および任意の日付範囲指定での集計が可能。
- **正確な試合数カウント**:
  - プレー記録がない選手でも、コートに出場していれば「試合数」にカウント（出場記録テーブル連携）。
- **詳細なスタッツ表示**:
  - **成功数 / 失敗数 / 成功率 (%)** をアクションごとに並列表示。
  - **1試合平均 (Av)** や **詳細内訳 (サブアクション)** の表示も設定でON/OFF可能。
- **ランキング機能**:
  - 各項目のヘッダーをタップしてソート（昇順/降順）。
  - チーム内トップの成績を**緑色の太字**で自動ハイライト。

### 3. チーム管理 (Team Management)
選手とチームの基本情報を管理します。
- **名簿管理**:
  - 氏名、背番号、**コートネーム**、詳細情報の登録・編集。
  - 項目（スキーマ）の追加・削除・並び替えが可能。
- **データ保全**:
  - **CSVエクスポート**: 任意の場所にファイルを保存可能（Windowsファイルダイアログ対応）。
  - **CSVインポート**: 外部データの一括取り込み。

### 4. 統合設定 (Settings)
アプリ全体のカスタマイズを行うハブ機能です。
- **アクション定義**:
  - 「成功」「失敗」の記録有無を個別に設定。
  - 結果に応じた詳細項目（「正面」「パスミス」など）の定義。
- **レイアウト設定**:
  - 試合記録画面のボタン配置をグリッド上で編集。

---

## 🛠 技術スタックとアーキテクチャ

保守性と拡張性を重視し、**Clean Architecture** を意識したレイヤー構造とモダンなFlutterライブラリを採用しています。

- **Framework**: Flutter (Windows Target)
- **State Management**: `Riverpod` (HooksRiverpod)
  - 依存性注入(DI)とアプリケーションの状態管理。
- **UI Logic**: `Flutter Hooks`
  - `StatefulWidget`のボイラープレートを削減し、ライフサイクルを簡潔に記述。
- **Data Model**: `Freezed` & `json_serializable`
  - イミュータブルなデータモデルとJSON変換ロジックを自動生成。
- **Database**: `sqflite_common_ffi` (SQLite v7)
  - **DAOパターン**を採用し、データ操作の責務を分離。
  - テーブル構成: `teams`, `fields`, `items`, `action_definitions`, `matches`, `match_logs`, `match_participations`

## 📂 プロジェクト構造

機能（Feature）ごとにディレクトリを分割し、その内部でレイヤーを分けています。

```text
lib/
  ├─ main.dart           # エントリーポイント (ProviderScope, DB初期化)
  ├─ root_screen.dart    # 統合ナビゲーション (NavigationRail)
  │
  ├─ core/database/      # 共通インフラ
  │   └─ database_helper.dart  # DB接続・テーブル作成のみを担当
  │
  ├─ features/
  │   ├─ game_record/    # 【試合記録機能】
  │   │   ├─ application/# GameRecorderController (タイマー, ログ操作, 保存ロジック)
  │   │   ├─ data/       # MatchDao (試合・ログ・出場記録のSQL操作)
  │   │   ├─ domain/     # LogEntry, MatchRecord などのモデル
  │   │   └─ presentation/
  │   │       ├─ pages/  # MatchRecordScreen (記録画面)
  │   │       └─ widgets/# TimerBar, OperationPanel, PlayerSelectionPanel 等の部品
  │   │
  │   ├─ analysis/       # 【データ分析機能】
  │   │   ├─ application/# AnalysisController (集計ロジック)
  │   │   ├─ domain/     # PlayerStats (集計結果モデル)
  │   │   └─ presentation/
  │   │       └─ pages/  # AnalysisScreen (集計表、ソート、フィルタ表示)
  │   │
  │   ├─ team_mgmt/      # 【チーム管理機能】
  │   │   ├─ application/# TeamStore (チーム状態管理)
  │   │   ├─ data/       # TeamDao, CsvExportService, CsvImportService
  │   │   ├─ domain/     # Team, RosterItem, Schema
  │   │   └─ presentation/# PlayerListScreen, SchemaSettingsScreen 等
  │   │
  │   └─ settings/       # 【統合設定機能】
  │       ├─ data/       # ActionDao (アクション定義・配置のSQL操作)
  │       ├─ domain/     # ActionDefinition
  │       └─ presentation/
  │           ├─ pages/  # UnifiedSettings, ButtonLayoutSettings, ActionSettings 等