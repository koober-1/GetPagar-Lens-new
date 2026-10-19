// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/api/api_constants.dart';
import '../core/api/dio_client.dart';
import '../core/storage/local_storage.dart';
import '../routing/app_router.dart'; // <-- global authNotifier
import '../models/employee_model.dart';

class EmployeeService {
  Future<List<EmployeeModel>> getAllEmployees() async {
    try {
      final company = await LocalStorage.getCompany();

      // ============================================================
      // COMPANY NOT SELECTED
      // ============================================================

      if (company == null || company['id'] == null) {
        debugPrint('Exception: Company not selected');

        // IMPORTANT:
        // Use the SAME AuthNotifier instance used by GoRouter.
        await authNotifier.resetToLogin();

        return [];
      }

      final int companyId = company['id'];

      debugPrint('Company ID: $companyId');

      // ============================================================
      // GET EMPLOYEES
      // ============================================================

      final response = await DioClient.dio.get(
        ApiConstants.getAllEmployees(companyId),
      );

      final List employees = response.data['data'] ?? [];

      return employees
          .map((employeeJson) => EmployeeModel.fromJson(employeeJson))
          .toList();
    }
    // ============================================================
    // DIO ERROR
    // ============================================================
    on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch employees',
      );
    }
    // ============================================================
    // OTHER ERROR
    // ============================================================
    catch (e) {
      debugPrint('EmployeeService error: $e');

      throw Exception(e.toString());
    }
  }
}
