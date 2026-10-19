// ignore_for_file: unnecessary_underscores

import 'dart:io';
import 'package:flutter/material.dart';
import '../session/employee_image_cache.dart';
import '../utils/face_media_url.dart';

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
    super.key,
    required this.imageField,
    required this.employeeCode,
    this.localImagePath,
    this.size = 64,
    this.radius = 8,
  });

  final String imageField;
  final String employeeCode;
  final String? localImagePath;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Priority: explicit local path → cached local path → network URL
    final cachedPath = EmployeeImageCache.instance.get(employeeCode);
    final effectiveLocalPath = localImagePath ?? cachedPath;
    final networkUrl = FaceMediaUrl.avatarUrl(imageField);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFEFEFEF),
        child: effectiveLocalPath != null
            ? Image.file(
          File(effectiveLocalPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, color: Color(0xFF999999)),
        )
            : networkUrl != null
            ? Image.network(
          networkUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, color: Color(0xFF999999)),
        )
            : const Icon(Icons.person, color: Color(0xFF999999)),
      ),
    );
  }
}