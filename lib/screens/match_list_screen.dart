import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches 💘'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(uid)
            .collection('users')
            .orderBy('matchedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No matches yet',
                      style: TextStyle(
                          fontSize: 20, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Keep swiping! 💪',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final matchUserId = docs[index].id;
              return _MatchTile(
                  matchUserId: matchUserId, currentUid: uid);
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String matchUserId;
  final String currentUid;

  const _MatchTile(
      {required this.matchUserId, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(matchUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Loading...'),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        final name = data['name'] as String? ?? 'User';
        final photoUrl = data['photoUrl'] as String? ?? '';
        final age = data['age'];

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child:
                photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title:
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              age != null ? 'Age $age • It\'s a match 💘' : 'It\'s a match 💘'),
          trailing:
              const Icon(Icons.chat_bubble_outline, color: Colors.pink),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: matchUserId,
                  otherUserName: name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}