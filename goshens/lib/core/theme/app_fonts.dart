import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers that avoid runtime CDN fetches on web.
class AppFonts {
  static TextStyle outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    if (kIsWeb) {
      return TextStyle(
        fontFamily: 'Segoe UI',
        fontFamilyFallback: const ['Roboto', 'Helvetica', 'Arial', 'sans-serif'],
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );
    }

    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }

  static TextTheme textTheme() {
    if (kIsWeb) {
      return ThemeData.light().textTheme.apply(
            fontFamily: 'Segoe UI',
            fontFamilyFallback: const ['Roboto', 'Helvetica', 'Arial', 'sans-serif'],
          );
    }

    return GoogleFonts.interTextTheme();
  }
}
