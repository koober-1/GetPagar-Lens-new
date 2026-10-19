import '../api/api_constants.dart';

/// Builds a URL Flutter can load for face images stored by your localhost backend.
///
/// Handles Windows-style `\\` paths from JSON and avoids double slashes when joining.
class FaceMediaUrl {
  FaceMediaUrl._();

  static String? avatarUrl(String? relativeOrAbsoluteFromApi) {
    final raw = relativeOrAbsoluteFromApi?.trim() ?? '';
    if (raw.isEmpty) return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    var path = raw.replaceAll(r'\', '/');
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final origin = ApiConstants.faceApiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$origin$path';
  }
}