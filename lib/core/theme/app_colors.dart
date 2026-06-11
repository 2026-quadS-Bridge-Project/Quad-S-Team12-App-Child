import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color gray900 = Color(0xFF171818);
  static const Color gray800 = Color(0xFF2F3032);
  static const Color gray700 = Color(0xFF47484B);
  static const Color gray600 = Color(0xFF5F6165);
  static const Color gray500 = Color(0xFF777A7F);
  static const Color gray400 = Color(0xFF91969E);
  static const Color gray300 = Color(0xFFA7ACB2);
  static const Color gray200 = Color(0xFFD5D8DE);
  static const Color gray100 = Color(0xFFF5F7FA);
  static const Color gray050 = Color(0xFFFAFBFC);

  static const Color primary = Color(0xFF3A99F8);
  static const Color positive = Color(0xFF00BF40);
  static const Color cautionary = Color(0xFFFF9200);
  static const Color destructive = Color(0xFFFF4242);

  static const Color labelStrong = black;
  static const Color labelNormal = Color(0xFF171719);
  static const Color lineNormalNeutral = Color(0x2970737C);

  static const Color background = gray100;
  static const Color surface = white;
  static const Color surfaceMuted = gray100;
  static const Color border = gray200;
  static const Color textPrimary = labelStrong;
  static const Color textSecondary = gray600;

  // region: Cross-screen validated tokens (Figma — see docs/figma-specs/00-CATALOG.md §1.1)

  // Near-black ink, distinct from gray900. Input values, topbar titles, section headers.
  static const Color inkBlack = Color(0xFF050505);

  // Gray scale extension — sits between gray100 and gray200.
  // Separator bands, donut base ring, completed-mission card bg.
  static const Color gray150 = Color(0xFFEDEEF1);

  // Primary tonal ramp (light end) — speech bubbles, info backgrounds, button :active.
  static const Color primarySoft = Color(0xFFE1F0FE);
  static const Color primaryLight = Color(0xFFEBF5FE);
  static const Color primarySubtle = Color(0xFFC2DFFD);

  // Destructive tonal extensions — chip bg + soft error border.
  static const Color destructiveSubtle = Color(0xFFFFD3D3);
  static const Color destructiveBorderSoft = Color(0xFFFF7878);

  // Bonus time donut + label (previously hardcoded in child_home).
  static const Color bonusAmber = Color(0xFFFFBF00);

  // Softer variant of bonusAmber — child_home completed-ring color.
  static const Color bonusAmberSoft = Color(0xFFFFD980);

  // Modal scrim for dialogs and bottom sheets — rgba(68,68,68,0.60).
  static const Color scrim = Color(0x99444444);

  // Brand wordmark color — lighter blue tint used ONLY for the "Bridge" logo
  // on the intro screen (Figma 662-8356). Distinct from `primary` (#3A99F8);
  // do not reuse for CTAs, links, or icons.
  static const Color brandWordmark = Color(0xFF6DB5FF);

  // region: Declared-only tokens (reserved — present in Figma, not yet used in app)

  // Figma variable — highlight/darkest.
  static const Color highlightDarkest = Color(0xFF006FFD);
  // Reserved for mission reward badge (Figma style library).
  static const Color secondaryYellow = Color(0xFFFFCC33);
  // Figma variable only — line/purple style.
  static const Color lineStylePurple = Color(0xFF655B96);

  // region: Semantic aliases

  static const Color inputText = inkBlack;
  static const Color dialogScrim = scrim;
  static const Color cardSeparator = gray150;
}
