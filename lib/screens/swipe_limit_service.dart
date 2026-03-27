import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwipeLimitService {
  static const int freeSwipeLimit = 10;

  static Future<bool> canSwipe() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    final data = doc.data();

    // Premium users have unlimited swipes
    if (data?["isPremium"] == true) return true;

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month}-${today.day}";

    final swipeDoc = await FirebaseFirestore.instance
        .collection("swipe_counts")
        .doc(uid)
        .get();

    if (!swipeDoc.exists) return true;

    final swipeData = swipeDoc.data()!;
    if (swipeData["date"] != todayStr) return true;

    final count = (swipeData["count"] ?? 0) as int;
    return count < freeSwipeLimit;
  }

  static Future<int> getRemainingSwipes() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    final data = doc.data();

    if (data?["isPremium"] == true) return 999;

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month}-${today.day}";

    final swipeDoc = await FirebaseFirestore.instance
        .collection("swipe_counts")
        .doc(uid)
        .get();

    if (!swipeDoc.exists) return freeSwipeLimit;
    final swipeData = swipeDoc.data()!;
    if (swipeData["date"] != todayStr) return freeSwipeLimit;

    final count = (swipeData["count"] ?? 0) as int;
    return (freeSwipeLimit - count).clamp(0, freeSwipeLimit);
  }

  static Future<void> incrementSwipeCount() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month}-${today.day}";

    final swipeDoc = await FirebaseFirestore.instance
        .collection("swipe_counts")
        .doc(uid)
        .get();

    if (!swipeDoc.exists || swipeDoc.data()?["date"] != todayStr) {
      await FirebaseFirestore.instance
          .collection("swipe_counts")
          .doc(uid)
          .set({"date": todayStr, "count": 1});
    } else {
      await FirebaseFirestore.instance
          .collection("swipe_counts")
          .doc(uid)
          .update({"count": FieldValue.increment(1)});
    }
  }
}