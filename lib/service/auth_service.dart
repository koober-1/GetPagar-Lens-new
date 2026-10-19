import 'package:dio/dio.dart';
import '../core/api/api_constants.dart';
import '../core/api/dio_client.dart';

class AuthService {
  final Dio _dio = DioClient.dio;

  // SEND OTP
  Future<Response> sendOtp({required String mobile}) async {
    return await _dio.post(ApiConstants.sendOtp, data: {"mobile": mobile});
  }

  // VERIFY OTP
  Future<Response> verifyOtp({required String mobile, required String otp,}) async {
    return await _dio.post(
      ApiConstants.verifyOtp,
      data: {"mobile": mobile, "otp": otp},
    );
  }
}
