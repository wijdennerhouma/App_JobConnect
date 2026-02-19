import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/translations.dart';

import '../../core/auth_state.dart';
import '../../services/auth_service.dart';
import 'login_history_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('security_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('authentication'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(lang.tr('change_password')),
                    subtitle: Text(lang.tr('update_password_regularly')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(lang.tr('two_factor_auth_title')),
                    subtitle: Text(lang.tr('add_security_layer')),
                    value: context.watch<AuthState>().isTwoFactorEnabled,
                    onChanged: (value) async {
                      final auth = context.read<AuthState>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      // Optimistic Update
                      auth.setTwoFactor(value);

                      try {
                        if (auth.userId != null && auth.token != null) {
                           await AuthService().toggleTwoFactor(auth.userId!, value, auth.token!);
                           scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(value ? lang.tr('2fa_on') : lang.tr('2fa_off'))),
                          );
                        }
                      } catch (e) {
                         // Revert on failure
                         auth.setTwoFactor(!value);
                         scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('${lang.tr('error')}: $e')),
                          );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.devices, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('connected_devices'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.laptop_chromebook),
                    title: const Text('Chrome (Windows)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.tr('current_connection')),
                        Text('${lang.tr('last_activity')}: ${lang.tr('just_now')}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('activity'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(lang.tr('login_history')),
                    subtitle: Text(lang.tr('view_login_history')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginHistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final lang = context.read<AppSettings>().language;
    final auth = context.read<AuthState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? errorMessage;

          return AlertDialog(
            title: Text(lang.tr('change_password')),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.red.withOpacity(0.1),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: lang.tr('current_password'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? lang.tr('required_field') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: lang.tr('new_password'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v != null && v.length < 6)
                          ? lang.tr('min_6_chars')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: lang.tr('confirm_new_password'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v != newPasswordController.text
                          ? lang.tr('password_mismatch_or_short')
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(lang.tr('cancel')),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            if (auth.userId != null && auth.token != null) {
                               await AuthService().changePassword(
                                auth.userId!,
                                oldPasswordController.text,
                                newPasswordController.text,
                                auth.token!,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(lang.tr('password_changed_success'))),
                                );
                              }
                            }
                          } catch (e) {
                            setState(() {
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                              isLoading = false;
                            });
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(lang.tr('change_password')),
              ),
            ],
          );
        },
      ),
    );
  }
}
