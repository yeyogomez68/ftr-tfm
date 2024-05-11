import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tfm_admin/db/DatabaseHelper.dart';
import 'package:tfm_admin/model/TreeDataModel.dart';

class FilePickerWidget extends StatefulWidget {
  final String categoria;
  const FilePickerWidget({Key? key, required this.categoria}) : super(key: key);
  @override
  _FilePickerWidgetState createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  String? _filePath;
  String? _fileContents;

  Future<void> _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();

      setState(() {
        _filePath = result.files.single.path!;
        _fileContents = contents;
      });
    }
  }

  Future<void> _saveToFileSystem() async {
    if (_fileContents != null) {
      List<String> lines = _fileContents!.split('\n');
      for (var line in lines) {
        List<String> parts = line.split(',');
        String speciesName = parts[0].trim();
        double totalHeight = double.parse(parts[1].trim());
        double x = double.parse(parts[2].trim());
        double y = double.parse(parts[3].trim());
        String fileName = parts[4].trim();

        TreeDataModel data = TreeDataModel(
          speciesName: speciesName,
          totalHeight: totalHeight,
          x: x,
          y: y,
          fileName: fileName,
        );
        await DatabaseHelper.insertData(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos guardados en la base de datos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _openFilePicker,
              child: Text('Seleccionar archivo'),
            ),
            SizedBox(height: 20),
            if (_filePath != null)
              Text('Ruta del archivo seleccionado: $_filePath'),
            SizedBox(height: 20),
            if (_fileContents != null)
              Text('Contenido del archivo:\n$_fileContents'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveToFileSystem,
              child: Text('Guardar datos en la base de datos'),
            ),
          ],
        ),
      ),
    );
  }
}
