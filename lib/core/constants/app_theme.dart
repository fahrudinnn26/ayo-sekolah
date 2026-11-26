import 'package:material_ui/material_ui.dart';

/// Konfigurasi tema Material Design 3 untuk aplikasi Ayo Sekolah.
///
/// Menggunakan palet warna biru-hijau edukatif yang bersih, tipografi yang
/// mudah dibaca, serta ukuran target sentuh (touch target) minimal 48dp untuk
/// kenyamanan aksesibilitas seluruh pengguna.
class AppTheme {
  AppTheme._();

  /// Ukuran target sentuh minimal sesuai standar aksesibilitas (48dp).
  static const double minTouchTargetSize = 48.0;

  // Palet Warna Utama (Biru-Hijau Edukatif)
  static const Color primaryBlue = Color(0xFF0B6E8F);
  static const Color primaryDark = Color(0xFF074F68);
  static const Color primaryContainer = Color(0xFFD6EEF5);

  static const Color secondaryGreen = Color(0xFF0F9D8A);
  static const Color secondaryDark = Color(0xFF0B6E60);
  static const Color secondaryContainer = Color(0xFFD2F4EE);

  static const Color tertiaryAccent = Color(0xFF1D4ED8);

  // Warna Permukaan & Netral
  static const Color surfaceBackground = Color(0xFFF5F9FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color borderColor = Color(0xFFCBD5E1);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Warna Semantik Status Zonasi & Simulasi PPDB
  static const Color statusAman = Color(0xFF15803D);
  static const Color statusAmanBackground = Color(0xFFDCFCE7);
  static const Color statusWaspada = Color(0xFFB45309);
  static const Color statusWaspadaBackground = Color(0xFFFEF3C7);
  static const Color statusBerisiko = Color(0xFFB91C1C);
  static const Color statusBerisikoBackground = Color(0xFFFEE2E2);
  static const Color statusInfo = Color(0xFF0369A1);
  static const Color statusInfoBackground = Color(0xFFE0F2FE);

  /// Tema terang (Light Theme) berbasis Material Design 3.
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primaryDark,
      secondary: secondaryGreen,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: secondaryDark,
      tertiary: tertiaryAccent,
      onTertiary: Colors.white,
      surface: surfaceBackground,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      error: statusBerisiko,
      onError: Colors.white,
      outline: borderColor,
      outlineVariant: dividerColor,
    );

    const TextTheme textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.2,
        color: textSecondary,
      ),
    );

    final OutlinedBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: primaryBlue, width: 1.25),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTargetSize, minTouchTargetSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryGreen,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusBerisiko, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusBerisiko, width: 1.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer,
        selectedColor: primaryBlue,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: minTouchTargetSize,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryBlue : textSecondary,
          );
        }),
      ),
    );
  }
}
