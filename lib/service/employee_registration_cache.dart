import 'package:shared_preferences/shared_preferences.dart';

class EmployeeRegistrationCache {
  EmployeeRegistrationCache._();
  static final EmployeeRegistrationCache instance = EmployeeRegistrationCache._();

  static const _registeredKey = 'face_registered_employee_codes';
  static const _clearedKey = 'face_registration_cleared_employee_codes';

  Future<Set<String>> readRegisteredCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return _readSet(prefs, _registeredKey);
  }

  Future<Set<String>> readClearedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return _readSet(prefs, _clearedKey);
  }

  Set<String> _readSet(SharedPreferences prefs, String key) {
    return prefs.getStringList(key)?.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet() ??
        {};
  }

  Future<void> addRegisteredCode(String employeeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final reg = _readSet(prefs, _registeredKey);
    final clr = _readSet(prefs, _clearedKey);
    final code = employeeCode.trim();
    reg.add(code);
    clr.remove(code);
    await prefs.setStringList(_registeredKey, reg.toList());
    await prefs.setStringList(_clearedKey, clr.toList());
  }

  Future<void> removeRegisteredCode(String employeeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final reg = _readSet(prefs, _registeredKey);
    reg.remove(employeeCode.trim());
    await prefs.setStringList(_registeredKey, reg.toList());
  }

  /// Call after the face backend confirms delete so the UI stops treating stale HRM images as registered.
  Future<void> markClearedAfterDelete(String employeeCode) async {
    final prefs = await SharedPreferences.getInstance();
    final reg = _readSet(prefs, _registeredKey);
    final clr = _readSet(prefs, _clearedKey);
    final code = employeeCode.trim();
    reg.remove(code);
    clr.add(code);
    await prefs.setStringList(_registeredKey, reg.toList());
    await prefs.setStringList(_clearedKey, clr.toList());
  }
}
