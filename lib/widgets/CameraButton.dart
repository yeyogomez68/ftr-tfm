import 'package:flutter/material.dart';
import 'package:tfm_admin/pages/ImagePickerPage.dart'; // Import the CameraPage

class CameraButton extends StatelessWidget {
  const CameraButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePickerPage())),
      child: const Icon(Icons.camera_alt),
    );
  }
}
