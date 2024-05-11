import 'package:flutter/material.dart';
import 'package:tfm_admin/widgets/FilePickerWidget.dart';
/*
void main() {
  runApp(MaterialApp(
    home: FilePickerPage(),
  ));
}
*/
class FilePickerPage extends StatelessWidget {
  final String categoria;
  const FilePickerPage({Key? key, required this.categoria}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carga de archivos'),
      ),
      body: FilePickerWidget( categoria: categoria),
    );
  }
}
