import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1); // Índigo
  static const Color secondary = Color(0xFF8B5CF6); // Violeta
  static const Color success = Color(0xFF10B981); // Verde
  static const Color warning = Color(0xFFF59E0B); // Amarelo
  static const Color danger = Color(0xFFEF4444); // Vermelho
  
  // Light Mode
  static const Color lightBg = Color(0xFFF9FAFB);
  static const Color lightCardBg = Colors.white;
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightSubText = Color(0xFF6B7280);
  
  // Dark Mode
  static const Color darkBg = Color(0xFF111827);
  static const Color darkCardBg = Color(0xFF1F2937);
  static const Color darkText = Color(0xFFF9FAFB);
  static const Color darkSubText = Color(0xFFD1D5DB);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}