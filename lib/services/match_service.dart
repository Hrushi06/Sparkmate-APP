import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveLike(String fromUid, String toUid) =>
      _db
          .collection('swipes')
          .doc(fromUid)
          .collection('liked')
          .doc(toUid)
          .set({'timestamp': FieldValue.serverTimestamp()});

  Future<void> savePass(String fromUid, String toUid) =>
      _db
          .collection('swipes')
          .doc(fromUid)
          .collection('passed')
          .doc(toUid)
          .set({'timestamp': FieldValue.serverTimestamp()});

  Future<bool> isLikedBack(String fromUid, String byUid) async {
    final doc = await _db
        .collection('swipes')
        .doc(byUid)
        .collection('liked')
        .doc(fromUid)
        .get();
    return doc.exists;
  }

  Future<void> createMatch(String uid1, String uid2) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('matches').doc(uid1).collection('users').doc(uid2),
      {'matchedAt': FieldValue.serverTimestamp()},
    );

    batch.set(
      _db.collection('matches').doc(uid2).collection('users').doc(uid1),
      {'matchedAt': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }

  Stream<QuerySnapshot> getMatchesStream(String uid) =>
      _db
          .collection('matches')
          .doc(uid)
          .collection('users')
          .orderBy('matchedAt', descending: true)
          .snapshots();
}