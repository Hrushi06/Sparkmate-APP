import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MatchListScreen extends StatelessWidget {
  MatchListScreen({super.key});

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Matches 💘"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("matches")
            .doc(currentUser.uid)
            .collection("users")
            .orderBy("matchedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No matches yet 💔",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Keep swiping to find your spark!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final matchUserId = matches[index].id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(matchUserId)
                    .get(),
                builder: (context, userSnap) {
                  // ✅ Show shimmer placeholder while loading
                  if (!userSnap.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text("Loading..."),
                    );
                  }

                  // ✅ Safe null check on user data
                  if (!userSnap.data!.exists) return const SizedBox();

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.pink.shade100,
                        // ✅ Safe null check on photoUrl
                        backgroundImage:
                            userData["photoUrl"] != null &&
                                    userData["photoUrl"] != ""
                                ? NetworkImage(userData["photoUrl"])
                                : null,
                        child: userData["photoUrl"] == null ||
                                userData["photoUrl"] == ""
                            ? const Icon(Icons.person, color: Colors.pink)
                            : null,
                      ),
                      title: Text(
                        userData["name"] ?? "User",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${userData["age"] ?? ""} • ${userData["gender"] ?? ""}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.pink,
                      ),
                      // ✅ Open chat screen on tap
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: matchUserId,
                              otherUserName: userData["name"] ?? "User",
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}