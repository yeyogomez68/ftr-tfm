import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib; // Use an alias for clarity
import 'package:image_picker/image_picker.dart'; // Import the image_picker package

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late File _imageFile;
  late String _selectedTreeType;
  final _storage = FirebaseStorage.instance;

  Future<void> _pickImage() async {
    // Create an instance of the ImagePicker class
    final picker = ImagePicker();

    // Pick an image from the camera
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || _selectedTreeType == null) {
      return;
    }

    // Decode the image file into a Dart image object
    final img = imgLib.decodeImage(_imageFile.readAsBytesSync());

    // Resize the image to a suitable size for uploading
    final resizedImg = imgLib.copyResize(img!, width: 640, height: 480);

    // Encode the resized image as a JPEG file
    final data = imgLib.encodeJpg(resizedImg, quality: 80);

    // Create a reference to the storage location for the image
    final reference = _storage.ref().child('images/${_imageFile.path.split('/').last}');

    // Upload the image data to Firebase Storage
    final uploadTask = reference.putData(data);

    // Get the download URL for the uploaded image
    final url = await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());

    print('Image uploaded to: $url');

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subida completada'),
        content: const Text('¿Deseas confirmar la subida de la imagen?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Navigator.of(context).pop();
              // Implement your confirmation action here
            },
          ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar foto y subir a Firebase'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (_imageFile != null)
            Image.file(_imageFile, width: 300, height: 300)
          else
            const Text('No se ha seleccionado ninguna imagen'),
          DropdownButton<String>(
            value: _selectedTreeType,
            hint: const Text('Seleccionar tipo de árbol'),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'almendro',
                child: Text('Almendro'),
              ),
              DropdownMenuItem<String>(
                value: 'manzano',
                child: Text('Manzano'),
              ),
              // Add more tree types as needed
            ],
            onChanged: (value) {
              setState(() {
                _selectedTreeType = value!;
              });
            },
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Tomar foto'),
          ),
          ElevatedButton(
            onPressed: _uploadImage,
            child: Text('Subir imagen'),
          ),
        ],
      ),
    );
  }
}
