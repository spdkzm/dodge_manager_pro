// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // メインカラー
  static const Color primary = Colors.indigo;

  // 記録・分析用カラー
  static const Color success = Colors.red;
  static const Color failure = Colors.blue;
  static const Color defaultAction = Colors.green; // 単体アクション用

  // テキストカラー
  static const Color textMain = Colors.black87;
  static const Color textSub = Colors.grey;

  // 背景・枠線など
  static const Color backgroundLight = Color(0xFFF5F5F5); // Colors.grey[100]近似
  static const Color border = Colors.black12;
}

class AppTextStyles {
  // ダイアログ等のタイトル
  static const TextStyle titleLarge = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.textMain,
  );

  // カラムのヘッダーなど
  static const TextStyle headerMedium = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: AppColors.textMain,
  );

  // サブタイトル・ラベル
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSub,
  );

  // 強調ラベル (成功の内訳、など)
  static const TextStyle labelBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );

  // 数値データ
  static const TextStyle statValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  // パーセンテージ表示
  static const TextStyle percentageLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}