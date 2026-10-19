import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String tokenKey = 'token';
  static const String companyKey = 'selected_company';

  // Last screen
  static const String lastRouteKey = 'last_route';

  // Logout state
  static const String hasLoggedOutKey = 'has_logged_out';

  // Screen state
  static const String employeeScreenKey = 'employee_screen';
  static const String attendanceCameraKey = 'attendance_camera';

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(tokenKey, token);

    // A successful login means the user is no longer logged out.
    await prefs.setBool(hasLoggedOutKey, false);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
  }

  // ============================================================
  // LOGOUT STATE
  // ============================================================

  static Future<void> setHasLoggedOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(hasLoggedOutKey, value);
  }

  static Future<bool> getHasLoggedOut() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(hasLoggedOutKey) ?? false;
  }

  // ============================================================
  // SELECTED COMPANY
  // ============================================================

  static Future<void> saveCompany(Map<String, dynamic> company) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(companyKey, jsonEncode(company));
  }

  static Future<Map<String, dynamic>?> getCompany() async {
    final prefs = await SharedPreferences.getInstance();

    final company = prefs.getString(companyKey);

    if (company == null) {
      return null;
    }

    return jsonDecode(company) as Map<String, dynamic>;
  }

  static Future<void> removeCompany() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(companyKey);
  }

  // ============================================================
  // LAST ROUTE
  // ============================================================

  static Future<void> saveLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(lastRouteKey, route);
  }

  static Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(lastRouteKey);
  }

  static Future<void> removeLastRoute() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(lastRouteKey);
  }

  // ============================================================
  // EMPLOYEE SCREEN STATE
  // ============================================================

  static Future<void> setEmployeeScreen(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(employeeScreenKey, value);
  }

  static Future<bool> getEmployeeScreen() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(employeeScreenKey) ?? false;
  }

  // ============================================================
  // ATTENDANCE CAMERA STATE
  // ============================================================

  static Future<void> setAttendanceCamera(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(attendanceCameraKey, value);
  }

  static Future<bool> getAttendanceCamera() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(attendanceCameraKey) ?? false;
  }

  // ============================================================
  // SAVE EMPLOYEE SCREEN STATE
  // ============================================================

  static Future<void> saveEmployeeScreenState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(employeeScreenKey, true);

    await prefs.setBool(attendanceCameraKey, false);

    await prefs.setString(lastRouteKey, 'employee');
  }

  // ============================================================
  // SAVE ATTENDANCE CAMERA STATE
  // ============================================================

  static Future<void> saveAttendanceCameraState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(employeeScreenKey, true);

    await prefs.setBool(attendanceCameraKey, true);

    await prefs.setString(lastRouteKey, 'attendance_camera');
  }

  // ============================================================
  // CLEAR SCREEN STATE
  // ============================================================

  static Future<void> clearScreenState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(employeeScreenKey);
    await prefs.remove(attendanceCameraKey);
    await prefs.remove(lastRouteKey);
  }

  // ============================================================
  // GET SAVED SCREEN STATE
  // ============================================================

  static Future<Map<String, bool>> getScreenState() async {
    final prefs = await SharedPreferences.getInstance();

    final employee = prefs.getBool(employeeScreenKey) ?? false;
    final camera = prefs.getBool(attendanceCameraKey) ?? false;

    return {'employeeScreen': employee, 'attendanceCamera': camera};
  }

  // ============================================================
  // CLEAR LOGIN DATA
  // ============================================================

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // ----------------------------------------------------------
    // Remove authentication/session data.
    // ----------------------------------------------------------

    await prefs.remove(tokenKey);
    await prefs.remove(companyKey);
    await prefs.remove(lastRouteKey);

    // ----------------------------------------------------------
    // Remove screen state.
    // ----------------------------------------------------------

    await prefs.remove(employeeScreenKey);
    await prefs.remove(attendanceCameraKey);

    // ----------------------------------------------------------
    // IMPORTANT:
    // Keep this flag so the app knows that the user
    // explicitly logged out.
    // ----------------------------------------------------------

    await prefs.setBool(hasLoggedOutKey, true);
  }
}
