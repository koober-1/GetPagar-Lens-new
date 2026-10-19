import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/notifiers/employee_list_refresh_notifier.dart';
import '../../models/employee_model.dart';
import '../../routing/app_routes.dart';
import '../../service/employee_registration_cache.dart';
import '../../service/face_recognition_service.dart';

class RegistrationCameraScreen extends StatefulWidget {
  const RegistrationCameraScreen({super.key, required this.employee});

  final EmployeeModel employee;

  @override
  State<RegistrationCameraScreen> createState() =>
      _RegistrationCameraScreenState();
}

class _RegistrationCameraScreenState extends State<RegistrationCameraScreen> {
  CameraController? _controller;
  final _faceService = FaceRecognitionService();

  bool _initializing = true;
  bool _uploading = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  //Compress image to avoid timeout error
  Future<File> _compressImage(String path) async {
    final dir = await getTemporaryDirectory();

    final targetPath = '${dir.path}/compressed.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 60,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  Future<bool> _showCameraDisclosureDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Camera Access Disclosure"),
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

  Future<void> _setup() async {
    final cameraDisclosure = await _showCameraDisclosureDialog();

    if (!cameraDisclosure) {
      setState(() {
        _initializing = false;
        _initError = 'Camera permission required.';
      });
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _initializing = false;
        _initError = 'Camera permission is required for registration.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = 'Could not start camera: $e';
      });
    }
  }

  Future<void> _captureAndRegister() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _uploading) {
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      // TAKE PICTURE
      final shot = await controller.takePicture();

      // ORIGINAL FILE
      final originalFile = File(shot.path);

      debugPrint('Original Size: ${originalFile.lengthSync()}');

      // COMPRESS IMAGE
      final compressedImage = await _compressImage(shot.path);

      debugPrint('Compressed Size: ${compressedImage.lengthSync()}');

      // REGISTER FACE
      await _faceService.registerFace(
        employeeId: widget.employee.id,
        companyId: widget.employee.companyId.toString(),
        branchId: widget.employee.branchId.toString(),
        employeeName: widget.employee.employeeName,
        employeeCode: widget.employee.employeeCode,
        imagePath: compressedImage.path,
      );

      // CACHE
      await EmployeeRegistrationCache.instance.addRegisteredCode(
        widget.employee.employeeCode,
      );

      // REFRESH LIST
      EmployeeListRefreshNotifier.instance.requestRefresh();

      if (!mounted) return;

      // SUCCESS SCREEN
      context.pushReplacement(
        AppRoutes.registrationSuccess,
        extra: widget.employee,
      );
    } catch (e) {
      if (!mounted) return;

      await showDialog<void>(
        context: context,

        builder: (ctx) => AlertDialog(
          title: const Text('Registration failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_initError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (_initializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Opening camera…', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Capture face'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_uploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          if (!_uploading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: GestureDetector(
                  onTap: _captureAndRegister,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
