import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdaptiveThemeService {
  static final AdaptiveThemeService _instance = AdaptiveThemeService._internal();
  factory AdaptiveThemeService() => _instance;
  AdaptiveThemeService._internal();

  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Blue
        brightness: Brightness.light,
        // Enhanced light color scheme
        surface: const Color(0xFFF8F9FF), // Very light blue tint
        surfaceVariant: const Color(0xFFF0F4FF), // Light blue tint
        outline: const Color(0xFFE1E8FF), // Light blue outline
        outlineVariant: const Color(0xFFD4E2FF), // Very light blue outline
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // Typography with enhanced colors
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Color(0xFF1E293B), // Slate-800
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Color(0xFF1E293B),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF1E293B),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF334155), // Slate-700
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFF334155),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFF334155),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFF475569), // Slate-600
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF475569),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF475569),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Color(0xFF475569),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Color(0xFF64748B), // Slate-500
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(0xFF94A3B8), // Slate-400
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF475569),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFF64748B),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFF94A3B8),
        ),
      ),
      
      // Enhanced Scaffold with subtle gradient background
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      
      // Enhanced App Bar with subtle gradient
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F9FF),
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFFE1E8FF),
        scrolledUnderElevation: 1,
        // Add subtle border
        titleTextStyle: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Enhanced Card with better shadows and colors
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 3,
        shadowColor: const Color(0x1A1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // Add subtle border
        surfaceTintColor: const Color(0xFFF0F4FF),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      ),
      
      // Enhanced Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: const Color(0x1A1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          // Add subtle gradient effect
          surfaceTintColor: const Color(0xFF1976D2),
        ),
      ),
      
      // Enhanced Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      
      // Enhanced Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E8FF), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E8FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF2196F3),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        prefixIconColor: const Color(0xFF64748B),
        suffixIconColor: const Color(0xFF64748B),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Enhanced Drawer with subtle background
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFFF8F9FF),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
      ),
      
      // Enhanced List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: Color(0xFFFFFFFF),
        selectedTileColor: Color(0xFFE1E8FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      
      // Enhanced Divider with better color
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE1E8FF),
        thickness: 1,
        space: 1,
      ),
      
      // Enhanced Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF475569),
        size: 24,
      ),
      
      // Enhanced Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Enhanced Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F4FF),
        selectedColor: const Color(0xFFE1E8FF),
        disabledColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 1,
        shadowColor: const Color(0x1A1E293B),
      ),
    );
  }

  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Blue
        brightness: Brightness.dark,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Color(0xFFFFFFFF),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Color(0xFFFFFFFF),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFFFFFFFF),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFFFFFFFF),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFFFFFFFF),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFFFFFFFF),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFFFFFFFF),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFFFFFFFF),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFFFFFFFF),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Color(0xFFFFFFFF),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Color(0xFFFFFFFF),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(0xFFB0B0B0),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFFFFFFFF),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFFB0B0B0),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFFB0B0B0),
        ),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Card
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        shadowColor: Color(0x4D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),
                 hintStyle: const TextStyle(
           color: Color(0xFF808080),
           fontSize: 16,
           fontWeight: FontWeight.w400,
           letterSpacing: 0.5,
         ),
         labelStyle: const TextStyle(
           color: Color(0xFFB0B0B0),
           fontSize: 16,
           fontWeight: FontWeight.w500,
           letterSpacing: 0.1,
         ),
         floatingLabelStyle: const TextStyle(
           color: Color(0xFF2196F3),
           fontSize: 16,
           fontWeight: FontWeight.w600,
           letterSpacing: 0.15,
         ),
        prefixIconColor: const Color(0xFF808080),
        suffixIconColor: const Color(0xFF808080),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
      ),
      
      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
      ),
    );
  }

  // Initialize adaptive theme
  static Future<void> initialize() async {
    await AdaptiveTheme.of(GlobalKey<NavigatorState>().currentContext!);
  }

  // Get current theme mode
  static AdaptiveThemeMode? getCurrentMode(BuildContext context) {
    return AdaptiveTheme.of(context).mode;
  }

  // Toggle theme
  static void toggleTheme(BuildContext context) {
    try {
      final currentMode = AdaptiveTheme.of(context).mode;
      AdaptiveThemeMode newMode;
      
      switch (currentMode) {
        case AdaptiveThemeMode.light:
          newMode = AdaptiveThemeMode.dark;
          break;
        case AdaptiveThemeMode.dark:
          newMode = AdaptiveThemeMode.light;
          break;
        case AdaptiveThemeMode.system:
          // If system mode, switch to light mode
          newMode = AdaptiveThemeMode.light;
          break;
        default:
          newMode = AdaptiveThemeMode.light;
      }
      
      AdaptiveTheme.of(context).setThemeMode(newMode);
    } catch (e) {
      print('Error toggling theme: $e');
    }
  }

  // Set specific theme mode
  static void setThemeMode(BuildContext context, AdaptiveThemeMode mode) {
    AdaptiveTheme.of(context).setThemeMode(mode);
  }

  // Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    try {
      final mode = AdaptiveTheme.of(context).mode;
      return mode == AdaptiveThemeMode.dark || 
             (mode == AdaptiveThemeMode.system && 
              MediaQuery.of(context).platformBrightness == Brightness.dark);
    } catch (e) {
      // Fallback to system brightness if adaptive theme is not available
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}
