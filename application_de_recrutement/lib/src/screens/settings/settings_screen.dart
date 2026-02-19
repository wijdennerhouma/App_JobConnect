import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import 'privacy_screen.dart';
import 'security_screen.dart';
import 'help_support_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lang = settings.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Langue
          _buildSection(
            context,
            title: lang.tr('language'),
            icon: Icons.language,
            children: [
              _buildLanguageOption(context),
            ],
          ),

          const SizedBox(height: 24),

          // Apparence
          _buildSection(
            context,
            title: lang.tr('appearance'),
            icon: Icons.palette,
            children: [
              _buildThemeOption(context),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications
          _buildSection(
            context,
            title: lang.tr('notifications'),
            icon: Icons.notifications,
            children: [
              _buildNotificationSwitch(
                context,
                title: lang.tr('notifications'),
                value: context.watch<AppSettings>().notificationsEnabled,
                onChanged: (value) {
                  context.read<AppSettings>().setNotificationsEnabled(value);
                },
              ),
              if (context.watch<AppSettings>().notificationsEnabled) ...[
                const Divider(height: 32),
                _buildNotificationSwitch(
                  context,
                  title: lang.tr('email_notifications'),
                  subtitle: lang.tr('notifications_subtitle'),
                  value: context.watch<AppSettings>().emailNotifications,
                  onChanged: (value) {
                    context.read<AppSettings>().setEmailNotifications(value);
                  },
                ),
                const Divider(height: 32),
                _buildNotificationSwitch(
                  context,
                  title: lang.tr('push_notifications'),
                  subtitle: lang.tr('notifications_subtitle'),
                  value: context.watch<AppSettings>().pushNotifications,
                  onChanged: (value) {
                    context.read<AppSettings>().setPushNotifications(value);
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Compte
          _buildSection(
            context,
            title: lang.tr('account'),
            icon: Icons.account_circle,
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text(lang.tr('privacy')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(lang.tr('security')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // À propos
          _buildSection(
            context,
            title: lang.tr('about'),
            icon: Icons.info,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: Text(lang.tr('version')),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help),
                title: Text(lang.tr('help_support')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description),
                title: Text(lang.tr('terms_of_use')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.shield),
                title: Text(lang.tr('privacy_policy')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lang = settings.language;
    
    return Column(
      children: AppLanguage.values.map((langValue) {
        return RadioListTile<AppLanguage>(
          title: Text(langValue.name),
          value: langValue,
          groupValue: settings.language,
          onChanged: (value) {
            if (value != null) {
              context.read<AppSettings>().setLanguage(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${lang.tr('language_changed')}: ${langValue.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildThemeOption(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final lang = settings.language;
    
    return Column(
      children: AppThemeMode.values.map((mode) {
        String themeTitle = '';
        String? themeSubtitle;
        
        switch (mode) {
          case AppThemeMode.system:
            themeTitle = lang.tr('theme_system');
            themeSubtitle = lang.tr('theme_system_subtitle');
            break;
          case AppThemeMode.light:
            themeTitle = lang.tr('theme_light');
            break;
          case AppThemeMode.dark:
            themeTitle = lang.tr('theme_dark');
            break;
        }
        
        return RadioListTile<AppThemeMode>(
          title: Text(themeTitle),
          subtitle: themeSubtitle != null ? Text(themeSubtitle) : null,
          value: mode,
          groupValue: settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              context.read<AppSettings>().setThemeMode(value);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildNotificationSwitch(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
