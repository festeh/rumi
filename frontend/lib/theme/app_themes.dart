import 'package:flutter/material.dart';
import 'tokens.dart';

/// Available app themes.
enum AppTheme {
  catppuccinMocha,
  catppuccinLatte,
  nord,
  dracula,
  gruvboxDark,
}

/// Extension to get display name for themes.
extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.catppuccinMocha:
        return 'Catppuccin Mocha';
      case AppTheme.catppuccinLatte:
        return 'Catppuccin Latte';
      case AppTheme.nord:
        return 'Nord';
      case AppTheme.dracula:
        return 'Dracula';
      case AppTheme.gruvboxDark:
        return 'Gruvbox Dark';
    }
  }

  bool get isDark {
    switch (this) {
      case AppTheme.catppuccinLatte:
        return false;
      default:
        return true;
    }
  }

  /// Preview colors for theme selector.
  List<Color> get previewColors {
    switch (this) {
      case AppTheme.catppuccinMocha:
        return [
          const Color(0xFF1e1e2e),
          const Color(0xFF89b4fa),
          const Color(0xFFf5c2e7),
        ];
      case AppTheme.catppuccinLatte:
        return [
          const Color(0xFFeff1f5),
          const Color(0xFF1e66f5),
          const Color(0xFFea76cb),
        ];
      case AppTheme.nord:
        return [
          const Color(0xFF2e3440),
          const Color(0xFF88c0d0),
          const Color(0xFF81a1c1),
        ];
      case AppTheme.dracula:
        return [
          const Color(0xFF282a36),
          const Color(0xFFbd93f9),
          const Color(0xFFff79c6),
        ];
      case AppTheme.gruvboxDark:
        return [
          const Color(0xFF282828),
          const Color(0xFFfe8019),
          const Color(0xFFfabd2f),
        ];
    }
  }
}

/// Theme definitions for the app.
class AppThemes {
  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.catppuccinMocha:
        return _catppuccinMocha();
      case AppTheme.catppuccinLatte:
        return _catppuccinLatte();
      case AppTheme.nord:
        return _nord();
      case AppTheme.dracula:
        return _dracula();
      case AppTheme.gruvboxDark:
        return _gruvboxDark();
    }
  }

  static ThemeData _catppuccinMocha() {
    const base = Color(0xFF1e1e2e);
    const surface = Color(0xFF313244);
    const overlay = Color(0xFF45475a);
    const text = Color(0xFFcdd6f4);
    const subtext = Color(0xFFa6adc8);
    const accent = Color(0xFF89b4fa);
    const secondary = Color(0xFFf5c2e7);
    const error = Color(0xFFf38ba8);

    return _buildTheme(
      brightness: Brightness.dark,
      base: base,
      surface: surface,
      overlay: overlay,
      text: text,
      subtext: subtext,
      accent: accent,
      secondary: secondary,
      error: error,
    );
  }

  static ThemeData _catppuccinLatte() {
    const base = Color(0xFFeff1f5);
    const surface = Color(0xFFe6e9ef);
    const overlay = Color(0xFFccd0da);
    const text = Color(0xFF4c4f69);
    const subtext = Color(0xFF6c6f85);
    const accent = Color(0xFF1e66f5);
    const secondary = Color(0xFFea76cb);
    const error = Color(0xFFd20f39);

    return _buildTheme(
      brightness: Brightness.light,
      base: base,
      surface: surface,
      overlay: overlay,
      text: text,
      subtext: subtext,
      accent: accent,
      secondary: secondary,
      error: error,
    );
  }

  static ThemeData _nord() {
    const base = Color(0xFF2e3440);
    const surface = Color(0xFF3b4252);
    const overlay = Color(0xFF434c5e);
    const text = Color(0xFFeceff4);
    const subtext = Color(0xFFd8dee9);
    const accent = Color(0xFF88c0d0);
    const secondary = Color(0xFF81a1c1);
    const error = Color(0xFFbf616a);

    return _buildTheme(
      brightness: Brightness.dark,
      base: base,
      surface: surface,
      overlay: overlay,
      text: text,
      subtext: subtext,
      accent: accent,
      secondary: secondary,
      error: error,
    );
  }

  static ThemeData _dracula() {
    const base = Color(0xFF282a36);
    const surface = Color(0xFF44475a);
    const overlay = Color(0xFF6272a4);
    const text = Color(0xFFf8f8f2);
    const subtext = Color(0xFFbfbfbf);
    const accent = Color(0xFFbd93f9);
    const secondary = Color(0xFFff79c6);
    const error = Color(0xFFff5555);

    return _buildTheme(
      brightness: Brightness.dark,
      base: base,
      surface: surface,
      overlay: overlay,
      text: text,
      subtext: subtext,
      accent: accent,
      secondary: secondary,
      error: error,
    );
  }

  static ThemeData _gruvboxDark() {
    const base = Color(0xFF282828);
    const surface = Color(0xFF3c3836);
    const overlay = Color(0xFF504945);
    const text = Color(0xFFebdbb2);
    const subtext = Color(0xFFa89984);
    const accent = Color(0xFFfe8019);
    const secondary = Color(0xFFfabd2f);
    const error = Color(0xFFfb4934);

    return _buildTheme(
      brightness: Brightness.dark,
      base: base,
      surface: surface,
      overlay: overlay,
      text: text,
      subtext: subtext,
      accent: accent,
      secondary: secondary,
      error: error,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color base,
    required Color surface,
    required Color overlay,
    required Color text,
    required Color subtext,
    required Color accent,
    required Color secondary,
    required Color error,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: brightness == Brightness.dark ? base : Colors.white,
      primaryContainer: overlay,
      onPrimaryContainer: text,
      secondary: secondary,
      onSecondary: brightness == Brightness.dark ? base : Colors.white,
      secondaryContainer: overlay,
      onSecondaryContainer: text,
      surface: surface,
      onSurface: text,
      error: error,
      onError: Colors.white,
      outline: subtext.withOpacity(0.5),
      shadow: Colors.black.withOpacity(0.1),
      surfaceTint: accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: base,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(
            color: subtext.withOpacity(0.2),
            width: Borders.thin,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: brightness == Brightness.dark ? base : Colors.white,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: subtext.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: subtext.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: accent, width: Borders.medium),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: subtext.withOpacity(0.2),
        thickness: Borders.thin,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: TypeScale.xxxl,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: TypeScale.xxl,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontSize: TypeScale.xl,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: TypeScale.xl,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: TypeScale.lg,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleSmall: TextStyle(
          fontSize: TypeScale.base,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: TypeScale.base,
          color: text,
        ),
        bodyMedium: TextStyle(
          fontSize: TypeScale.sm,
          color: text,
        ),
        bodySmall: TextStyle(
          fontSize: TypeScale.xs,
          color: subtext,
        ),
        labelLarge: TextStyle(
          fontSize: TypeScale.sm,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        labelMedium: TextStyle(
          fontSize: TypeScale.xs,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        labelSmall: TextStyle(
          fontSize: TypeScale.xs,
          color: subtext,
        ),
      ),
    );
  }
}
