import 'package:flutter/material.dart';
import 'package:tfm_admin/widgets/FilePickerWidget.dart';

void main() {
  runApp(MaterialApp(
    home: FilePickerPage(),
  ));
}

class FilePickerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carga de archivos'),
      ),
      body: FilePickerWidget(),
    );
  }
}
