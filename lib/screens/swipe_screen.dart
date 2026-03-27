import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'match_list_screen.dart';
import 'match_popup_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  List<SwipeItem> swipeItems = [];
  MatchEngine? matchEngine;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection("users").get();

      for (var doc in usersSnap.docs) {
        // ✅ Skip current user
        if (doc.id == currentUser.uid) continue;

        // ✅ Skip already swiped users
        final liked = await FirebaseFirestore.instance
            .collection("swipes")
            .doc(currentUser.uid)
            .collection("liked")
            .doc(doc.id)
            .get();

        final passed = await FirebaseFirestore.instance
            .collection("swipes")
            .doc(currentUser.uid)
            .collection("passed")
            .doc(doc.id)
            .get();

        if (liked.exists || passed.exists) continue;

        final data = doc.data();

        swipeItems.add(
          SwipeItem(
            content: data,
            likeAction: () async {
              final otherUserId = doc.id;

              try {
                // ✅ Save like
                await FirebaseFirestore.instance
                    .collection("swipes")
                    .doc(currentUser.uid)
                    .collection("liked")
                    .doc(otherUserId)
                    .set({"timestamp": FieldValue.serverTimestamp()});

                // ✅ Check if other user already liked you
                final otherLike = await FirebaseFirestore.instance
                    .collection("swipes")
                    .doc(otherUserId)
                    .collection("liked")
                    .doc(currentUser.uid)
                    .get();

                if (otherLike.exists) {
                  // 💘 IT'S A MATCH!
                  await FirebaseFirestore.instance
                      .collection("matches")
                      .doc(currentUser.uid)
                      .collection("users")
                      .doc(otherUserId)
                      .set({"matchedAt": FieldValue.serverTimestamp()});

                  await FirebaseFirestore.instance
                      .collection("matches")
                      .doc(otherUserId)
                      .collection("users")
                      .doc(currentUser.uid)
                      .set({"matchedAt": FieldValue.serverTimestamp()});

                  // ✅ Safe null check on photoUrl before showing popup
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchPopupScreen(
                        name: data["name"] ?? "Someone",
                        photoUrl: data["photoUrl"] ?? "",
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Something went wrong: $e")),
                );
              }
            },

            nopeAction: () {
              FirebaseFirestore.instance
                  .collection("swipes")
                  .doc(currentUser.uid)
                  .collection("passed")
                  .doc(doc.id)
                  .set({"timestamp": FieldValue.serverTimestamp()});
            },
          ),
        );
      }

      setState(() {
        matchEngine = MatchEngine(swipeItems: swipeItems);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load users: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (swipeItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("SparkMate"),
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MatchListScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied,
                  size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No more profiles nearby 😴",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SparkMate"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MatchListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SwipeCards(
        matchEngine: matchEngine!,
        onStackFinished: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No more profiles 🎉")),
          );
        },
        itemBuilder: (context, index) {
          final user = swipeItems[index].content as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Safe null check on photoUrl
                if (user["photoUrl"] != null && user["photoUrl"] != "")
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: NetworkImage(user["photoUrl"]),
                  )
                else
                  const CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                const SizedBox(height: 20),
                Text(
                  "${user["name"] ?? "Unknown"}, ${user["age"] ?? ""}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user["gender"] ?? "",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    user["bio"] ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}