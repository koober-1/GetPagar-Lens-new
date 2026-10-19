// ignore_for_file: library_prefixes, use_null_aware_elements, avoid_print

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/api/api_constants.dart';
import '../core/api/dio_client.dart';

class FaceRecognitionService {
  final Dio _hrmDio = DioClient.dio;

  final Dio _faceApiDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.faceApiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json'},
    ),
  );

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'];
    return e.message ?? 'Something went wrong';
  }

  // REGISTER / UPDATE FACE IMAGE
  Future<void> registerFace({
    required int employeeId,
    required String companyId,
    required String branchId,
    required String employeeName,
    required String employeeCode,
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final formData = FormData.fromMap({
        'company_id': companyId,
        'branch_id': branchId,
        'employee_name': employeeName,
        'employee_code': employeeCode,
        'image': await MultipartFile.fromFile(imagePath),
        // 👇 Uncomment and rename fields once backend team confirms
        // if (latitude != null) 'latitude': latitude,
        // if (longitude != null) 'longitude': longitude,
      });

      final response = await _hrmDio.put(
        ApiConstants.updateEmployeeFace(employeeId),
        data: formData,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update face');
      }
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // IDENTIFY EMPLOYEE via socket
  Future<Map<String, dynamic>> identifyEmployee({
    required int companyId,
    required String imagePath,
    double? latitude,
    double? longitude,
    String? address,
    void Function(String message, int percent)? onProgress,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    IO.Socket? socket;

    try {
      print('==============================================');
      print('START FACE IDENTIFICATION');
      print('==============================================');
      print('Socket URL: ${ApiConstants.socketUrl}');
      print('Company ID: $companyId');
      print('Image: $imagePath');
      print('==============================================');

      socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .enableReconnection()
            .build(),
      );

      final connectionCompleter = Completer<String>();

      socket.onConnect((_) {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.complete(socket!.id ?? '');
        }
      });

      socket.onConnectError((err) {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(
            Exception('Socket connection failed: $err'),
          );
        }
      });

      socket.connect();

      final socketId = await connectionCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Socket connection timed out'),
      );

      socket.on('face_identification_progress', (data) {
        if (onProgress != null) {
          final message = data['message']?.toString() ?? 'Processing';
          final percent = (double.tryParse(data['progress'].toString()) ?? 0)
              .toInt();
          onProgress(message, percent);
        }
      });

      socket.on('face_identification_result', (data) {
        if (!completer.isCompleted) {
          if (data['success'] == true && data['matched'] == true) {
            completer.complete(data);
          } else {
            completer.completeError(
              Exception(data['message'] ?? 'Employee not found'),
            );
          }
        }
      });

      final formData = FormData.fromMap({
        'socket_id': socketId,
        'image': await MultipartFile.fromFile(imagePath),

        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      });

      final response = await _faceApiDio.post(
        ApiConstants.identifyEmployee(companyId),
        data: formData,
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to start identification',
        );
      }

      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Identification timed out'),
      );

      return result;
    } finally {
      socket?.dispose();
    }
  }

  // MARK ATTENDANCE
  Future<Map<String, dynamic>> markAttendance({
    required int companyId,
    required String employeeCode,
    required String employeeName,
    required String imagePath,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final formData = FormData.fromMap({
        'company_id': companyId,
        'employee_code': employeeCode,
        'employee_name': employeeName,
        'image': await MultipartFile.fromFile(imagePath),

        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      });
      final response = await _hrmDio.post(
        ApiConstants.markAttendance,
        data: formData,
      );
      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to mark attendance',
        );
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // DELETE FACE
  Future<void> deleteRegistration(String employeeCode) async {
    try {
      final response = await _faceApiDio.delete(
        '${ApiConstants.deleteEmployeeFace}/$employeeCode',
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message']);
      }
    } on DioException catch (e) {
      throw Exception(_parseError(e));
    }
  }
}
