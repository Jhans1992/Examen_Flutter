import 'package:cloud_firestore/cloud_firestore.dart';


FirebaseFirestore db = FirebaseFirestore.instance;

Future<List<Map<String, dynamic>>> getDataFromCollection(String collectionName) async {
  List<Map<String, dynamic>> data = [];

  try {
    CollectionReference collectionReference = db.collection(collectionName);
    QuerySnapshot querySnapshot = await collectionReference.get();

    for (var document in querySnapshot.docs) {
      data.add(document.data() as Map<String, dynamic>);
    }
  } catch (e) {
    print('Ocurrió un error al obtener los documentos de $collectionName: $e');
  }

  return data;
}
