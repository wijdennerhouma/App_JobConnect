import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../services/auth_service.dart';
import 'animated_background.dart';
import 'auth_settings_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = AuthService();
      await authService.forgotPassword(_emailController.text.trim());
      
      if (!mounted) return;
      final lang = context.read<AppSettings>().language;
      
      setState(() {
        _message = lang.tr('reset_email_sent');
        _isError = false;
        _emailController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        leading: BackButton(color: textColor),
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
              child: Card(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 64,
                          color: textColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.tr('forgot_password_title'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.tr('forgot_password_instruction'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: subTextColor),
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
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
                        
                        if (_message != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isError
                                  ? Colors.red.withOpacity(isDark ? 0.2 : 0.1)
                                  : Colors.green.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _isError
                                      ? (isDark ? Colors.red.withOpacity(0.5) : Colors.red)
                                      : (isDark ? Colors.green.withOpacity(0.5) : Colors.green)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isError ? Icons.error_outline : Icons.check_circle_outline,
                                  color: _isError
                                      ? (isDark ? Colors.red[200] : Colors.red[700])
                                      : (isDark ? Colors.green[200] : Colors.green[700]),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _message!,
                                    style: TextStyle(
                                      color: _isError
                                          ? (isDark ? Colors.red[100] : Colors.red[900])
                                          : (isDark ? Colors.green[100] : Colors.green[900]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                : Text(lang.tr('send_reset_link'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(lang.tr('back_to_login'), style: TextStyle(color: subTextColor)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
