# Dodge Manager Pro

ドッジボールチームの運営を支援する、Windowsタブレット（10インチ・横画面）向け統合アプリケーションです。
チーム管理、試合のリアルタイム記録、データの永続化を一元管理します。

## 技術スタックとアーキテクチャ

本プロジェクトは、保守性と拡張性を最大化するためにモダンなFlutterアーキテクチャを採用しています。

- **Framework**: Flutter (Windows)
- **State Management**: `Riverpod` (HooksRiverpod)
  - 依存性注入(DI)とアプリケーションの状態管理を担当。
- **UI Logic**: `Flutter Hooks`
  - `StatefulWidget`のボイラープレートを削減し、コントローラーのライフサイクルを簡潔に記述。
- **Data Model**: `Freezed` & `json_serializable`
  - イミュータブルなデータモデルとJSON変換ロジックを自動生成。
- **Database**: `sqflite_common_ffi` (SQLite v4)
  - チーム、選手、試合ログ、設定データを永続化。

### レイヤー構造 (Clean Architecture風)

機能ごとにディレクトリを分割し、その内部で役割分担を明確にしています。

- **Presentation (UI)**: `HookConsumerWidget` を使用。ロジックを持たず、Controllerの状態を描画するだけ。
- **Application (Logic)**: `ChangeNotifier` + `Provider`。ビジネスロジック、状態保持、DB操作の呼び出し。
- **Domain (Model)**: `Freezed` で生成されたデータ型。アプリの中核となるデータ定義。
- **Data (Infrastructure)**: `DAO` パターンを採用。SQLiteへの具体的なSQL操作を隠蔽。

## プロジェクト構造

```text
lib/
  ├─ main.dart           # エントリーポイント (ProviderScope, DB初期化)
  ├─ root_screen.dart    # 統合ナビゲーション
  │
  ├─ core/database/      # 共通基盤
  │   └─ database_helper.dart  # DB接続・テーブル作成のみを担当
  │
  ├─ features/           # 機能モジュール
  │   │
  │   ├─ game_record/    # 【試合記録機能】
  │   │   ├─ application/
  │   │   │   └─ game_recorder_controller.dart # 試合進行ロジック (Riverpod)
  │   │   ├─ data/
  │   │   │   └─ match_dao.dart    # 試合データのSQL操作
  │   │   ├─ domain/
  │   │   │   └─ models.dart       # Freezedモデル (LogEntry, MatchRecord等)
  │   │   └─ presentation/
  │   │       ├─ pages/            # MatchRecordScreen, HistoryScreen
  │   │       └─ widgets/          # 分割されたUI部品 (TimerBar, OperationPanel等)
  │   │
  │   ├─ team_mgmt/      # 【チーム管理機能】
  │   │   ├─ application/
  │   │   │   └─ team_store.dart   # チーム状態管理 (Riverpod)
  │   │   ├─ data/
  │   │   │   ├─ team_dao.dart     # チーム・選手のSQL操作
  │   │   │   └─ csv_..._service.dart
  │   │   ├─ domain/               # Team, RosterItem, Schema (Freezed適用推奨)
  │   │   └─ presentation/         # PlayerListScreen, TeamManagementScreen 等
  │   │
  │   └─ settings/       # 【統合設定機能】
  │       ├─ data/
  │       │   └─ action_dao.dart   # アクション定義のSQL操作
  │       ├─ domain/
  │       │   └─ action_definition.dart # Freezedモデル
  │       └─ presentation/
  │           ├─ pages/            # UnifiedSettings, ActionSettings 等
  │           └─ match_environment_screen.dart # Hooksを使用した設定画面