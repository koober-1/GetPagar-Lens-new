// lib/service/welcome_service.dart

import 'package:dio/dio.dart';

import '../core/api/api_constants.dart';
import '../core/api/dio_client.dart';

class WelcomeService {
  final Dio _dio = DioClient.dio;

  String _parseError(DioException e) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return e.message ?? 'Something went wrong';
  }

  /// Fetch all companies for the admin mobile number
  Future<Response> getAdminCompanies({required String mobile}) async {
    try {
      final response = await _dio.get(ApiConstants.adminCompanies(mobile));

      return response;
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }
}
