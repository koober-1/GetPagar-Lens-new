/// Turns Node/Express/Sequelize/Joi style JSON errors into a single readable string.
String faceApiErrorMessage(dynamic data) {
  if (data == null) return 'Request failed (empty response)';
  if (data is String) {
    final t = data.trim();
    return t.isEmpty ? 'Request failed' : t;
  }
  if (data is! Map) return data.toString();

  final map = Map<String, dynamic>.from(data);

  final details = _collectValidationDetails(map);
  final headline = _headlineMessage(map);

  if (headline != null && details != null) {
    return '$headline — $details';
  }
  if (details != null) return details;
  if (headline != null) return headline;

  return map.toString();
}

String? _headlineMessage(Map<String, dynamic> map) {
  for (final key in ['message', 'error', 'msg', 'statusText']) {
    final v = map[key];
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
  }
  return null;
}

String? _collectValidationDetails(Map<String, dynamic> map) {
  final parts = <String>[];

  final errors = map['errors'];
  if (errors is List) {
    for (final e in errors) {
      if (e is String) {
        parts.add(e);
      } else if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        parts.add(
          (m['msg'] ?? m['message'] ?? m['error'] ?? m['path'] ?? e).toString(),
        );
      } else {
        parts.add(e.toString());
      }
    }
  }

  if (errors is Map) {
    errors.forEach((key, value) {
      if (value is List) {
        parts.addAll(value.map((x) => x.toString()));
      } else {
        parts.add('$key: $value');
      }
    });
  }

  final details = map['details'];
  if (details is List) {
    for (final d in details) {
      if (d is Map) {
        final dm = Map<String, dynamic>.from(d);
        parts.add((dm['message'] ?? dm['msg'] ?? d).toString());
      } else {
        parts.add(d.toString());
      }
    }
  }

  if (parts.isEmpty) return null;
  return parts.where((s) => s.trim().isNotEmpty).join('; ');
}
