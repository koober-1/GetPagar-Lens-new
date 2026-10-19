// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../core/notifiers/employee_list_refresh_notifier.dart';
import '../../core/session/current_employee.dart';
import '../../core/session/employee_image_cache.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../models/employee_model.dart';
import './camera_dialog.dart';
import '../../service/employee_registration_cache.dart';
import '../../service/face_recognition_service.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key, required this.employee});
  final EmployeeModel employee;

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final _face = FaceRecognitionService();
  bool _busy = false;
  String? _localImagePath; // shows captured photo immediately on profile

  // Location — fetched silently, ready for when backend needs it
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchLocationSilently();
  }

  Future<bool> _showLocationDisclosureDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Location Access Disclosure"),
          content: const Text(
            "GetPagar Lens by GetPagar collects your location information "
            "to verify workplace location and improve attendance accuracy.\n\n"
            "Location data is used only for employee verification purposes.\n\n"
            "By continuing, you agree to allow location access.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Decline"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                "Agree & Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _fetchLocationSilently() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final agreed = await _showLocationDisclosureDialog();

        if (!agreed) {
          return;
        }

        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
    }
  }

  Future<File> _compressImage(String path) async {
    final dir = await getTemporaryDirectory();
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      '${dir.path}/compressed_profile.jpg',
      quality: 60,
    );
    if (result == null) throw Exception('Image compression failed');
    return File(result.path);
  }

  Future<bool> _showDataDisclosureDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Privacy Disclosure"),
          content: const Text(
            "GetPagar Lens by GetPagar uses your camera to capture "
            "employee images for face recognition and identity verification.\n\n"
            "The camera is used only for employee attendance and verification "
            "purposes.\n\n"
            "By continuing, you agree to allow camera access.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Decline"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                "Agree & Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _updateImage() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      final agreed = await _showDataDisclosureDialog();

      if (!agreed) {
        return;
      }

      status = await Permission.camera.request();

      if (!status.isGranted) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission is required")),
        );
        return;
      }
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open camera: $e')));
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    XFile? shot;

    try {
      shot = await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CameraDialog(controller: controller!),
      );
    } finally {
      if (controller.value.isInitialized) {
        await controller.dispose();
      }
    }

    if (shot == null || !mounted) return;

    final image = shot;
    // Show captured photo immediately
    setState(() => _localImagePath = image.path);

    setState(() => _busy = true);

    try {
      final compressed = await _compressImage(image.path);

      await _face.registerFace(
        employeeId: widget.employee.id,
        companyId: widget.employee.companyId.toString(),
        branchId: widget.employee.branchId.toString(),
        employeeName: widget.employee.employeeName,
        employeeCode: widget.employee.employeeCode,
        imagePath: compressed.path,
        latitude: _latitude,
        longitude: _longitude,
      );

      EmployeeImageCache.instance.set(widget.employee.employeeCode, image.path);

      EmployeeListRefreshNotifier.instance.requestRefresh();

      await EmployeeRegistrationCache.instance.addRegisteredCode(
        widget.employee.employeeCode,
      );

      // 👇 Update current employee session with local file path
      // so the list tile reflects the new image immediately
      CurrentEmployee.updateImage(shot.path);

      // 👇 Trigger list refresh
      EmployeeListRefreshNotifier.instance.requestRefresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face image updated successfully ✅')),
      );
    } catch (e) {
      if (mounted) setState(() => _localImagePath = null);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employee;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.appBar,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: EmployeeAvatar(
              imageField: e.image,
              employeeCode: e.employeeCode,
              localImagePath: _localImagePath,
              size: 120,
              radius: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            e.employeeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.departmentName,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: 'Employee code', value: e.employeeCode),
          const SizedBox(height: 40),
          FilledButton.icon(
            onPressed: _busy ? null : _updateImage,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_busy ? 'Uploading…' : 'Update face image'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
