class FaceScanLogsExportModel {
  final bool success;
  final String companyId;
  final int totalRecords;
  final List<FaceScanLogsExportData> data;

  FaceScanLogsExportModel({
    required this.success,
    required this.companyId,
    required this.totalRecords,
    required this.data,
  });

  factory FaceScanLogsExportModel.fromJson(Map<String, dynamic> json) {
    return FaceScanLogsExportModel(
      success: json['success'] ?? false,
      companyId: json['company_id']?.toString() ?? '',
      totalRecords: json['totalRecords'] ?? 0,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => FaceScanLogsExportData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'company_id': companyId,
      'totalRecords': totalRecords,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class FaceScanLogsExportData {
  final int srNo;
  final String employeeCode;
  final String date;
  final String time;
  final String latitude;
  final String longitude;
  final String address;
  final String lastSyncDate;
  final String lastSyncTime;

  FaceScanLogsExportData({
    required this.srNo,
    required this.employeeCode,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.lastSyncDate,
    required this.lastSyncTime,
  });

  factory FaceScanLogsExportData.fromJson(Map<String, dynamic> json) {
    return FaceScanLogsExportData(
      srNo: json['srNo'] ?? 0,
      employeeCode: json['employeeCode'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      address: json['address'] ?? '',
      lastSyncDate: json['lastSyncDate'] ?? '',
      lastSyncTime: json['lastSyncTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'employeeCode': employeeCode,
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'lastSyncDate': lastSyncDate,
      'lastSyncTime': lastSyncTime,
    };
  }
}
