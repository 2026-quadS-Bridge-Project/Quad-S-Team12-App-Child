import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const double mobileFrameWidth = 375;
  static const double mobileCanvasHeight = 812;
  static const double mobileHorizontalPadding = 24;
  static const double mobileContentWidth = 327;

  static const double pageHorizontal = 24;
  static const double pageTop = 28;
  static const double sectionGap = 32;
  static const double itemGap = 16;
  static const double smallGap = 8;
  static const double mediumGap = 12;
  static const double photoGap = 12; // from 11-mission.md (사진 그리드, itemGap과 별개)

  // Radii
  static const double cardRadius = 28;
  static const double cardRadiusSmall =
      16; // from 02-child-home.md, 06-notifications.md, 08b-time-v1-daily.md, 11-mission.md
  static const double dialogRadius =
      12; // from 05-delete.md, 06-notifications.md
  /// Small surface / input field / tile corner radius. 12px. Distinct from
  /// [dialogRadius] (also 12 but reserved for modal dialogs).
  static const double fieldRadius = 12;
  static const double buttonRadius =
      8; // from 00-CATALOG.md §1.4 (대부분 CTA; theme의 16과 별개)
  static const double bottomSheetTopRadius =
      24; // from 08a-time-v1-entry-weekly.md
  static const double errorBannerRadius =
      8; // from 08c-time-v1-errors-done.md, 09-time-v2.md (over/under banner)

  static const double cardPadding = 24;

  // Component sizing
  static const double bottomSheetHeight =
      397.0; // from 08a-time-v1-entry-weekly.md (49% of 812)
  static const double topBarHeight =
      52; // from 00-CATALOG.md §2.1 (CmpTopBar 표준)

  // Shadows — from 02-child-home.md §9 (Deltas, time-card shadow).
  // rgba(217,217,217,0.5) → time card / surface elevation.
  static const Color cardShadowColor = Color(0x80D9D9D9);
}
