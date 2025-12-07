# 🏀 Dodge Manager Pro

**ドッジボール チーム管理・試合記録・データ分析アプリ**

Dodge Manager Pro は、ドッジボールチームの監督、コーチ、マネージャー向けに開発された、高機能な管理・分析ツールです。
Windows/Mac/Linux などのデスクトップ環境での利用を主眼に置きつつ、Flutterによるクロスプラットフォーム設計となっています。

## ✨ 特徴 (Features)

### 👥 チーム・名簿管理
* **マルチチーム対応**: 複数のチームを作成し、ワンタップで切り替え可能。
* **柔軟な名簿設計 (スキーマ設定)**:
   * 背番号、名前だけでなく、住所、電話番号、学年など、チームに必要な項目を自由に追加・定義できます。
   * 入力方式も「プルダウン」「数値範囲」「日付」など細かく設定可能。
* **CSV連携**: 既存の名簿データをCSVで一括インポート・エクスポート可能。

### 📝 試合記録 (Real-time Recording)
* **直感的な操作パネル**:
   * カスタマイズ可能なボタン配置で、試合のスピードに合わせて「誰が・何をしたか」を即座に記録。
   * タイマー機能搭載（試合時間のカウントダウン、一時停止）。
* **メンバー管理**:
   * 「コート」「ベンチ」「欠席」のステータスを管理。複数選択モードでスムーズなメンバー交代が可能。
* **詳細なアクション記録**:
   * 単なる回数だけでなく、「成功/失敗」の判定や、詳細なコース（サブアクション）も記録できます。

### 📊 データ分析 (Analytics)
* **高度なフィルタリング**:
   * 全期間、年別、月別、日別、試合別での集計。
   * 「公式戦」「練習試合」などの種別による絞り込みに対応。
* **詳細スタッツ**:
   * 選手ごとの成功率、アクション数を自動計算。
   * 時系列のログ（タイムライン）表示で試合の流れを振り返り可能。
* **データ修正**: 記録ミスがあっても、後からログや出場メンバーを修正できます。
* **CSV出力**: 分析結果をCSVファイルとして保存し、Excel等で二次加工が可能。

### ⚙️ 高度なカスタマイズ & 管理
* **ボタン配置エディタ**: 記録画面のボタン配置をドラッグ＆ドロップで自由に変更。
* **アクション定義**: チーム独自の用語や集計ルールに合わせてアクションを作成。
* **バックアップ**: データベース全体をファイルとしてバックアップ・復元可能。

## 🛠️ 技術スタック (Tech Stack)

* **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.x)
* **Language**: Dart
* **State Management**: [Riverpod](https://riverpod.dev/) (Hooks Riverpod)
* **Database**: [sqflite](https://pub.dev/packages/sqflite) / [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (Desktop support)
* **Code Generation**: [Freezed](https://pub.dev/packages/freezed), [JSON Serializable](https://pub.dev/packages/json_serializable)
* **Utility**: CSV, File Picker, Intl, Path Provider, UUID

## 🚀 セットアップ (Setup)

### 必須要件
* Flutter SDK
* Dart SDK
* Desktop利用の場合: 各プラットフォームのビルドツール (Visual Studio for Windows, Xcode for macOS, etc.)

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone [repository_url]
   cd dodge_manager_pro