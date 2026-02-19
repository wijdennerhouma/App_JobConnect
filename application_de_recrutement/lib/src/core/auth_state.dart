import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserType { employee, entreprise }

class AuthState extends ChangeNotifier {
  String? _token;
  String? _userId;
  UserType? _userType;

  String? get token => _token;
  String? get userId => _userId;
  UserType? get userType => _userType;

  bool get isAuthenticated => _token != null && _userId != null;
  bool get isEmployee => _userType == UserType.employee;
  bool get isEntreprise => _userType == UserType.entreprise;

  bool _isTwoFactorEnabled = false;
  bool get isTwoFactorEnabled => _isTwoFactorEnabled;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _isTwoFactorEnabled = prefs.getBool('isTwoFactorEnabled') ?? false;
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final typeStr = prefs.getString('userType');
    if (typeStr == 'employee') {
      _userType = UserType.employee;
    } else if (typeStr == 'entreprise') {
      _userType = UserType.entreprise;
    }
    notifyListeners();
  }

  Future<void> setSession({
    required String token,
    required String userId,
    required String type,
  }) async {
    _token = token;
    _userId = userId;
    _userType = type == 'employee' ? UserType.employee : UserType.entreprise;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    await prefs.setString('userType', type);


    final history = prefs.getStringList('login_history') ?? [];
    history.insert(0, DateTime.now().toIso8601String());

    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    await prefs.setStringList('login_history', history);

    notifyListeners();
  }

  Future<List<String>> getLoginHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('login_history') ?? [];
  }
  
  void setTwoFactor(bool enabled) {
    _isTwoFactorEnabled = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isTwoFactorEnabled', enabled);
    });
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _userType = null;
    _isTwoFactorEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userType');
    await prefs.remove('isTwoFactorEnabled');
    notifyListeners();
  }

  Future<void> setHasSeenOnboarding() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    notifyListeners();
  }
}

