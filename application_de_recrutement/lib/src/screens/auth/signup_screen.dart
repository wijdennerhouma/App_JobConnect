import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../services/auth_service.dart';
import '../onboarding/post_signup_wizard_screen.dart';

import 'animated_background.dart';
import 'auth_settings_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // acts as Last Name for candidates, or Company Name
  final _firstNameController = TextEditingController(); // Only for candidates
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isEmployee = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
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
      final result = await authService.signup(
        name: _nameController.text.trim(),
        firstName: _isEmployee ? _firstNameController.text.trim() : null,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        city: _cityController.text.trim(),
        type: _isEmployee ? 'employee' : 'entreprise',
      );

      if (!mounted) return;
      await context.read<AuthState>().setSession(
            token: result.token,
            userId: result.userId,
            type: result.type,
          );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PostSignupWizardScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
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
              constraints: const BoxConstraints(maxWidth: 480),
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
                        Text(
                          lang.tr('signup'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Custom styled SegmentedButton equivalent or wrapped for dark mode
                        Theme(
                          data: theme.copyWith(
                            segmentedButtonTheme: SegmentedButtonThemeData(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return Colors.blue;
                                    }
                                    return isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2);
                                  },
                                ),
                                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return Colors.white;
                                    }
                                    return subTextColor;
                                  },
                                ),
                                side: MaterialStateProperty.all(
                                  BorderSide(color: borderColor),
                                ),
                              ),
                            ),
                          ),
                          child: SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: true,
                                label: Text(lang.tr('candidate')),
                                icon: const Icon(Icons.person_outline),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text(lang.tr('company')),
                                icon: const Icon(Icons.business_outlined),
                              ),
                            ],
                            selected: {_isEmployee},
                            onSelectionChanged: (set) {
                              setState(() {
                                _isEmployee = set.first;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isEmployee) ...[
                           TextFormField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: lang.tr('first_name_label') ?? 'Prénom', // Ensure translation key exists or use fallback
                              labelStyle: TextStyle(color: subTextColor),
                              prefixIcon: Icon(Icons.person_outline, color: subTextColor),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: !isDark,
                              fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return lang.tr('not_provided');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: _isEmployee ? (lang.tr('name_label') ?? 'Nom') : lang.tr('full_name_or_company'),
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.person, color: subTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: !isDark,
                            fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.tr('not_provided');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.tr('email'),
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: !isDark,
                            fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.tr('not_provided');
                            }
                            if (!value.contains('@')) {
                              return lang.tr('error');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.tr('password'),
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: !isDark,
                            fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang.tr('not_provided');
                            }
                            if (value.length < 6) {
                              return lang.tr('error');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cityController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: lang.tr('city_label'),
                            labelStyle: TextStyle(color: subTextColor),
                            prefixIcon: Icon(Icons.location_city_outlined, color: subTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: !isDark,
                            fillColor: !isDark ? Colors.white.withOpacity(0.5) : null,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(color: isDark ? Colors.red[300] : Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    lang.tr('signup_button'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
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

