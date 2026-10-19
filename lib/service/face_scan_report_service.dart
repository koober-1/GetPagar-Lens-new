import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_constants.dart';
import '../core/storage/local_storage.dart';
import '../models/face_scan_report_model.dart';
import '../models/face_scan_logs_export_model.dart';

class FaceScanReportService {
  FaceScanReportService(this._dio);

  final Dio _dio;

  Future<FaceScanReportModel> getFaceScanReport({required String date}) async {
    try {
      final company = await LocalStorage.getCompany();

      if (company == null || company['id'] == null) {
        throw Exception('Company not selected');
      }

      final int companyId = company['id'];

      debugPrint('Company ID: $companyId');

      final response = await _dio.get(
        ApiConstants.faceScanReport(companyId, date),
      );
      debugPrint("response.data: ${response.data}");
      return FaceScanReportModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch face scan report: $e');
    }
  }

  Future<FaceScanLogsExportModel> faceAllFaceScanLogsExport() async {
    try {
      final company = await LocalStorage.getCompany();

      if (company == null || company['id'] == null) {
        throw Exception('Company not selected');
      }

      final int companyId = company['id'];

      debugPrint('Company ID: $companyId');

      final response = await _dio.get(
        ApiConstants.faceAllFaceScanLogsExport(companyId),
      );
      debugPrint("response.data: ${response.data}");
      return FaceScanLogsExportModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch face scan logs export: $e');
    }
  }
}
