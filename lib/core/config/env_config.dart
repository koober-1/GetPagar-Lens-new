import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads environment-specific values from `.env` at app startup.
class EnvConfig {
  EnvConfig._();

  static late final String hrmBaseUrl;
  static late final String faceApiBaseUrl;
  static late final String socketUrl;
  static late final String hrmApiToken;
  static late final int defaultCompanyId;

  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);

    hrmBaseUrl = _require('HRM_BASE_URL');
    faceApiBaseUrl = _require('FACE_API_BASE_URL');
    socketUrl = _require('SOCKET_URL');
    hrmApiToken = _require('HRM_API_TOKEN');
    defaultCompanyId = int.parse(_require('DEFAULT_COMPANY_ID'));
  }

  static String _require(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing or empty $key in .env. Copy .env.example to .env and set values.',
      );
    }
    return value;
  }
}
