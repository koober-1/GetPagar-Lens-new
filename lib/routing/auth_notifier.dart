import 'package:flutter/foundation.dart';

import '../core/storage/local_storage.dart';
import 'app_routes.dart';

class AuthNotifier extends ChangeNotifier {
  bool initialized = false;
  bool loggedIn = false;
  bool logOut = false;

  // ============================================================
  // SCREEN STATE
  // ============================================================

  // True when the user is inside the employee section.
  bool employeeScreen = false;

  // True when the Attendance Camera screen is active.
  bool attendanceCamera = false;

  String? lastRoute;

  // Used for first-login / Welcome Screen flow.
  String? postLoginRoute;

  // Mobile number used for first-login Welcome Screen.
  String? loginMobile;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> init() async {
    final token = await LocalStorage.getToken();
    final hasLoggedOut = await LocalStorage.getHasLoggedOut();

    loggedIn = token != null && token.isNotEmpty;

    if (loggedIn) {
      logOut = false;

      // ----------------------------------------------------------
      // IMPORTANT:
      // Do NOT set postLoginRoute here.
      //
      // postLoginRoute is only used during login / Welcome flow.
      // ----------------------------------------------------------

      postLoginRoute = null;
      loginMobile = null;

      // ----------------------------------------------------------
      // LOAD SAVED SCREEN STATE
      // ----------------------------------------------------------

      employeeScreen = await LocalStorage.getEmployeeScreen();
      attendanceCamera = await LocalStorage.getAttendanceCamera();

      debugPrint('==========================================');
      debugPrint('AUTH INIT');
      debugPrint('Token exists');
      debugPrint('loggedIn = true');
      debugPrint('logOut = false');
      debugPrint('employeeScreen = $employeeScreen');
      debugPrint('attendanceCamera = $attendanceCamera');

      // ----------------------------------------------------------
      // APP RESTART ROUTE
      // ----------------------------------------------------------

      if (employeeScreen && attendanceCamera) {
        // User closed the app while Attendance Camera was open.

        lastRoute = AppRoutes.attendanceCamera;

        await LocalStorage.saveLastRoute(AppRoutes.attendanceCamera);

        debugPrint('Route = ${AppRoutes.attendanceCamera}');
      } else if (employeeScreen && !attendanceCamera) {
        // User closed the app while Employee Screen was open.

        lastRoute = AppRoutes.employee;

        await LocalStorage.saveLastRoute(AppRoutes.employee);

        debugPrint('Route = ${AppRoutes.employee}');
      } else {
        // --------------------------------------------------------
        // SAFE FALLBACK
        // --------------------------------------------------------
        //
        // If the user is logged in but no screen state exists,
        // open Employee Screen.
        // --------------------------------------------------------

        employeeScreen = true;
        attendanceCamera = false;

        lastRoute = AppRoutes.employee;

        await LocalStorage.setEmployeeScreen(true);
        await LocalStorage.setAttendanceCamera(false);
        await LocalStorage.saveLastRoute(AppRoutes.employee);

        debugPrint('No saved screen state.');
        debugPrint('Fallback Route = ${AppRoutes.employee}');
      }

      debugPrint('==========================================');
    } else {
      // ----------------------------------------------------------
      // NOT LOGGED IN
      // ----------------------------------------------------------

      loggedIn = false;
      logOut = hasLoggedOut;

      postLoginRoute = null;
      loginMobile = null;

      lastRoute = null;

      employeeScreen = false;
      attendanceCamera = false;

      debugPrint('==========================================');
      debugPrint('AUTH INIT');
      debugPrint('Token does not exist');
      debugPrint('loggedIn = false');
      debugPrint('logOut = $logOut');
      debugPrint('employeeScreen = false');
      debugPrint('attendanceCamera = false');
      debugPrint('==========================================');
    }

    initialized = true;

    notifyListeners();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login({String? nextRoute, String? mobile}) async {
    debugPrint('==========================================');
    debugPrint('BEFORE LOGIN');
    debugPrint('loggedIn: $loggedIn');
    debugPrint('logOut: $logOut');

    // ----------------------------------------------------------
    // AUTH STATE
    // ----------------------------------------------------------

    loggedIn = true;
    logOut = false;

    // ----------------------------------------------------------
    // IMPORTANT:
    // KEEP YOUR WELCOME SCREEN LOGIC
    // ----------------------------------------------------------

    postLoginRoute = nextRoute;
    loginMobile = mobile;

    // ----------------------------------------------------------
    // DEFAULT LOGIN SCREEN
    // ----------------------------------------------------------

    employeeScreen = true;
    attendanceCamera = false;

    lastRoute = AppRoutes.employee;

    // ----------------------------------------------------------
    // SAVE LOGIN STATE
    // ----------------------------------------------------------

    await LocalStorage.setHasLoggedOut(false);

    await LocalStorage.setEmployeeScreen(true);

    await LocalStorage.setAttendanceCamera(false);

    await LocalStorage.saveLastRoute(AppRoutes.employee);

    debugPrint('AFTER LOGIN');
    debugPrint('loggedIn: $loggedIn');
    debugPrint('logOut: $logOut');
    debugPrint('postLoginRoute: $postLoginRoute');
    debugPrint('loginMobile: $loginMobile');
    debugPrint('employeeScreen: $employeeScreen');
    debugPrint('attendanceCamera: $attendanceCamera');
    debugPrint('lastRoute: $lastRoute');
    debugPrint('==========================================');

    notifyListeners();
  }

  // ============================================================
  // OPEN EMPLOYEE SCREEN
  // ============================================================

  Future<void> openEmployeeScreen() async {
    // ----------------------------------------------------------
    // SCREEN STATE
    // ----------------------------------------------------------

    employeeScreen = true;
    attendanceCamera = false;

    lastRoute = AppRoutes.employee;

    // ----------------------------------------------------------
    // SAVE STATE
    // ----------------------------------------------------------

    await LocalStorage.setEmployeeScreen(true);

    await LocalStorage.setAttendanceCamera(false);

    await LocalStorage.saveLastRoute(AppRoutes.employee);

    debugPrint('==========================================');
    debugPrint('OPEN EMPLOYEE SCREEN');
    debugPrint('employeeScreen = true');
    debugPrint('attendanceCamera = false');
    debugPrint('lastRoute = ${AppRoutes.employee}');
    debugPrint('==========================================');

    notifyListeners();
  }

  // ============================================================
  // OPEN ATTENDANCE CAMERA
  // ============================================================

  Future<void> openAttendanceCamera() async {
    // ----------------------------------------------------------
    // SCREEN STATE
    // ----------------------------------------------------------

    employeeScreen = true;
    attendanceCamera = true;

    lastRoute = AppRoutes.attendanceCamera;

    // ----------------------------------------------------------
    // SAVE STATE
    // ----------------------------------------------------------

    await LocalStorage.setEmployeeScreen(true);

    await LocalStorage.setAttendanceCamera(true);

    await LocalStorage.saveLastRoute(AppRoutes.attendanceCamera);

    debugPrint('==========================================');
    debugPrint('OPEN ATTENDANCE CAMERA');
    debugPrint('employeeScreen = true');
    debugPrint('attendanceCamera = true');
    debugPrint('lastRoute = ${AppRoutes.attendanceCamera}');
    debugPrint('==========================================');

    notifyListeners();
  }

  // ============================================================
  // SAVE LAST SCREEN
  // ============================================================

  Future<void> setLastRoute(String route) async {
    // ----------------------------------------------------------
    // EMPLOYEE SCREEN
    // ----------------------------------------------------------

    if (route == AppRoutes.employee) {
      await openEmployeeScreen();
      return;
    }

    // ----------------------------------------------------------
    // ATTENDANCE CAMERA
    // ----------------------------------------------------------

    if (route == AppRoutes.attendanceCamera) {
      await openAttendanceCamera();
      return;
    }

    // Ignore unsupported routes.
    return;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    debugPrint('==========================================');
    debugPrint('BEFORE LOGOUT');
    debugPrint('loggedIn: $loggedIn');

    // ----------------------------------------------------------
    // AUTH STATE
    // ----------------------------------------------------------

    loggedIn = false;
    logOut = true;

    // ----------------------------------------------------------
    // CLEAR MEMORY STATE
    // ----------------------------------------------------------

    lastRoute = null;
    postLoginRoute = null;
    loginMobile = null;

    employeeScreen = false;
    attendanceCamera = false;

    // ----------------------------------------------------------
    // CLEAR PERSISTED LOGIN STATE
    // ----------------------------------------------------------

    await LocalStorage.logout();

    debugPrint('AFTER LOGOUT');
    debugPrint('loggedIn: $loggedIn');
    debugPrint('logOut: $logOut');
    debugPrint('employeeScreen: $employeeScreen');
    debugPrint('attendanceCamera: $attendanceCamera');
    debugPrint('==========================================');

    notifyListeners();
  }

  // ============================================================
  // CLOSE ATTENDANCE CAMERA
  // ============================================================

  Future<void> closeAttendanceCamera() async {
    employeeScreen = true;
    attendanceCamera = false;

    lastRoute = AppRoutes.employee;

    await LocalStorage.setEmployeeScreen(true);
    await LocalStorage.setAttendanceCamera(false);
    await LocalStorage.saveLastRoute(AppRoutes.employee);

    debugPrint('==========================================');
    debugPrint('CLOSE ATTENDANCE CAMERA');
    debugPrint('employeeScreen = true');
    debugPrint('attendanceCamera = false');
    debugPrint('lastRoute = ${AppRoutes.employee}');
    debugPrint('==========================================');

    notifyListeners();
  }

  // ============================================================
  // RESET TO LOGIN
  // ============================================================

  Future<void> resetToLogin() async {
    debugPrint('==========================================');
    debugPrint('RESETTING AUTHENTICATION TO LOGIN');

    // ----------------------------------------------------------
    // AUTH STATE
    // ----------------------------------------------------------

    loggedIn = false;
    logOut = true;

    // ----------------------------------------------------------
    // CLEAR MEMORY STATE
    // ----------------------------------------------------------

    lastRoute = null;
    postLoginRoute = null;
    loginMobile = null;

    employeeScreen = false;
    attendanceCamera = false;

    // ----------------------------------------------------------
    // CLEAR PERSISTED STATE
    // ----------------------------------------------------------

    await LocalStorage.logout();

    debugPrint('loggedIn = $loggedIn');
    debugPrint('logOut = $logOut');
    debugPrint('employeeScreen = $employeeScreen');
    debugPrint('attendanceCamera = $attendanceCamera');
    debugPrint('==========================================');

    notifyListeners();
  }
}
