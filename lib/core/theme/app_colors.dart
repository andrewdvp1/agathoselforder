import 'package:flutter/material.dart';

/// Color Tokens — Glassmorphic POS & QRIS Design System (v1.0)
class AppColors {
  AppColors._();

  // Palet Warna Inti
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color secondary = Color(0xFF10B981); // Emerald Green
  static const Color tertiary = Color(0xFFF59E0B); // Vivid Amber
  static const Color neutral = Color(0xFF0F172A); // Deep Navy Slate
  static const Color error = Color(0xFFEF4444); // Coral Red

  // Canvas & Surface Tokens
  static const Color bgCanvasDeep = Color(0xFF0B1120);
  static const Color bgCanvas = Color(0xFF0F172A);
  static const Color surfaceBase = Color(0xFF1E293B);
  static const Color surfaceGlassBase = Color(0x8C1E293B); // rgba(30, 41, 59, 0.55)
  static const Color surfaceGlassElevated = Color(0xB81E293B); // rgba(30, 41, 59, 0.72)
  static const Color surfaceInput = Color(0x8C0F172A); // rgba(15, 23, 42, 0.55)

  // Glass Borders
  static const Color borderGlassSubtle = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.10)
  static const Color borderGlassInput = Color(0x24FFFFFF); // rgba(255, 255, 255, 0.14)
  static const Color borderGlassMedium = Color(0x26FFFFFF); // rgba(255, 255, 255, 0.15)
  static const Color borderGlassModal = Color(0x33FFFFFF); // rgba(255, 255, 255, 0.20)
  static const Color borderGlassHighlight = Color(0x38FFFFFF); // rgba(255, 255, 255, 0.22)
  static const Color borderGlassHover = Color(0x40FFFFFF); // rgba(255, 255, 255, 0.25)

  // Tonal Fills & On-Tonal
  static const Color primaryTonal = Color(0xFFC7D2FE);
  static const Color primaryTonalAlt = Color(0xFFA5B4FC);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryOnTonal = Color(0xFF1E1B4B);
  static const Color primaryIconDark = Color(0xFF312E81);

  static const Color secondaryTonal = Color(0xFF6EE7B7);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryOnTonal = Color(0xFF064E3B);

  static const Color tertiaryTonal = Color(0xFFFCD34D);
  static const Color tertiaryLight = Color(0xFFFBBF24);
  static const Color tertiaryDark = Color(0xFFD97706);
  static const Color tertiaryOnTonal = Color(0xFF78350F);

  static const Color errorTonal = Color(0xFFFCA5A5);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorOnTonal = Color(0xFF7F1D1D);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInactiveIcon = Color(0xFFCBD5E1);
  static const Color invertedSurface = Color(0xFFE2E8F0);

  // Status Badge Backgrounds (Translucent)
  static const Color statusPendingBg = Color(0x29F59E0B); // 16%
  static const Color statusProcessingBg = Color(0x2E6366F1); // 18%
  static const Color statusPaidBg = Color(0x2E10B981); // 18%
  static const Color statusRejectedBg = Color(0x2EEF4444); // 18%
  static const Color statusExpiredBg = Color(0x2994A3B8); // 16%

  // Ambient Radial Orb Colors
  static const Color orbPrimary = Color(0x2E6366F1); // 18%
  static const Color orbSecondary = Color(0x1F10B981); // 12%
  static const Color orbTertiary = Color(0x14F59E0B); // 8%
}
