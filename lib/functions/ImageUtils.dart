import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static Future<File> compressImage(File imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    final image = img.decodeImage(imageFile.readAsBytesSync());
    final compressedImage = img.encodeJpg(image!, quality: 70);

    final compressedFile = File('$tempPath/image.jpg');
    await compressedFile.writeAsBytes(compressedImage);

    return compressedFile;
  }
}
