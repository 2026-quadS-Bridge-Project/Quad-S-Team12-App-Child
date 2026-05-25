import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Pretendard';

  static const TextStyle heading1SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.364,
    letterSpacing: -0.4656,
    color: AppColors.labelStrong,
  );

  static const TextStyle heading1Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.364,
    letterSpacing: -0.4656,
    color: AppColors.labelStrong,
  );

  static const TextStyle heading1Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.364,
    letterSpacing: -0.4656,
    color: AppColors.labelStrong,
  );

  static const TextStyle heading2Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.24,
    color: AppColors.labelStrong,
  );

  static const TextStyle heading2Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.24,
    color: AppColors.labelStrong,
  );

  static const TextStyle heading2Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: -0.24,
    color: AppColors.labelStrong,
  );

  static const TextStyle headlineSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.445,
    letterSpacing: -0.02,
    color: AppColors.labelStrong,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.445,
    letterSpacing: -0.02,
    color: AppColors.labelStrong,
  );

  static const TextStyle headlineRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.445,
    letterSpacing: -0.02,
    color: AppColors.labelStrong,
  );

  static const TextStyle bodySemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.0912,
    color: AppColors.labelStrong,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.0912,
    color: AppColors.labelStrong,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.0912,
    color: AppColors.labelStrong,
  );

  static const TextStyle labelSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.429,
    letterSpacing: 0.203,
    color: AppColors.labelStrong,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.429,
    letterSpacing: 0.203,
    color: AppColors.labelStrong,
  );

  static const TextStyle labelRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.429,
    letterSpacing: 0.203,
    color: AppColors.labelStrong,
  );

  static const TextStyle captionSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.334,
    letterSpacing: 0.3024,
    color: AppColors.labelStrong,
  );

  static const TextStyle captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.334,
    letterSpacing: 0.3024,
    color: AppColors.labelStrong,
  );

  static const TextStyle captionRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.334,
    letterSpacing: 0.3024,
    color: AppColors.labelStrong,
  );

  static const TextTheme theme = TextTheme(
    displayLarge: heading1SemiBold,
    displayMedium: heading1Medium,
    displaySmall: heading1Regular,
    headlineLarge: heading2Bold,
    headlineMedium: heading2Medium,
    headlineSmall: heading2Regular,
    titleLarge: headlineSemiBold,
    titleMedium: headlineMedium,
    titleSmall: headlineRegular,
    bodyLarge: bodyRegular,
    bodyMedium: bodyMedium,
    bodySmall: captionRegular,
    labelLarge: labelSemiBold,
    labelMedium: labelMedium,
    labelSmall: captionMedium,
  );
}
