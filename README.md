# 🏀 Dodge Manager Pro

**ドッジボール チーム管理・試合記録・データ分析アプリケーション**

Dodge Manager Pro は、ドッジボールチームの監督、コーチ、マネージャー向けに設計された、高機能なオールインワン管理ツールです。
Flutter で開発されており、特に Windows / macOS / Linux などのデスクトップ環境での利用に最適化されていますが、モバイル環境への展開も可能なアーキテクチャを採用しています。

## ✨ 主な機能 (Features)

### 1. チーム・名簿管理 (Team Management)
* **マルチチーム対応**: 複数のチームを作成し、サイドメニューから瞬時に切り替え可能。
* **カスタムスキーマ設計**:
  * 選手、対戦相手、会場の各リストに対して、必要な項目（住所、電話番号、学年、守備位置など）を自由に定義可能。
  * 入力タイプとして「テキスト」「数値（範囲指定可）」「日付」「プルダウン」「背番号」などをサポート。
  * 必須項目や重複禁止項目の設定が可能。
* **CSV インポート/エクスポート**: 既存のExcelデータなどをCSV経由で一括取り込み・出力が可能。

### 2. 試合記録 (Real-time Game Recording)
* **直感的な操作パネル**:
  * **ボタン配置カスタマイズ**: ドラッグ＆ドロップで記録ボタンの配置や列数を自由に変更可能。
  * **アクション定義**: 「アタック」「キャッチ」などのアクションに加え、「成功/失敗」や「詳細（コースなど）」を階層的に定義可能。
* **リアルタイムタイマー**: 試合時間のカウントダウン、一時停止、再開機能。
* **メンバー管理**:
  * 「コート」「ベンチ」「欠席」の状態を管理。
  * 複数選択モードにより、セット間のメンバー入れ替えがスムーズに行えます。
  * ベンチの選手は記録ボタンが無効化されるなど、誤入力防止機能も搭載。

### 3. データ分析 (Analytics)
* **多角的な集計**:
  * 期間（年/月/日）、試合種別（公式戦/練習試合）、特定の試合ごとにデータをフィルタリング。
* **プレイヤー別スタッツ**:
  * アクションごとの成功数、失敗数、成功率、試合数を自動計算。
  * CSV形式でのスタッツ出力に対応。
* **ログ編集**:
  * 記録ミスがあった場合、時系列ログから修正・削除が可能。
  * 試合終了後でも、スコアや勝敗結果、メンバー情報の修正が可能。

### 4. 設定・データ管理 (Settings & Data)
* **バックアップと復元**: データベースファイル (`.db`) を直接エクスポート/インポートし、機種変更やPC移行に対応。
* **試合環境設定**: デフォルトの試合時間や、スコア記録の有無などを設定可能。

## 🛠️ 技術スタック (Tech Stack)

* **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.x)
* **Language**: Dart
* **State Management**: [Riverpod](https://riverpod.dev/) (Hooks Riverpod)
* **Database**: [sqflite](https://pub.dev/packages/sqflite) (Mobile) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (Desktop)
* **Code Generation**: [Freezed](https://pub.dev/packages/freezed), [JSON Serializable](https://pub.dev/packages/json_serializable)
* **File I/O**: [file_picker](https://pub.dev/packages/file_picker), [csv](https://pub.dev/packages/csv), [share_plus](https://pub.dev/packages/share_plus)
* **Utility**: [intl](https://pub.dev/packages/intl), [uuid](https://pub.dev/packages/uuid)

## 📂 ディレクトリ構成 (Folder Structure)

フィーチャー（機能）ごとのディレクトリ構成を採用しており、メンテナンス性に優れています。

```text
lib/
├── core/
│   └── database/        # データベース接続・マイグレーション (database_helper.dart)
├── features/
│   ├── analysis/        # 分析機能 (Controller, UI, Models)
│   ├── game_record/     # 試合記録機能 (Controller, UI, DAO)
│   ├── match_info/      # 対戦相手・会場管理 (UI)
│   ├── settings/        # 設定・バックアップ・アクション定義 (UI, Logic)
│   └── team_mgmt/       # チーム・名簿管理・CSV処理 (UI, Logic, DAO)
├── main.dart            # エントリーポイント
└── root_screen.dart     # ルート画面 (NavigationRail)