import 'package:flutter/foundation.dart';

/// Tiny signal so the employee tab can refetch when registration or delete finishes,
/// without pulling in a full state-management library.
class EmployeeListRefreshNotifier extends ChangeNotifier {
  EmployeeListRefreshNotifier._();
  static final EmployeeListRefreshNotifier instance = EmployeeListRefreshNotifier._();

  void requestRefresh() => notifyListeners();
}
