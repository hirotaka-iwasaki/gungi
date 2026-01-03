import 'package:flutter/material.dart';

/// アプリのテーマ設定
/// 原作（HUNTER×HUNTER）の軍儀をイメージした和風デザイン
class AppTheme {
  // =========================================================================
  // 盤面の色（木目調）
  // =========================================================================
  static const Color boardColor = Color(0xFFD4A574); // 榧（かや）の木色
  static const Color boardColorLight = Color(0xFFE8C89E); // 明るい木目
  static const Color boardColorDark = Color(0xFFC49A6C); // 暗い木目
  static const Color boardLineColor = Color(0xFF5D3A1A); // 漆黒の線
  static const Color boardBorderColor = Color(0xFF3D2314); // 外枠

  // =========================================================================
  // 駒の色
  // =========================================================================
  // 先手（白）：象牙色をイメージ
  static const Color whitePieceColor = Color(0xFFFFF8DC); // 象牙色
  static const Color whitePieceBorderColor = Color(0xFFB8860B); // 金縁
  static const Color whitePieceTextColor = Color(0xFF1A0A00); // 墨色

  // 後手（黒）：漆黒をイメージ
  static const Color blackPieceColor = Color(0xFF1A1A1A); // 漆黒
  static const Color blackPieceBorderColor = Color(0xFFB8860B); // 金縁
  static const Color blackPieceTextColor = Color(0xFFFFD700); // 金文字

  // =========================================================================
  // ハイライト色
  // =========================================================================
  static const Color selectedColor = Color(0xAA4CAF50); // 選択中（緑）
  static const Color legalMoveColor = Color(0x6600BFFF); // 移動可能（青）
  static const Color lastMoveColor = Color(0x66FFD700); // 最後の手（金）
  static const Color captureColor = Color(0x88FF4500); // 捕獲可能（赤）
  static const Color stackColor = Color(0x6600FF7F); // ツケ可能（緑）

  // =========================================================================
  // 背景・パネル色
  // =========================================================================
  static const Color backgroundColor = Color(0xFF1A1410); // 漆黒の背景
  static const Color panelColor = Color(0xFF2D241C); // 木目調パネル
  static const Color accentColor = Color(0xFFB8860B); // 金色アクセント

  // =========================================================================
  // 星（目印）の色
  // =========================================================================
  static const Color starColor = Color(0xFF3D2314); // 盤面の星

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: panelColor,
        foregroundColor: Color(0xFFFFD700),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: panelColor,
        titleTextStyle: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
