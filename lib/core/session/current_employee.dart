import 'package:getpagar_lens/models/employee_model.dart';

class CurrentEmployee {
  static EmployeeModel? employee;

  static void updateImage(String newImagePath) {
    if (employee == null) return;
    employee = employee!.copyWith(image: newImagePath);
  }
}
