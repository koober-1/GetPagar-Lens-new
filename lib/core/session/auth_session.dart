import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env_config.dart';

/// Persists login state so the user stays signed in after the app is killed.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyPhone = 'auth_phone';
  static const _keyCompanyId = 'auth_company_id';
  static const _keyCompanyName = 'auth_company_name';

  SharedPreferences? _prefs;
  bool _isLoggedIn = false;
  String? _phone;
  int _companyId = EnvConfig.defaultCompanyId;
  String _companyName = 'TEST';

  bool get isLoggedIn => _isLoggedIn;
  String? get phone => _phone;
  int get companyId => _companyId;
  String get companyName => _companyName;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _prefs!.getBool(_keyLoggedIn) ?? false;
    _phone = _prefs!.getString(_keyPhone);
    _companyId = _prefs!.getInt(_keyCompanyId) ?? EnvConfig.defaultCompanyId;
    _companyName = _prefs!.getString(_keyCompanyName) ?? 'TEST';
  }

  Future<void> saveLogin({
    required String phone,
    int? companyId,
    String companyName = 'TEST',
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _isLoggedIn = true;
    _phone = phone;
    _companyId = companyId ?? EnvConfig.defaultCompanyId;
    _companyName = companyName;
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyPhone, phone);
    await prefs.setInt(_keyCompanyId, _companyId);
    await prefs.setString(_keyCompanyName, companyName);
    notifyListeners();
  }

  Future<void> clear() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _isLoggedIn = false;
    _phone = null;
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyPhone);
    notifyListeners();
  }
}
