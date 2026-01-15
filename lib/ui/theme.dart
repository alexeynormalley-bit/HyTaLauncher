import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get strict {

    const black = Color(0xFF000000);
    const darkGrey = Color(0xFF121212);
    const white = Color(0xFFFFFFFF);

    final baseText = GoogleFonts.robotoTextTheme();
    final headerFont = GoogleFonts.roboto(fontWeight: FontWeight.w900); // Strong style
    final monoFont = GoogleFonts.robotoMono();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: black,
      primaryColor: white,
      colorScheme: const ColorScheme.dark(
        primary: white,
        onPrimary: black,
        surface: black,
        onSurface: white,
        background: black,
        onBackground: white,
        error: white, // Minimalist error
        onError: black,
        outline: white,
        secondary: white,
      ),
      textTheme: baseText.copyWith(
        displayLarge: headerFont.copyWith(color: white),
        displayMedium: headerFont.copyWith(color: white),
        displaySmall: headerFont.copyWith(color: white),
        headlineLarge: headerFont.copyWith(color: white),
        headlineMedium: headerFont.copyWith(color: white),
        bodyLarge: baseText.bodyLarge?.copyWith(color: white),
        bodyMedium: baseText.bodyMedium?.copyWith(color: white),
        labelLarge: GoogleFonts.roboto(fontWeight: FontWeight.bold), // Button text
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkGrey,
        labelStyle: TextStyle(color: Colors.white54),
        hintStyle: TextStyle(color: Colors.white24),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(12)), 
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: white, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: white),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          side: const BorderSide(color: white, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))), 
          textStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(color: Colors.white54),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))),
          textStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkGrey,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white12), 
            borderRadius: BorderRadius.all(Radius.circular(24))
        ),
        elevation: 0,
        margin: EdgeInsets.all(8),
      ),
      visualDensity: VisualDensity.standard,
      dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
      iconTheme: const IconThemeData(color: white),
    );
  }
}
