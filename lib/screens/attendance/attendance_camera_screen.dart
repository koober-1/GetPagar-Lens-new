// ignore_for_file: deprecated_member_use, unnecessary_underscores, curly_braces_in_flow_control_structures, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../../core/session/employee_image_cache.dart';
import '../../core/utils/camera_input_image.dart';
import '../../service/face_recognition_service.dart';
// import '../../routing/app_routes.dart';
import '../../routing/app_router.dart';
import '../../core/storage/local_storage.dart';

enum _CardState { hidden, verifying, success, failed }

class AttendanceCameraScreen extends StatefulWidget {
  const AttendanceCameraScreen({super.key});

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen>
    with WidgetsBindingObserver {
  final _faceService = FaceRecognitionService();
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableTracking: true,
      minFaceSize: 0.18,
    ),
  );

  CameraController? _controller;
  CameraDescription? _camera;

  bool _initializing = true;
  String? _initError;
  bool _streamRunning = false;
  bool _captureLocked = false;
  int _frameTick = 0;
  int _stableFrames = 0;

  Rect? _faceRect;
  Size? _imageSize;
  bool _faceVerified = false;

  _CardState _cardState = _CardState.hidden;
  String _cardEmployeeName = '';
  String _cardTime = '';
  String _cardDirection = '';
  String _cardMessage = '';
  String _cardImageUrl = '';
  int companyId = 0;

  Position? _currentPosition;
  String _currentAddress = '';
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // IMPORTANT:
    // The user is currently on Attendance Camera.
    // Save this immediately so if the app is closed,
    // it will reopen on Attendance Camera.
    _setAttendanceCameraActive();

    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadCompany(), _loadCurrentLocation()]);

    await _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;

    if (c == null || !c.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Only stop camera stream.
      //
      // DO NOT set attendanceCamera = false.
      //
      // We want:
      // employeeScreen = true
      // attendanceCamera = true
      //
      // to remain saved if the app is closed.

      _stopStreamOnly();
    } else if (state == AppLifecycleState.resumed) {
      _startStreamIfReady();
    }
  }

  Future<void> _loadCompany() async {
    final company = await LocalStorage.getCompany();

    if (mounted) {
      setState(() {
        companyId = company?['id'] ?? '';
      });
    }
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

  Future<void> _bootstrap() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      final agreed = await _showCameraDisclosureDialog();

      if (!agreed) {
        if (!mounted) return;

        setState(() {
          _initializing = false;
          _initError = 'Camera permission required.';
        });
        return;
      }

      status = await Permission.camera.request();

      if (!status.isGranted) {
        if (!mounted) return;

        setState(() {
          _initializing = false;
          _initError = 'Camera permission is required for registration.';
        });
        return;
      }
    }
    try {
      final cameras = await availableCameras();
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
      await _startStreamIfReady();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = 'Could not start camera: $e';
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final agreed = await _showLocationDisclosureDialog();

      if (!agreed) {
        throw Exception("Location permission denied.");
      }

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. Please enable it from Settings.",
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _getCurrentAddress(double latitude, double longitude) async {
    final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isEmpty) return '';

    final p = placemarks.first;

    return [
      p.name,
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
  }

  Future<void> _loadCurrentLocation() async {
    if (_locationLoaded) return;

    final position = await _getCurrentLocation();

    final address = await _getCurrentAddress(
      position.latitude,
      position.longitude,
    );

    _currentPosition = position;
    _currentAddress = address;
    _locationLoaded = true;
  }

  Future<void> _setAttendanceCameraActive() async {
    await LocalStorage.setEmployeeScreen(true);
    await LocalStorage.setAttendanceCamera(true);

    debugPrint('==========================================');
    debugPrint('ATTENDANCE CAMERA ACTIVE');
    debugPrint('employeeScreen = true');
    debugPrint('attendanceCamera = true');
    debugPrint('==========================================');
  }

  // Future<void> _closeAttendanceCamera() async {
  //   // Stop camera first
  //   await _stopStreamOnly();

  //   // ----------------------------------------------------------
  //   // SAVE EMPLOYEE SCREEN AS ACTIVE
  //   // ----------------------------------------------------------

  //   await LocalStorage.setEmployeeScreen(true);

  //   // Attendance camera is no longer active
  //   await LocalStorage.setAttendanceCamera(false);

  //   // Save the route that should open after restart
  //   await LocalStorage.saveLastRoute(AppRoutes.employee);

  //   // Update AuthNotifier memory state
  //   authNotifier.employeeScreen = true;
  //   authNotifier.attendanceCamera = false;
  //   authNotifier.lastRoute = AppRoutes.employee;

  //   debugPrint('==========================================');
  //   debugPrint('ATTENDANCE CAMERA CLOSED');
  //   debugPrint('employeeScreen = true');
  //   debugPrint('attendanceCamera = false');
  //   debugPrint('lastRoute = ${AppRoutes.employee}');
  //   debugPrint('==========================================');
  // }

  Future<void> _startStreamIfReady() async {
    final c = _controller;
    final cam = _camera;
    if (c == null || !c.value.isInitialized || cam == null || _streamRunning)
      return;
    _stableFrames = 0;
    _captureLocked = false;
    await c.startImageStream(_onCameraImage);
    _streamRunning = true;
  }

  Future<void> _stopStreamOnly() async {
    final c = _controller;

    if (c == null || !_streamRunning) {
      return;
    }

    try {
      await c.stopImageStream();
    } catch (_) {}

    _streamRunning = false;
  }

  Future<void> _onCameraImage(CameraImage image) async {
    final c = _controller;
    final cam = _camera;
    if (!mounted || c == null || cam == null || _captureLocked) return;

    _frameTick++;
    if (_frameTick % 4 != 0) return;

    final input = CameraInputImageConverter.fromCameraImage(
      image: image,
      controller: c,
      camera: cam,
    );
    if (input == null) return;

    try {
      final faces = await _detector.processImage(input);
      if (!mounted || _captureLocked) return;

      if (faces.length == 1) {
        final box = faces.first.boundingBox;
        final ratio = box.height / image.height;
        if (mounted) {
          setState(() {
            _faceRect = box;
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });
        }
        if (ratio >= 0.22) {
          _stableFrames++;
        } else {
          _stableFrames = 0;
        }
      } else {
        _stableFrames = 0;
        if (mounted) setState(() => _faceRect = null);
      }

      if (_stableFrames >= 6) {
        _stableFrames = 0;
        await _captureAndVerify();
      }
    } catch (_) {}
  }

  Future<void> _captureAndVerify() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _captureLocked) return;

    _captureLocked = true;
    await _stopStreamOnly();
    if (!mounted) return;

    setState(() {
      _cardState = _CardState.verifying;
      _cardMessage = 'Scanning face…';
      _cardEmployeeName = '';
      _cardTime = '';
      _faceVerified = false;
    });

    String? capturedImagePath;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final shot = await c.takePicture();
      capturedImagePath = shot.path;

      await _loadCurrentLocation();

      final position = _currentPosition!;
      final address = _currentAddress;

      final identifyResult = await _faceService.identifyEmployee(
        companyId: companyId,
        imagePath: capturedImagePath,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        onProgress: (message, percent) {
          if (mounted) {
            setState(
              () =>
                  _cardMessage = '$message${percent > 0 ? ' ($percent%)' : ''}',
            );
          }
        },
      );
      if (mounted) {
        setState(() {
          _faceVerified = true;
          _cardMessage = 'Marking attendance…';
          final emp = identifyResult['employee'] as Map<String, dynamic>? ?? {};
          _cardEmployeeName =
              emp['employee_name']?.toString() ?? "employee name";
        });
      }

      final emp = identifyResult['employee'] as Map<String, dynamic>? ?? {};

      final isVerified = emp['verified'] == true;

      if (!isVerified) {
        throw Exception('Face verification failed');
      }

      // ---------------------------------------------------------
      // CHECK ATTENDANCE RESULT
      // ---------------------------------------------------------
      final attendance = identifyResult['attendance'] as Map<String, dynamic>?;

      final attendanceSuccess = attendance?['success'] == true;

      final attendanceMessage =
          attendance?['message']?.toString() ?? 'Unable to mark attendance';

      debugPrint('Face verified: $isVerified');
      debugPrint('Attendance success: $attendanceSuccess');
      debugPrint('Attendance message: $attendanceMessage');

      // ---------------------------------------------------------
      // FACE VERIFIED BUT ATTENDANCE FAILED
      // ---------------------------------------------------------
      if (!attendanceSuccess) {
        if (mounted) {
          setState(() {
            _cardState = _CardState.failed;

            _cardEmployeeName =
                emp['employee_name']?.toString() ?? 'Unknown Employee';

            _cardTime = '';

            _cardDirection = '';

            _faceVerified = false;

            _cardMessage = attendanceMessage;
          });
        }

        await Future<void>.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        setState(() {
          _cardState = _CardState.hidden;
          _faceRect = null;
        });

        _captureLocked = false;
        await _startStreamIfReady();

        return;
      }

      // ---------------------------------------------------------
      // ATTENDANCE SUCCESS
      // ---------------------------------------------------------

      final empName = emp['employee_name']?.toString() ?? 'Unknown Employee';

      final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

      String employeeImageUrl = '';

      final employeeCode = emp['employee_code']?.toString() ?? '';

      if (employeeCode.isNotEmpty) {
        employeeImageUrl = EmployeeImageCache.instance.get(employeeCode) ?? '';
      }

      final attendanceData = attendance?['data'] as Map<String, dynamic>?;

      final direction = attendanceData?['direction']?.toString() ?? '';

      if (mounted) {
        setState(() {
          _cardState = _CardState.success;

          _cardEmployeeName = empName;

          _cardTime = formattedTime;

          _cardDirection = direction;

          _cardImageUrl = employeeImageUrl;

          _cardMessage = direction == 'IN'
              ? 'Checked In!'
              : direction == 'OUT'
              ? 'Checked Out!'
              : 'Attendance Marked!';

          _faceVerified = true;
        });
      }

      await Future<void>.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      setState(() {
        _cardState = _CardState.hidden;
        _faceVerified = false;
        _faceRect = null;
      });

      _captureLocked = false;
      await _startStreamIfReady();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cardState = _CardState.failed;
        _cardMessage = e.toString().replaceFirst('Exception: ', '');
        _faceVerified = false;
      });

      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() {
        _cardState = _CardState.hidden;
        _faceRect = null;
      });
      _captureLocked = false;
      await _startStreamIfReady();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreamOnly();
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  Rect _scaledFaceRect(Rect face, Size imageSize, Size screenSize) {
    final scaleX = screenSize.width / imageSize.height;
    final scaleY = screenSize.height / imageSize.width;

    // Mirror horizontally for front camera
    final left = screenSize.width - (face.right * scaleX);
    final right = screenSize.width - (face.left * scaleX);
    final top = face.top * scaleY;
    final bottom = face.bottom * scaleY;

    return Rect.fromLTRB(
      left.clamp(0.0, screenSize.width),
      top.clamp(0.0, screenSize.height),
      right.clamp(0.0, screenSize.width),
      bottom.clamp(0.0, screenSize.height),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // User pressed Cancel
    if (shouldLogout != true) {
      return;
    }

    // ----------------------------------------------------------
    // STOP CAMERA
    // ----------------------------------------------------------

    await _stopStreamOnly();

    // ----------------------------------------------------------
    // LOGOUT
    //
    // authNotifier.logout() sets:
    //
    // loggedIn = false
    // employeeScreen = false
    // attendanceCamera = false
    //
    // and calls notifyListeners().
    //
    // GoRouter is listening to authNotifier, so the redirect
    // automatically sends the user to AppRoutes.login.
    // ----------------------------------------------------------

    await authNotifier.logout();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_initError!),
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
              Text('Starting camera…', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        // --------------------------------------------------------
        // DO NOT GO BACK.
        // SHOW LOGOUT CONFIRMATION INSTEAD.
        // --------------------------------------------------------

        await _showLogoutDialog(context);
      },

      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Mark Attendance'),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _showLogoutDialog(context);
            },
          ),
        ),

        body: Stack(
          fit: StackFit.expand,

          children: [
            CameraPreview(_controller!),

            // ======================================================
            // FACE BOUNDING BOX
            // ======================================================
            if (_faceRect != null && _imageSize != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  final scaled = _scaledFaceRect(
                    _faceRect!,
                    _imageSize!,
                    screenSize,
                  );

                  return CustomPaint(
                    painter: _FaceBoxPainter(
                      rect: scaled,
                      color: _faceVerified ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),

            // ======================================================
            // BOTTOM HINT
            // ======================================================
            if (_cardState == _CardState.hidden)
              Positioned(
                left: 16,
                right: 16,
                bottom: 42,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: const Text(
                    'Position your face in the frame. '
                    'Attendance submits automatically.',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),

                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ======================================================
            // ATTENDANCE RESULT CARD
            // ======================================================
            if (_cardState != _CardState.hidden)
              Positioned(
                left: 16,
                right: 16,
                bottom: 42,

                child: _AttendanceCard(
                  state: _cardState,
                  employeeName: _cardEmployeeName,
                  time: _cardTime,
                  direction: _cardDirection,
                  message: _cardMessage,
                  imageUrl: _cardImageUrl,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.state,
    required this.employeeName,
    required this.time,
    required this.direction,
    required this.message,
    required this.imageUrl,
  });

  final _CardState state;
  final String employeeName;
  final String time;
  final String direction;
  final String message;
  final String imageUrl;

  Widget _placeholder() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.person, color: Colors.white54),
  );

  @override
  Widget build(BuildContext context) {
    final isSuccess = state == _CardState.success;
    final isFailed = state == _CardState.failed;

    final bgColor = isFailed
        ? const Color(0xFFB71C1C)
        : isSuccess
        ? const Color(0xFF1B8A4C)
        : const Color(0xFFE65100);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (employeeName.isNotEmpty) ...[
                  Text(
                    'EMPLOYEE : $employeeName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (time.isNotEmpty) ...[
                  Text(
                    'TIME : $time',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    if (isSuccess) ...[
                      Icon(
                        direction == 'In' ? Icons.login : Icons.logout,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                    ] else if (!isFailed) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Employee photo thumbnail
          if (isSuccess && imageUrl.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : Image.file(
                      File(imageUrl),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaceBoxPainter extends CustomPainter {
  final Rect rect;
  final Color color;
  _FaceBoxPainter({required this.rect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_FaceBoxPainter old) =>
      old.rect != rect || old.color != color;
}
