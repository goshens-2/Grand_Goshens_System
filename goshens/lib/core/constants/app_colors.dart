import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Secondary
  static const Color primary = Color(0xFF00B4D8); // Clean dental cyan/blue
  static const Color primaryLight = Color(0xFF90E0EF); // Soft sky cyan
  static const Color primaryDark = Color(0xFF03045E); // Deep blue for text and icons
  static const Color secondary = Color(0xFF0077B6); // Deep cyan accent
  
  // Brand Accents
  static const Color accent = Color(0xFF2DC653); // Fresh green
  static const Color accentLight = Color(0xFFD8F3DC); // Soft green tint
  
  // Neutrals & Surfaces
  static const Color background = Color(0xFFF3F8FB); // Soft clinical mist
  static const Color surface = Colors.white; // Pure white
  static const Color surfaceVariant = Color(0xFFEDF4F8); // Light cyan-grey surface
  static const Color cardShadow = Color(0x1403045E); // Soft navy shadow
  static const Color border = Color(0xFFD7E6EE); // Subtle slate-cyan border
  static const Color gold = Color(0xFFC9A227); // Quiet luxury accent
  
  // Status Colors
  static const Color error = Color(0xFFE63946); // Muted red
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFB703); // Warm amber
  static const Color warningBackground = Color(0xFFFFF3CD);
  static const Color success = Color(0xFF2DC653);
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF00B4D8);
  static const Color infoBackground = Color(0xFFE0F7FA);
  
  // Typography Colors
  static const Color textPrimary = Color(0xFF03045E); // Deep navy primary text
  static const Color textSecondary = Color(0xFF4A5568); // Muted slate secondary text
  static const Color textMuted = Color(0xFFA0AEC0); // Light muted text

  /// High-contrast body/title ink: navy in light, ice-mint in dark.
  static Color ink(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF1FFFB)
        : primaryDark;
  }

  /// Secondary copy that stays readable on both scaffolds.
  static Color muted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB7E4DC)
        : textSecondary;
  }

  /// Quiet labels and chevrons.
  static Color faint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7FCEC4)
        : textMuted;
  }

  static Color card(BuildContext context) => Theme.of(context).colorScheme.surface;

  static Color hairline(BuildContext context) => Theme.of(context).colorScheme.outline;

  /// Strong actions: navy in light, mint teal in dark.
  static Color cta(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2DD4BF)
        : primaryDark;
  }

  static Color onCta(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF042F2E)
        : Colors.white;
  }

  static Color highlight(BuildContext context) => Theme.of(context).colorScheme.secondary;

  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF03045E), Color(0xFF0077B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2DC653), Color(0xFF25A244)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
