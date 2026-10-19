import 'dart:io';
import 'package:flutter/material.dart';

class FacePreviewScreen extends StatefulWidget {
  const FacePreviewScreen({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<FacePreviewScreen> createState() => _FacePreviewScreenState();
}

class _FacePreviewScreenState extends State<FacePreviewScreen> {

  final TextEditingController nameController =
  TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void saveFace() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter employee name'),
        ),
      );
      return;
    }

    debugPrint("Employee Name: $name");
    debugPrint("Image Path: ${widget.imagePath}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Face Saved Successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Face Preview"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                ),
              )
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter Employee Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveFace,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}