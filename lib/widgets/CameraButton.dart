import 'package:flutter/material.dart';
import 'package:tfm_admin/pages/CameraPage.dart'; // Import the CameraPage

class CameraButton extends StatelessWidget {
  const CameraButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraPage()),
      ),
      child: const Icon(Icons.camera_alt),
    );
  }
}
