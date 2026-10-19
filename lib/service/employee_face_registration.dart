import '../models/employee_model.dart';
import 'employee_registration_cache.dart';

class EmployeeFaceRegistration {
  EmployeeFaceRegistration._();
  static final EmployeeFaceRegistration instance = EmployeeFaceRegistration._();

  Future<bool> isRegistered(EmployeeModel employee) async {
    final registered = await EmployeeRegistrationCache.instance.readRegisteredCodes();
    final cleared = await EmployeeRegistrationCache.instance.readClearedCodes();
    return employee.isFaceRegistered(
      cachedRegisteredCodes: registered,
      cachedClearedCodes: cleared,
    );
  }
}
