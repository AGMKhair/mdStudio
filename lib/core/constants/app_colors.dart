// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

/// ResTech Brand Colors
/// Primary: Orange (#F27F21) — from logo
/// Secondary: Navy (#0B1D37) — from logo
class AppColors {
  AppColors._();

  // --- Brand ---
  static const Color primary = Color(0xFFF27F21); // Orange
  static const Color primaryDark = Color(0xFFC6661A);
  static const Color primaryLight = Color(0xFFFFB37B);

  static const Color secondary = Color(0xFF0B1D37); // Navy
  static const Color secondaryDark = Color(0xFF051020);
  static const Color secondaryLight = Color(0xFF1E3A5F);

  // --- Neutrals ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0D0D0D);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // --- Semantic ---
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // --- Background ---
  static const Color scaffoldBg = Color(0xFFF8F8F8);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkScaffoldBg = Color(0xFF0B1D37); // Navy Background
  static const Color darkCardBg = Color(0xFF142742);

  // --- Menu Colors ---
  static const Color embedAirlineColor = Color(0xFFF27F21); // Orange
  static const Color modifyAirlineColor = Color(0xFF0B1D37); // Navy
  static const Color embedFlightColor = Color(0xFFE67E22); // Dark Orange
  static const Color modifyFlightColor = Color(0xFF1B3A57); // Muted Navy
  static const Color createBookingColor = Color(0xFFF39C12); // Amber
  static const Color createTicketColor = Color(0xFF2C3E50); // Dark Slate

  static const Color greenColor = Color(0xFF22C55E);
  static const Color redColor = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
}
