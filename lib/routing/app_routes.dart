class AppRoutes {
  static const login = '/';
  static const welcome = '/welcome';
  static const home = '/home';
  static const setting = '/setting';
  static const facePreview = '/facePreview';

  static const testScreen = '/testScreen';

  /// Bottom tabs inside [ShellRoute]
  static const employee = '/home/employee';
  static const logs = '/home/logs';

  /// Full-screen routes **outside** the shell (no bottom navigation).
  static const registrationInstructions = '/registration/instructions';
  static const registrationCamera = '/registration/camera';
  static const registrationSuccess = '/registration/success';
  static const employeeProfile = '/employee/profile';
  static const attendanceCamera = '/attendance/camera';
}
