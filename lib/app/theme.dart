import 'package:flutter/material.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      surface: Colors.black,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF141414),
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF1A1A1A),
      textStyle: TextStyle(color: Colors.white),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF1A1A1A)),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF141414),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
