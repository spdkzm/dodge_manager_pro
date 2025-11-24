# Dodge Manager Pro

ドッジボールチームの運営を支援する、Windowsタブレット（10インチ・横画面）向け統合アプリケーションです。
既存の「試合記録アプリ」と「名簿管理アプリ」を統合し、一つのプラットフォームで運用できるように設計されています。

## 機能概要

### 1. 試合記録 (Game Record)
- **リアルタイム記録**: 試合タイマー（5分計など）と連動したプレーログ記録。
- **ベンチワーク**: コート・ベンチ・欠席の選手配置管理。
- **履歴保存**: 試合結果のローカル保存と閲覧（Shared Preferences使用）。

### 2. チーム管理 (Team Management)
- **名簿管理**: 選手の詳細情報（氏名、連絡先、生年月日、年齢自動計算など）の管理。
- **カスタマイズ**: 管理項目の追加・変更（スキーマ設定）。
- **データ連携**: CSV形式でのインポート・エクスポート。
- **データベース**: SQLiteによる堅牢なデータ保存（Windows対応）。

## 開発環境

- **Framework**: Flutter
- **Target Platform**: Windows (10/11)
- **Database**:
    - `shared_preferences` (簡易設定・ログ)
    - `sqflite_common_ffi` (名簿データ)

## プロジェクト構造

機能ごとにディレクトリを分割して管理しています。

```text
lib/
  ├─ main.dart           # アプリのエントリーポイント (Windows DB初期化)
  ├─ root_screen.dart    # 統合ナビゲーション (NavigationRail)
  │
  ├─ features/
  │   ├─ game_record/    # 旧・試合記録アプリのソースコード
  │   └─ team_mgmt/      # 旧・名簿管理アプリのソースコード