import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get strict {

    const black = Color(0xFF000000);
    const darkGrey = Color(0xFF101010);
    const red = Color(0xFFFF0000);
    const white = Color(0xFFFFFFFF);

    final baseText = GoogleFonts.robotoFlexTextTheme();

    final dotoFont = GoogleFonts.getFont('Doto'); 

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: red,
      colorScheme: const ColorScheme.dark(
        primary: red,
        onPrimary: white,
        surface: black,
        onSurface: white,
        background: black,
        onBackground: white,
        error: red,
        onError: white,
        outline: white,
        secondary: red,
      ),
      textTheme: baseText.copyWith(
        displayLarge: dotoFont.copyWith(color: white, fontWeight: FontWeight.bold),
        displayMedium: dotoFont.copyWith(color: white, fontWeight: FontWeight.bold),
        displaySmall: dotoFont.copyWith(color: white, fontWeight: FontWeight.bold),
        headlineLarge: dotoFont.copyWith(color: white, fontWeight: FontWeight.bold),
        headlineMedium: dotoFont.copyWith(color: white, fontWeight: FontWeight.bold),
        bodyLarge: baseText.bodyLarge?.copyWith(color: white),
        bodyMedium: baseText.bodyMedium?.copyWith(color: white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkGrey,
        labelStyle: TextStyle(color: Colors.white),
        hintStyle: TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.zero, 
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: red, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: red),
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          foregroundColor: white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), 
          textStyle: GoogleFonts.robotoFlex(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkGrey,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.white12), borderRadius: BorderRadius.zero),
        elevation: 0,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
