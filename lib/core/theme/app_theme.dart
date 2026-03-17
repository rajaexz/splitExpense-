import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.lightBackground,
      // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.primaryGreenDark,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        error: AppColors.error,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textBlack,
        onBackground: AppColors.textBlack,
        onError: AppColors.textWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textWhite,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize18,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        color: AppColors.lightCard,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.padding16,
          vertical: AppDimensions.padding16,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.textBlack,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
          textStyle: const TextStyle(
            // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
            fontSize: AppFonts.fontSize16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: const TextStyle(
            // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
            fontSize: AppFonts.fontSize14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize32,
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
        displayMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize28,
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
        displaySmall: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize24,
          fontWeight: FontWeight.w600,
          color: AppColors.textBlack,
        ),
        headlineMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize20,
          fontWeight: FontWeight.w600,
          color: AppColors.textBlack,
        ),
        titleLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize18,
          fontWeight: FontWeight.w600,
          color: AppColors.textBlack,
        ),
        titleMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize16,
          fontWeight: FontWeight.w500,
          color: AppColors.textBlack,
        ),
        bodyLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize16,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
        bodyMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize14,
          fontWeight: FontWeight.normal,
          color: AppColors.textGrey,
        ),
        bodySmall: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize12,
          fontWeight: FontWeight.normal,
          color: AppColors.textGreyLight,
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor: AppColors.darkBackground,
      // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.primaryGreenLight,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.error,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textBlack,
        onSurface: AppColors.textWhite,
        onBackground: AppColors.textWhite,
        onError: AppColors.textWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textWhite,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize18,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        color: AppColors.darkCard,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.padding16,
          vertical: AppDimensions.padding16,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
          textStyle: const TextStyle(
            // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
            fontSize: AppFonts.fontSize16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: const TextStyle(
            // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
            fontSize: AppFonts.fontSize14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize32,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        displayMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize28,
          fontWeight: FontWeight.bold,
          color: AppColors.textWhite,
        ),
        displaySmall: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize24,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
        headlineMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize20,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
        titleLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize18,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
        titleMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize16,
          fontWeight: FontWeight.w500,
          color: AppColors.textWhite,
        ),
        bodyLarge: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize16,
          fontWeight: FontWeight.normal,
          color: AppColors.textWhite,
        ),
        bodyMedium: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize14,
          fontWeight: FontWeight.normal,
          color: AppColors.textGreyLight,
        ),
        bodySmall: TextStyle(
          // fontFamily: AppFonts.poppins, // Uncomment when Poppins fonts are added
          fontSize: AppFonts.fontSize12,
          fontWeight: FontWeight.normal,
          color: AppColors.textGrey,
        ),
      ),
    );
  }
}

