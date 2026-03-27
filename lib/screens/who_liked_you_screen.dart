import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WhoLikedYouScreen extends StatelessWidget {
  WhoLikedYouScreen({super.key});

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Who Liked You 👀"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection("swipes")
            .doc(currentUser.uid)
            .collection("liked")
            .get(),
        builder: (context, myLikesSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("swipes")
                .get()
                .asStream(),
            builder: (context, allSwipesSnap) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getLikedByUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.pinkAccent));
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 80,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            "No likes yet",
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Keep swiping to get noticed!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(user);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getLikedByUsers() async {
    final allUsers = await FirebaseFirestore.instance
        .collection("swipes")
        .get();

    List<Map<String, dynamic>> likedByUsers = [];

    for (var userSwipeDoc in allUsers.docs) {
      if (userSwipeDoc.id == currentUser.uid) continue;

      final likedMe = await FirebaseFirestore.instance
          .collection("swipes")
          .doc(userSwipeDoc.id)
          .collection("liked")
          .doc(currentUser.uid)
          .get();

      if (likedMe.exists) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(userSwipeDoc.id)
            .get();
        if (userDoc.exists) {
          likedByUsers.add({
            ...userDoc.data()!,
            "uid": userSwipeDoc.id,
          });
        }
      }
    }

    return likedByUsers;
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            user["photoUrl"] != null
                ? CachedNetworkImage(
                    imageUrl: user["photoUrl"],
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => _buildNoPhoto(user),
                  )
                : _buildNoPhoto(user),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${user["name"] ?? "User"}, ${user["age"] ?? ""}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(Icons.favorite,
                            color: Colors.pinkAccent, size: 12),
                        SizedBox(width: 4),
                        Text(
                          "Liked you",
                          style: TextStyle(
                              color: Colors.pinkAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPhoto(Map<String, dynamic> user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          (user["name"] ?? "U")[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}