import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for「先吃掉那隻青蛙 × GTD」.
///
/// Extracted directly from the design spec. Treat these as the single source
/// of truth — do not hard-code colours or font sizes elsewhere.
class AppColors {
  AppColors._();

  /// 背景、卡片底色
  static const ivoryL = Color(0xFFFAF8F3);

  /// 次要背景、進度條底
  static const ivoryM = Color(0xFFF0ECE2);

  /// 分隔線、border
  static const ivoryD = Color(0xFFE1DACB);

  /// 主要文字、按鈕
  static const ink = Color(0xFF1A1916);

  /// 次要文字（56% opacity）
  static const inkSoft = Color(0x8F1A1916);

  /// 青蛙高亮、連勝數字、CTA 按鈕
  static const accent = Color(0xFFB5502E);

  /// 標籤、次要 label
  static const cloud = Color(0xFFA39D91);

  /// 輔助
  static const cloudL = Color(0xFFDAD4C7);

  /// 統計長條圖非今日的 bar 顏色（取自原型）
  static const chartBar = Color(0xFFC9C2B2);

  /// 頁面外圈背景（iOS 裝置外框）
  static const page = Color(0xFFEDEAE3);
}

/// Named text styles. Fonts:
/// - Fraunces (serif) → 大標題、青蛙任務文字、統計數字
/// - Inter / Noto Sans TC (sans) → 一般 body 文字
/// - Geist Mono (mono) → 所有大寫 label、tab label、連勝單位
/// - Caveat (手寫) → 空狀態與連勝提示
class AppText {
  AppText._();

  // ---- Fraunces (serif) ----

  /// 大標題 34px（今日 / 收集匣 / 統計 / 設定）
  static TextStyle title() => GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.05,
        letterSpacing: -0.03 * 34,
      );

  /// 青蛙任務文字 22px
  static TextStyle frog() => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.35,
        letterSpacing: -0.02 * 22,
      );

  /// 統計大數字 58px
  static TextStyle statHuge({Color color = AppColors.accent}) =>
      GoogleFonts.fraunces(
        fontSize: 58,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1,
        letterSpacing: -0.04 * 58,
      );

  /// 統計卡片數字 28px
  static TextStyle statMedium() => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        letterSpacing: -0.02 * 28,
      );

  /// 連勝 badge 數字 16px
  static TextStyle streakBadge() => GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.accent,
        letterSpacing: -0.02 * 16,
      );

  // ---- Inter / Noto Sans TC (sans) ----

  /// 一般 body 文字 15.5px
  static TextStyle body({Color color = AppColors.ink}) => GoogleFonts.inter(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// body 15px（inbox item、input）
  static TextStyle body15({Color color = AppColors.ink}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// 按鈕文字 14.5px
  static TextStyle button({Color color = AppColors.ivoryL}) =>
      GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// 小 pill 按鈕 11.5–12px
  static TextStyle pill({Color color = AppColors.inkSoft}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// 青蛙完成訊息 15px w600
  static TextStyle emphasis({Color color = AppColors.accent}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 卡片小標題 14px w600
  static TextStyle cardTitle() => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  // ---- Mono ----
  // NOTE: Geist Mono isn't hosted on Google Fonts. JetBrains Mono is the
  // closest modern geometric substitute. To match the design exactly, bundle
  // the Geist Mono .ttf under assets/fonts/ and swap this to a local TextStyle.

  /// 大寫 mono label 11px（頁首日期、PREFERENCES 等）
  static TextStyle mono({
    double size = 11,
    Color color = AppColors.inkSoft,
    double letterSpacing = 0.1,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing * size,
      );

  // ---- Caveat (手寫) ----

  /// 手寫提示 20–22px
  static TextStyle caveat({double size = 22}) => GoogleFonts.caveat(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      );
}

/// Animation constants for the `fadeUp` entrance and staggered lists.
class AppMotion {
  AppMotion._();

  static const Duration fadeUpDuration = Duration(milliseconds: 500);

  /// cubic-bezier(0.2, 0.7, 0.2, 1.0)
  static const Cubic fadeUpCurve = Cubic(0.2, 0.7, 0.2, 1.0);

  /// stagger delay per list item
  static const Duration staggerStep = Duration(milliseconds: 55);
}

/// Radii used throughout the app.
class AppRadius {
  AppRadius._();

  static const double frogCard = 20;
  static const double statCard = 22;
  static const double smallCard = 20;
  static const double settingsCard = 16;
  static const double input = 14;
  static const double pill = 999;
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ivoryL,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.ink,
      surface: AppColors.ivoryL,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
