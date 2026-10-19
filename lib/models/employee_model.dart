class EmployeeModel {
  final int id;
  final int companyId;
  final int branchId;
  final String employeeName;
  final String employeeCode;
  final String departmentName;
  final String image;

  EmployeeModel({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.employeeName,
    required this.employeeCode,
    required this.departmentName,
    required this.image,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: (json['id'] as num).toInt(),
      companyId: (json['company_id'] as num).toInt(),
      branchId: (json['branch_id'] as num).toInt(),
      employeeName: json['employee_name'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      departmentName: json['department']?['department_name'] ?? '',
      image: json['image_url'] ?? '',
    );
  }

  bool isFaceRegistered({
    required Set<String> cachedRegisteredCodes,
    required Set<String> cachedClearedCodes,
  }) {
    final code = employeeCode.trim();
    if (code.isNotEmpty && cachedClearedCodes.contains(code)) {
      return false;
    }
    if (code.isNotEmpty && cachedRegisteredCodes.contains(code)) {
      return true;
    }
    return image.trim().isNotEmpty;
  }

  EmployeeModel copyWith({
    int? id,
    int? companyId,
    int? branchId,
    String? employeeName,
    String? employeeCode,
    String? departmentName,
    String? image,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      departmentName: departmentName ?? this.departmentName,
      image: image ?? this.image,
    );
  }
}
