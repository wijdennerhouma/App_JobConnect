import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../services/auth_service.dart';
import '../shell/main_shell.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'auth_settings_dialog.dart';
import 'animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ... (previous variables)
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = AuthService();
      final result = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;

      // Check if 2FA is enabled for this user
      if (result.isTwoFactorEnabled) {
        // Show 2FA verification dialog
        final code = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildTwoFactorDialog(context),
        );

        // If dialog cancelled or empty (though barrier is false, back button returns null)
        if (code == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await context.read<AuthState>().setSession(
            token: result.token,
            userId: result.userId,
            type: result.type,
          );
      // Also sync local state
      context.read<AuthState>().setTwoFactor(result.isTwoFactorEnabled);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if(mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTwoFactorDialog(BuildContext context) {
    final codeController = TextEditingController();
    String? errorText;
    
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Vérification à deux facteurs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Un code de vérification a été envoyé.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Mode Démo : Le code est 123456', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Code de vérification',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
               if (codeController.text == '123456') {
                 Navigator.pop(context, codeController.text);
               } else {
                 setState(() {
                   errorText = 'Code incorrect';
                 });
               }
            },
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<AppSettings>().language;
    final isDark = theme.brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6);
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () => showAuthSettingsDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Use logo or large text
                  Text(
                    'JobConnect',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.tr('login'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: subTextColor),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    color: cardColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: lang.tr('email'),
                                labelStyle: TextStyle(color: subTextColor),
                                prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: !isDark,
                                fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return lang.tr('not_provided');
                                if (!value.contains('@')) return lang.tr('error');
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: lang.tr('password'),
                                labelStyle: TextStyle(color: subTextColor),
                                prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: !isDark,
                                fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                              ),
                              validator: (value) => (value == null || value.isEmpty) ? lang.tr('not_provided') : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  lang.tr('forgot_password'),
                                  style: TextStyle(color: subTextColor),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: isDark ? Colors.red[300] : Colors.red[700])),
                            ],
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF3B82F6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(lang.tr('login_button'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
                              },
                              child: Text(lang.tr('signup'), style: TextStyle(color: subTextColor)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

