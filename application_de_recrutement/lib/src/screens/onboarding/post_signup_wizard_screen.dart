import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_button.dart';
import '../auth/animated_background.dart';
import '../shell/main_shell.dart';
import '../profile/profile_screen.dart';
import '../profile/manage_cv_screen.dart';
import '../entreprise/job_form_screen.dart';

/// Post-signup wizard: 2–3 steps by role (candidate or company) then go to main app.
class PostSignupWizardScreen extends StatefulWidget {
  const PostSignupWizardScreen({super.key});

  @override
  State<PostSignupWizardScreen> createState() => _PostSignupWizardScreenState();
}

class _PostSignupWizardScreenState extends State<PostSignupWizardScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final lang = context.watch<AppSettings>().language;
    final theme = Theme.of(context);
    final isEmployee = auth.isEmployee;
    final steps = isEmployee
        ? [
            lang.tr('complete_profile'),
            lang.tr('manage_cv'),
          ]
        : [
            lang.tr('complete_profile'),
            lang.tr('publish'),
          ];
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  lang.tr('welcome'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEmployee
                      ? lang.tr('complete_profile_promo')
                      : 'Complétez les informations de votre entreprise et publiez votre première offre.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate(steps.length, (i) {
                  final isActive = i == _step;
                  final isDone = i < _step;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      opacity: isActive ? 0.25 : 0.15,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? theme.colorScheme.primary
                                  : (isActive
                                      ? theme.colorScheme.primary.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3)),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              steps[i],
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                GlassButton(
                  onPressed: () async {
                    if (_step == 0) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(),
                        ),
                      );
                      if (mounted) setState(() => _step = 1);
                    } else if (_step == 1) {
                      if (isEmployee) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageCVScreen(),
                          ),
                        );
                      } else {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobFormScreen(),
                          ),
                        );
                      }
                      if (mounted) _goToMain();
                    }
                  },
                  width: double.infinity,
                  height: 56,
                  borderRadius: 20,
                  child: Text(
                    _step == 0
                        ? lang.tr('edit_profile')
                        : (isEmployee ? lang.tr('manage_cv') : lang.tr('publish')),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goToMain,
                  child: Text(
                    lang.tr('skip'),
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }
}
