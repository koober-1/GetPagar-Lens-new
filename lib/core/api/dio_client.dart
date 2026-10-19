import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../storage/local_storage.dart';
import 'api_constants.dart';

class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConstants.hrmBaseUrl,
            connectTimeout: const Duration(seconds: 180),
            receiveTimeout: const Duration(seconds: 180),
            sendTimeout: const Duration(seconds: 180),
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await LocalStorage.getToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              return handler.next(options);
            },
          ),
        )
        ..interceptors.add(
          PrettyDioLogger(requestBody: true, responseBody: true),
        );
}
