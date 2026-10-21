import 'package:flutter/material.dart';

/// Centralized color palette tailored for athletic dark-mode modern fitness aesthetic
class AppColors {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF0F172A); // Deep slate midnight
  static const Color surface = Color(0xFF1E293B); // Elevated card surface
  static const Color surfaceLight = Color(0xFF334155); // Secondary surface
  static const Color surfaceBorder = Color(0xFF334155); // Subtle card outline

  // Primary Brand Colors (Vibrant Green / Emerald)
  static const Color primary = Color(0xFF10B981); // Athletic emerald green
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryGlow = Color(0x3310B981);

  // Accent & Energy (Neon Coral / Orange)
  static const Color accent = Color(0xFFF97316); // High energy orange
  static const Color accentLight = Color(0xFFFB923C);
  static const Color accentGlow = Color(0x33F97316);

  // Secondary Accents
  static const Color cyan = Color(0xFF06B6D4); // For pace / distance metrics
  static const Color purple = Color(0xFF8B5CF6); // For workouts / strength
  static const Color pink = Color(0xFFEC4899); // For HIIT / calories

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted grey
  static const Color textMuted = Color(0xFF64748B); // Low emphasis

  // Status & Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF172033)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
