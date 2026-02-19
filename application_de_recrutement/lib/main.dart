import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/core/app_theme.dart';
import 'src/core/auth_state.dart';
import 'src/core/app_settings.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/shell/main_shell.dart';
import 'src/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RecruitmentApp());
}

class RecruitmentApp extends StatelessWidget {
  const RecruitmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..loadFromStorage()),
        ChangeNotifierProvider(create: (_) => AppSettings()..loadFromStorage()),
        ChangeNotifierProvider(create: (context) => NotificationService(context.read<AuthState>(), _navigatorKey)..init()),
      ],
      child: Consumer2<AuthState, AppSettings>(
        builder: (context, auth, settings, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'JobConnect',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('fr', ''),
              Locale('ar', ''),
            ],
            locale: Locale(settings.language.code),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode.toFlutterThemeMode(),
            home: auth.isAuthenticated 
                ? const MainShell() 
                : (auth.hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen()),
          );
        },
      ),
    );
  }
}
