import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_constants.dart';
import '../core/storage/local_storage.dart';
import '../models/face_scan_setting_model.dart';

class FaceScanSettingsService {
  FaceScanSettingsService(this._dio);

  final Dio _dio;

  Future<FaceScanSettingsModel> getFaceScanSettings() async {
    try {
      final company = await LocalStorage.getCompany();

      if (company == null || company['id'] == null) {
        throw Exception('Company not selected');
      }

      final int companyId = company['id'];

      debugPrint('Company ID: $companyId');

      final response = await _dio.get(
        ApiConstants.getFaceScanStatsData(companyId),
      );

      debugPrint('Face Scan Settings: ${response.data}');

      return FaceScanSettingsModel.fromJson(response.data);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch face scan setting: $e');
    }
  }
}
