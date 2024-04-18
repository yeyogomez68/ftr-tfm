import 'package:flutter/material.dart';
import 'package:tfm_admin/pages/CameraPage.dart'; // Import the CameraPage

class CameraButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraPage()),
      ),
      child: Icon(Icons.camera_alt),
    );
  }
}
