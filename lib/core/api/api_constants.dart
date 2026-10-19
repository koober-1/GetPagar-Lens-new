class ApiConstants {
  // ============================================================
  // HRM API
  // ============================================================
  static const String hrmBaseUrl = 'https://backend.getpagar.com/api';

  // ============================================================
  // EMPLOYEES
  // ============================================================
  static String getAllEmployees(int companyId) =>
      '/employees/company/$companyId/face-scan';

  // ============================================================
  // FACE API
  // ============================================================
  static const String faceApiBaseUrl = 'https://facescanbackend.getpagar.com';

  // ============================================================
  // SOCKET.IO
  // ============================================================
  static const String socketUrl = 'https://facescanbackend.getpagar.com';

  static const String socketPath = '/socket.io/';

  // ============================================================
  // FACE IDENTIFICATION
  // ============================================================
  static String identifyEmployee(int companyId) =>
      '/api/attendance/new-identify-employee/$companyId';

  // ============================================================
  // SETTING DATA
  // ============================================================
  static String getFaceScanStatsData(int companyId) =>
      '/attendances/face-scan-stats/$companyId';

  // ============================================================
  // FACE SCAN REPORT
  // ============================================================
  static String faceScanReport(int companyId, String date) =>
      '/attendances/facescan-report/$companyId?date=$date';

  // ============================================================
  // FACE SCAN REPORT
  // ============================================================
  static String faceAllFaceScanLogsExport(int companyId) =>
      '/attendances/facescan-export-all/$companyId';

  // ============================================================
  // ATTENDANCE
  // ============================================================
  static const String markAttendance = '/attendances/mark';

  static const String newMarkAttendance = '/attendances/new-mark';

  // ============================================================
  // EMPLOYEE FACE
  // ============================================================
  static String updateEmployeeFace(int id) => '/employees/put/image/$id';

  static const String faceMultipartFileField = 'image';

  static const bool faceMultipartAlsoSendFileField = false;

  static const String deleteEmployeeFace = '/employees/';

  // ============================================================
  // AUTH
  // ============================================================
  // static const String sendOtp = '/auth/send-sample-admin-otp';

  static const String sendOtp = '/auth/send-admin-otp';

  static const String verifyOtp = '/auth/verify-admin-otp';

  // ============================================================
  // ADMIN
  // ============================================================
  static String adminCompanies(String mobile) => '/auth/admin-companie/$mobile';
}
