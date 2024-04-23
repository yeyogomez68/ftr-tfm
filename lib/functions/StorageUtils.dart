import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageUtils {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String storagePath) async {
    try {
      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot storageSnapshot =
          await uploadTask.whenComplete(() => null);
      final String downloadUrl = await storageSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error al cargar el archivo: $e');
      return '';
    }
  }
}
