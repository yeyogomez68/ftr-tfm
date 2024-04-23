import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tfm_admin/functions/ImageUtils.dart';

class ImagePickerPage extends StatefulWidget {
  @override
  _ImagePickerPageState createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _imageFile;
  String _selectedCategory = 'Arbol 1';
  List<String> _categories = ['Arbol 1', 'Arbol 2', 'Arbol 3'];

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final compressedFile = await ImageUtils.compressImage(File(pickedFile.path));

      setState(() {
        _imageFile = compressedFile;
      });
    } else {
      print('Imagen no seleccionada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selección o toma de imagen'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: _imageFile == null
                  ? Text('Selecciona una imagen.')
                  : Image.file(_imageFile!),
            ),
          ),
          Offstage(
            offstage: _imageFile == null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                hint: const Text('Seleccione la Categoría'),
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
            ),
          ),
          Offstage(
            offstage: _imageFile == null,
            child: Padding(padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  
                },
                child: const Text('Subir al servidor'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Offstage(
            offstage: _imageFile == null,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _imageFile = null;
                });
              },
              tooltip: 'Eliminar imagen',
              child: Icon(Icons.delete),
            ),
          ),
          Offstage(
            offstage: _imageFile != null,
            child: FloatingActionButton(
              onPressed: () => _getImage(ImageSource.gallery),
              tooltip: 'Selecciona una imagen de la galería',
              child: Icon(Icons.photo_library),
            ),
          ),
          Offstage(
            offstage: _imageFile != null,
            child: SizedBox(height: 16)
            ),
          Offstage(
            offstage: _imageFile != null,
            child: FloatingActionButton(
              onPressed: () => _getImage(ImageSource.camera),
              tooltip: 'Toma una foto con tu camara',
              child: Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
