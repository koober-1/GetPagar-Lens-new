class EmployeeImageCache {
  EmployeeImageCache._();
  static final EmployeeImageCache instance = EmployeeImageCache._();

  final Map<String, String> _localPaths = {};

  void set(String employeeCode, String localPath) {
    _localPaths[employeeCode.trim()] = localPath;
  }

  String? get(String employeeCode) {
    return _localPaths[employeeCode.trim()];
  }

  void clear(String employeeCode) {
    _localPaths.remove(employeeCode.trim());
  }
}