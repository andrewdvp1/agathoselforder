import 'package:flutter/material.dart';

/// Color Tokens — Terracotta & Slate POS Design System
class AppColors {
  AppColors._();

  // Structural Command Deck (Slate Blue)
  static const Color slateHeader = Color(0xFF334E5E);
  static const Color slateDark = Color(0xFF1B3746);
  static const Color slateSidebar = Color(0xFF2B4352);
  static const Color slateSidebarFooter = Color(0xFF223642);
  static const Color onSlate = Color(0xFFFFFFFF);
  static const Color onSlateMuted = Color(0xFFCBD8E0);

  // Action CTAs & Ignition Accents
  static const Color ctaDark = Color(0xFF1F2933);
  static const Color ctaDarkHover = Color(0xFF2D3A46);
  static const Color accentTerracotta = Color(0xFFE85D3F);
  static const Color accentHover = Color(0xFFD14D30);
  static const Color accentSoft = Color(0xFFFDECE8);

  // Surfaces & Canvas
  static const Color bgCanvas = Color(0xFFF7F8FA);
  static const Color bgCanvasDeep = Color(0xFFF1F4F7);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceBase = Color(0xFFFFFFFF);
  static const Color surfaceInput = Color(0xFFFFFFFF);
  static const Color surfacePillInactive = Color(0xFFEFF3F6);
  static const Color surfaceRowHover = Color(0xFFF8FAFC);

  // Borders
  static const Color borderSubtle = Color(0xFFEDF1F5);
  static const Color borderDefault = Color(0xFFE6EBF0);
  static const Color borderInput = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Typography
  static const Color textPrimary = Color(0xFF1E262E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInactiveIcon = Color(0xFF64748B);

  // Semantic Status (two-part matrix)
  static const Color semanticSuccess = Color(0xFF16A34A);
  static const Color semanticSuccessSoft = Color(0xFFDCFCE7);
  static const Color statusPaidBorder = Color(0xFFBBF7D0);

  static const Color semanticWarning = Color(0xFFD97706);
  static const Color statusPendingText = Color(0xFFB45309);
  static const Color semanticWarningSoft = Color(0xFFFEF3C7);
  static const Color statusPendingBorder = Color(0xFFFDE68A);

  static const Color statusProcessingText = Color(0xFF2B547E);
  static const Color statusProcessingSoft = Color(0xFFE6EFF6);
  static const Color statusProcessingBorder = Color(0xFFC5DAE9);

  static const Color semanticError = Color(0xFFDC2626);
  static const Color semanticErrorSoft = Color(0xFFFEE2E2);
  static const Color statusErrorBorder = Color(0xFFFCA5A5);

  static const Color statusExpiredBg = Color(0xFFEFF3F6);

  // Backward-compatible aliases for existing components & tests
  static const Color primary = slateHeader;
  static const Color secondary = semanticSuccess;
  static const Color tertiary = semanticWarning;
  static const Color neutral = ctaDark;
  static const Color error = semanticError;

  static const Color surfaceGlassBase = surfaceCard;
  static const Color surfaceGlassElevated = surfaceCard;

  static const Color borderGlassSubtle = borderSubtle;
  static const Color borderGlassInput = borderInput;
  static const Color borderGlassMedium = borderDefault;
  static const Color borderGlassModal = borderDefault;
  static const Color borderGlassHighlight = borderDefault;
  static const Color borderGlassHover = borderStrong;

  static const Color primaryTonal = statusProcessingSoft;
  static const Color primaryTonalAlt = accentTerracotta;
  static const Color primaryLight = statusProcessingText;
  static const Color primaryOnTonal = slateDark;
  static const Color primaryIconDark = slateHeader;

  static const Color secondaryTonal = semanticSuccessSoft;
  static const Color secondaryLight = semanticSuccess;
  static const Color secondaryOnTonal = Color(0xFF14532D);

  static const Color tertiaryTonal = semanticWarningSoft;
  static const Color tertiaryLight = statusPendingText;
  static const Color tertiaryDark = semanticWarning;
  static const Color tertiaryOnTonal = Color(0xFF78350F);

  static const Color errorTonal = semanticErrorSoft;
  static const Color errorLight = semanticError;
  static const Color errorOnTonal = Color(0xFF991B1B);

  static const Color invertedSurface = ctaDark;

  static const Color statusPendingBg = semanticWarningSoft;
  static const Color statusProcessingBg = statusProcessingSoft;
  static const Color statusPaidBg = semanticSuccessSoft;
  static const Color statusRejectedBg = semanticErrorSoft;
}
