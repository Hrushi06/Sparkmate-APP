import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs;
  }

  Stream<QuerySnapshot> getUserStream(String uid) =>
      _db.collection('users').snapshots();
}