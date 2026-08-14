import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        scaffold: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        appBarForeground: AppColors.primaryDark,
        navUnselected: AppColors.textSecondary,
        inputFill: AppColors.surface,
        chipBackground: AppColors.surfaceVariant,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        primary: const Color(0xFF2DD4BF),
        secondary: const Color(0xFF5EEAD4),
        tertiary: const Color(0xFF86EFAC),
        surface: const Color(0xFF123044),
        scaffold: const Color(0xFF06141F),
        error: const Color(0xFFFF8A96),
        onPrimary: const Color(0xFF042F2E),
        onSurface: const Color(0xFFF1FFFB),
        onSurfaceVariant: const Color(0xFFB7E4DC),
        outline: const Color(0xFF2A5A5A),
        appBarForeground: const Color(0xFFF1FFFB),
        navUnselected: const Color(0xFF7FCEC4),
        inputFill: const Color(0xFF173A4A),
        chipBackground: const Color(0xFF1A4254),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Color surface,
    required Color scaffold,
    required Color error,
    required Color onPrimary,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color appBarForeground,
    required Color navUnselected,
    required Color inputFill,
    required Color chipBackground,
  }) {
    final baseTextTheme = AppFonts.textTheme();
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: brightness == Brightness.dark ? const Color(0xFF042F2E) : Colors.white,
      tertiary: tertiary,
      onTertiary: brightness == Brightness.dark ? const Color(0xFF052E16) : Colors.white,
      error: error,
      onError: brightness == Brightness.dark ? const Color(0xFF3B0A10) : Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline,
      inverseSurface: brightness == Brightness.dark ? const Color(0xFFE8F4FB) : AppColors.primaryDark,
      onInverseSurface: brightness == Brightness.dark ? const Color(0xFF06141F) : Colors.white,
      inversePrimary: brightness == Brightness.dark ? AppColors.secondary : const Color(0xFF2DD4BF),
    );

    final textTheme = baseTextTheme.copyWith(
      displayLarge: AppFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: -0.5),
      displayMedium: AppFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface, letterSpacing: -0.5),
      displaySmall: AppFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
      headlineSmall: AppFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface),
      titleLarge: AppFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
      titleMedium: AppFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      titleSmall: AppFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: onSurface, fontSize: 16, height: 1.5),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: onSurfaceVariant, fontSize: 14, height: 1.4),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: onSurfaceVariant, fontSize: 12, height: 1.4),
      labelLarge: AppFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: AppFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      cardColor: surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      dividerColor: outline,
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: IconThemeData(color: appBarForeground),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: appBarForeground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        titleTextStyle: AppFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: appBarForeground),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
        subtitleTextStyle: TextStyle(color: onSurfaceVariant, fontSize: 13, height: 1.35),
        titleTextStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        dividerColor: outline,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        contentTextStyle: TextStyle(color: onSurfaceVariant, fontSize: 14, height: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        textStyle: TextStyle(color: onSurface),
        iconColor: onSurface,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: outline)),
        textStyle: TextStyle(color: onSurface, fontSize: 12),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        labelStyle: TextStyle(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: error, width: 2)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: primary.withValues(alpha: 0.22),
        disabledColor: chipBackground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: outline)),
        labelStyle: AppFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface),
        secondaryLabelStyle: AppFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: onPrimary),
        iconTheme: IconThemeData(color: onSurface, size: 18),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.22),
        elevation: 0,
        height: 70,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : navUnselected);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
            color: selected ? onSurface : navUnselected,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1A4254) : AppColors.primaryDark,
        contentTextStyle: TextStyle(color: brightness == Brightness.dark ? const Color(0xFFF1FFFB) : Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary.withValues(alpha: 0.4) : outline),
      ),
    );
  }
}
