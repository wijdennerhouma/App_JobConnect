import 'package:flutter/foundation.dart';

class ApiConfig {
  /// You can override at runtime with:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:3000`
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      // For Flutter Web running on the same machine as backend
      // Use 127.0.0.1 to avoid potential IPv6 resolution issues with localhost
      return 'http://127.0.0.1:3000';
    }

    // Mobile/desktop defaults
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator uses 10.0.2.2 to reach host machine localhost
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:3000';
      default:
        return 'http://localhost:3000';
    }
  }
}

