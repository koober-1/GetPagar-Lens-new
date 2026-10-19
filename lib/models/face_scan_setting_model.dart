class FaceScanSettingsModel {
  final bool success;
  final String companyId;
  final int totalFaceScanEmployeeCount;
  final int totalFaceScanAttendanceCount;
  final String lastSyncTime;
  final String lastSyncDate;

  FaceScanSettingsModel({
    required this.success,
    required this.companyId,
    required this.totalFaceScanEmployeeCount,
    required this.totalFaceScanAttendanceCount,
    required this.lastSyncTime,
    required this.lastSyncDate,
  });

  factory FaceScanSettingsModel.fromJson(Map<String, dynamic> json) {
    return FaceScanSettingsModel(
      success: json['success'] ?? false,
      companyId: json['company_id']?.toString() ?? '',
      totalFaceScanEmployeeCount: json['totalFaceScanEmployeeCount'] ?? 0,
      totalFaceScanAttendanceCount: json['totalFaceScanAttendanceCount'] ?? 0,
      lastSyncTime: json['lastSyncTime'] ?? '',
      lastSyncDate: json['lastSyncDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'company_id': companyId,
      'totalFaceScanEmployeeCount': totalFaceScanEmployeeCount,
      'totalFaceScanAttendanceCount': totalFaceScanAttendanceCount,
      'lastSyncTime': lastSyncTime,
      'lastSyncDate': lastSyncDate,
    };
  }
}
