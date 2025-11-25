# Dodge Manager Pro

ドッジボールチームの運営を支援する、Windowsタブレット（10インチ・横画面）向け統合アプリケーションです。
チーム管理、試合のリアルタイム記録、データの永続化を一元管理します。

## アーキテクチャ概要

本プロジェクトは機能ごとにディレクトリを分割し、内部で **Presentation (UI)**、**Application (Logic)**、**Data (DB Access)** のレイヤー構造を採用しています。

- **Presentation**: 画面描画とユーザー操作の受け付け。複雑なロジックは持たず、Controllerを呼び出す。
- **Application**: アプリケーションの状態管理、タイマー処理、バリデーションなどのビジネスロジック。
- **Data (DAO)**: SQLiteデータベースへの直接的なアクセス（CRUD操作）を担当。

## プロジェクト構造とファイル詳細

### 📂 lib/ (ルート)
- **`main.dart`**: アプリのエントリーポイント。Windows用SQLiteライブラリ(`sqflite_common_ffi`)の初期化、日本語ロケールの設定、テーマ設定を行う。
- **`root_screen.dart`**: アプリ全体のナビゲーションシェル。左側の `NavigationRail` で「試合記録」「チーム管理」「設定」の各画面を切り替える。

---

### 📂 lib/features/game_record/ (試合記録機能)

#### 📁 application/
- **`game_recorder_controller.dart`**: 試合記録画面の「頭脳」。タイマーのカウントダウン、ログの追加・削除、DBへの保存処理、選手交代ロジックなどを一手に引き受ける `ChangeNotifier`。

#### 📁 data/
- **`match_dao.dart`**: 試合データ(`matches`)およびログデータ(`match_logs`)のSQLite操作（挿入・取得）を担当するDAO。

#### 📁 presentation/
- **`match_record_screen.dart`**: 試合記録のメイン画面。Controllerを監視し、以下のWidget部品を配置するレイアウト担当。
  - **📁 widgets/**
    - **`game_timer_bar.dart`**: 試合タイマー表示と、進行ボタン（開始/タイム/再開/終了）のUI部品。
    - **`player_selection_panel.dart`**: 左カラム。コート・ベンチ・欠席のタブ切り替えと選手リスト表示、複数選択移動モードのUI部品。
    - **`game_operation_panel.dart`**: 中央カラム。アクションボタンのグリッド表示、結果（成功/失敗）選択、詳細項目（サブアクション）選択のUI部品。
    - **`game_log_panel.dart`**: 右カラム。記録されたログの時系列リスト表示UI部品。

#### 📁 (root of feature)
- **`models.dart`**: 試合記録で使用するデータモデル (`LogEntry`, `MatchRecord`, `UIActionItem`, `ActionResult`)。
- **`history_screen.dart`**: 保存された過去の試合記録を一覧表示し、詳細ログを確認する画面。
- **`persistence.dart`**: (Legacy) アプリ終了時の一時データ保存(`SharedPreferences`)を担当。

---

### 📂 lib/features/team_mgmt/ (チーム・選手管理機能)

#### 📁 data/
- **`team_dao.dart`**: チーム(`teams`)、選手(`items`)、スキーマ定義(`fields`)のSQLite操作を担当するDAO。
- **`csv_import_service.dart`**: 外部CSVファイルから選手データを読み込み、DBにマージするサービス。
- **`csv_export_service.dart`**: 現在のチームデータをCSVファイルとして出力・共有するサービス。

#### 📁 presentation/
- **`main_screen.dart`**: チーム管理機能のルートWidget。現在は `PlayerListScreen` を表示するラッパー。
- **`player_list_screen.dart`**: 選手一覧の表示、追加・編集ダイアログ、ソート機能、フィルタリング機能を提供するメイン画面。
- **`team_management_screen.dart`**: チームの新規作成、名称変更、削除を行う管理画面。
- **`schema_settings_screen.dart`**: 名簿の管理項目（住所、電話番号、背番号など）の追加・変更・並び替えを行う画面。

#### 📁 (root of feature)
- **`team_store.dart`**: チームデータのキャッシュと状態管理を行う `ChangeNotifier`。アプリ全体で現在のチーム情報を保持する。
- **`database_helper.dart`**: SQLiteデータベース(`dodge_manager_v4.db`)の接続確立、テーブル作成(`onCreate`)のみを担当するシングルトン。
- **`team.dart`**: チーム情報のデータモデル。
- **`roster_item.dart`**: 選手個々のデータモデル（動的なMap構造を持つ）。
- **`schema.dart`**: 名簿項目の定義モデル（型、表示有無など）。

---

### 📂 lib/features/settings/ (統合設定機能)

#### 📁 data/
- **`action_dao.dart`**: アクション定義(`action_definitions`)のSQLite操作を担当するDAO。

#### 📁 domain/
- **`action_definition.dart`**: アクションボタンの設定モデル。成功/失敗フラグや、結果ごとの詳細項目(`subActionsMap`)を持つ。

#### 📁 presentation/
- **`unified_settings_screen.dart`**: 全設定メニュー（試合環境、アクション、チーム管理、CSVなど）へのアクセスを集約した画面。
- **`action_settings_screen.dart`**: アクションボタンの作成・編集画面。成功/失敗の記録有無や詳細項目を設定する。
- **`match_environment_screen.dart`**: 試合時間やボタン配置（列数）の設定画面。

---

## データベース設計 (SQLite v4)

- `teams`: チーム基本情報
- `fields`: 名簿の項目定義（スキーマ）
- `items`: 選手データ（JSON格納）
- `action_definitions`: アクションボタン定義（詳細項目はJSON格納）
- `matches`: 試合ヘッダー情報（対戦相手、日付）
- `match_logs`: 1プレーごとの詳細ログ（タイム、選手、アクション、結果）