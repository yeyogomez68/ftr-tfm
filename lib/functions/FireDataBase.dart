import 'package:cloud_firestore/cloud_firestore.dart';

class FireDataBase {
  static Future<List<String>> getCategories() async {
    List<String> categories = [];
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      querySnapshot.docs.forEach((doc) {
        categories.add(doc.id);
      });
    } catch (e) {
      print('Error al obtener las categorías: $e');
    }
    return categories;
  }
}
