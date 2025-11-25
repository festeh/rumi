import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/asr_settings_provider.dart';
import '../theme/app_themes.dart';
import '../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(Spacing.lg),
        children: [
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: Spacing.md),
          _buildThemeSection(context),
          SizedBox(height: Spacing.xxl),
          Text(
            'Transcription',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: Spacing.md),
          _buildLanguageSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...AppTheme.values.map((theme) => _buildThemeCard(
              context,
              theme,
              isSelected: themeProvider.currentTheme == theme,
              onTap: () => themeProvider.setTheme(theme),
            )),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ASRSettingsProvider>(
      builder: (context, asrSettings, child) {
        return Container(
          padding: EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: Borders.thin,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: Spacing.sm),
              DropdownButtonFormField<ASRLanguage>(
                value: asrSettings.language,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                ),
                items: ASRLanguage.values.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    asrSettings.setLanguage(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppTheme appTheme, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final previewColors = appTheme.previewColors;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: Container(
            padding: EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? Borders.medium : Borders.thin,
              ),
            ),
            child: Row(
              children: [
                // Color preview squares
                Row(
                  children: previewColors.map((color) {
                    return Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.only(right: Spacing.xs),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: Borders.thin,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(width: Spacing.md),
                // Theme name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appTheme.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        appTheme.isDark ? 'Dark' : 'Light',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Checkmark for selected
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: IconSizes.lg,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
