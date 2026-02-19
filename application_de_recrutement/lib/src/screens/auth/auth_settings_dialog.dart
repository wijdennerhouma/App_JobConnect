import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';

Future<void> showAuthSettingsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const AuthSettingsDialog(),
  );
}

class AuthSettingsDialog extends StatelessWidget {
  const AuthSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lang = settings.language;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent, // Custom background
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    lang.tr('language'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LANGUAGE SECTION
                  _buildSectionTitle(context, lang.tr('language'), Icons.language),
                  const SizedBox(height: 12),
                  ...AppLanguage.values.map((l) {
                    final isSelected = settings.language == l;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSelectionTile(
                        context, 
                        title: l.name, 
                        isSelected: isSelected,
                        onTap: () => context.read<AppSettings>().setLanguage(l),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // THEME SECTION
                  _buildSectionTitle(context, lang.tr('theme'), Icons.palette_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildThemeCard(context, AppThemeMode.system, Icons.smartphone, lang)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildThemeCard(context, AppThemeMode.light, Icons.light_mode, lang)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildThemeCard(context, AppThemeMode.dark, Icons.dark_mode, lang)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionTile(BuildContext context, {
    required String title, 
    required bool isSelected, 
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, AppThemeMode mode, IconData icon, AppLanguage lang) {
    final settings = context.watch<AppSettings>();
    final isSelected = settings.themeMode == mode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.read<AppSettings>().setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              _getThemeName(mode, lang),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppThemeMode mode, AppLanguage lang) {
    if (mode == AppThemeMode.system) return lang.tr('theme_system');
    if (mode == AppThemeMode.light) return lang.tr('theme_light');
    if (mode == AppThemeMode.dark) return lang.tr('theme_dark');
    return mode.displayName;
  }
}
