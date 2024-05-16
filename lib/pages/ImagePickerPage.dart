import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tfm_admin/functions/FireDataBase.dart';
import 'package:tfm_admin/functions/ImageUtils.dart';
import 'package:tfm_admin/functions/StorageUtils.dart';

class ImagePickerPage extends StatefulWidget {
  final String categoria;
  const ImagePickerPage({Key? key, required this.categoria}) : super(key: key);
  @override
  _ImagePickerPageState createState() =>
      _ImagePickerPageState(categoria: categoria);
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _imageFile;
  String _selectedCategory = '';
  List<String> _categories = [];
  final String categoria;
  _ImagePickerPageState({required this.categoria});

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    List<String> categories = await FireDataBase.getCategories();
    //filter categories by the category passed as parameter
    if (categoria.isNotEmpty) {
      categories = categories.where((element) => element == categoria).toList();
    }
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) {
        _selectedCategory = categories[0];
      }
    });
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final compressedFile =
          await ImageUtils.compressImage(File(pickedFile.path));

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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // Evita que se cierre al tocar afuera
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                        elevation: 0.0,
                        content: Container(
                          height: 100.0,
                          color: Colors.transparent,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    },
                  );
                  final downloadUrl = await StorageUtils().uploadFile(
                      _imageFile!, '$_selectedCategory/${DateTime.now()}.jpg');
                  Navigator.of(context).pop();
                  if (downloadUrl.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Imagen subida con éxito'),
                        duration: Duration(seconds: 5),
                      ),
                    );
                    setState(() {
                      _imageFile = null;
                    });
                  } else {
                    print('Error al subir la imagen');
                  }
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
          Offstage(offstage: _imageFile != null, child: SizedBox(height: 16)),
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
