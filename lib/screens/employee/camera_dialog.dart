// ignore_for_file: use_super_parameters, deprecated_member_use, unnecessary_import, unused_import, avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraDialog extends StatefulWidget {
  const CameraDialog({Key? key, required this.controller}) : super(key: key);

  final CameraController controller;

  @override
  State<CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<CameraDialog> {
  late FaceDetector _faceDetector;

  bool _busy = false;
  bool _captured = false;

  Face? _lastFace;

  int _countDown = 5;

  Timer? _timer;

  String _message = "Align your face";

  bool _faceDetected = false;
  bool _faceStable = false;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _startStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _faceDetector.close();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;

    _countDown = 5;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      if (_countDown == 1) {
        timer.cancel();
        _timer = null;

        await _capture();

        return;
      }

      setState(() {
        _countDown--;
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;

    if (mounted) {
      setState(() {
        _countDown = 5;
      });
    }
  }

  bool _isStable(Face current) {
    if (_lastFace == null) {
      _lastFace = current;
      return false;
    }

    final dx =
        (_lastFace!.boundingBox.center.dx - current.boundingBox.center.dx)
            .abs();

    final dy =
        (_lastFace!.boundingBox.center.dy - current.boundingBox.center.dy)
            .abs();

    _lastFace = current;

    return dx < 8 && dy < 8;
  }

  Future<void> _closeDialog([XFile? image]) async {
    _captured = true;

    try {
      if (widget.controller.value.isStreamingImages) {
        await widget.controller.stopImageStream();
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop(image);
    }
  }

  Future<void> _capture() async {
    if (_captured) return;

    try {
      final image = await widget.controller.takePicture();

      if (!mounted) return;

      await _closeDialog(image);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _startStream() async {
    await widget.controller.startImageStream((image) async {
      if (!mounted) return;
      if (_busy || _captured) return;

      if (!widget.controller.value.isInitialized) return;
      _busy = true;
      print("Starting Image Stream...");

      try {
        final inputImage = await _convertCameraImage(image);

        final faces = await _faceDetector.processImage(inputImage);

        print("Faces detected: ${faces.length}");

        if (faces.isEmpty) {
          _faceDetected = false;
          _faceStable = false;

          _message = "No face detected";

          _resetTimer();

          if (mounted) setState(() {});

          _busy = false;
          return;
        }

        final face = faces.first;

        final faceArea = face.boundingBox.width * face.boundingBox.height;

        final imageArea = image.width * image.height;

        final facePercent = (faceArea / imageArea) * 100;

        print("Face Size: ${facePercent.toStringAsFixed(1)}%");

        _faceDetected = true;

        final stable = _isStable(face);

        _faceStable = stable;

        if (stable) {
          _message = "Hold Still";

          _startTimer();
        } else {
          _message = "Don't move";

          _resetTimer();
        }

        if (mounted) setState(() {});
      } catch (e, stack) {
        debugPrint("========== MLKIT ERROR ==========");
        debugPrint(e.toString());
        debugPrint(stack.toString());
      }

      _busy = false;
    });
  }

  // ----------------------------------------------------------------------
  // PART 2
  // CameraImage -> InputImage Converter (ML Kit)
  // ----------------------------------------------------------------------

  Future<InputImage> _convertCameraImage(CameraImage image) async {
    final Uint8List bytes = image.planes.first.bytes;
    print("Frame received");

    final rotation =
        InputImageRotationValue.fromRawValue(
          widget.controller.description.sensorOrientation,
        ) ??
        InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Color get _statusColor {
    if (!_faceDetected) {
      return Colors.red;
    }

    if (_faceStable) {
      return Colors.green;
    }

    return Colors.orange;
  }

  String get _statusText {
    if (!_faceDetected) {
      return "No Face";
    }

    if (_faceStable) {
      return "Hold Still";
    }

    return "Don't Move";
  }

  double get _progress {
    return (5 - _countDown) / 5;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ===========================
          // Camera Preview
          // ===========================
          if (widget.controller.value.isInitialized)
            CameraPreview(widget.controller)
          else
            const ColoredBox(color: Colors.black),

          // ===========================
          // Dark Overlay
          // ===========================
          Container(color: Colors.black.withOpacity(0.25)),

          // ===========================
          // Face Guide
          // ===========================
          Center(
            child: Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _statusColor, width: 4),
              ),
            ),
          ),

          // ===========================
          // Title
          // ===========================
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Face Verification",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===========================
          // Countdown
          // ===========================
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black54,
                      border: Border.all(color: _statusColor, width: 5),
                    ),
                    child: Center(
                      child: Text(
                        "$_countDown",
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: _progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(_statusColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Keep your face inside the frame\nand do not move.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          // ===========================
          // Close Button
          // ===========================
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () async {
                    await _closeDialog();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
