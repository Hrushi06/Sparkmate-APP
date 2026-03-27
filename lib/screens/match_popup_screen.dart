import 'package:flutter/material.dart';

class MatchPopupScreen extends StatelessWidget {
  final String name;
  final String photoUrl;

  const MatchPopupScreen({
    super.key,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🎉 IT'S A MATCH!",
              style: TextStyle(
                color: Colors.pink,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You and this person liked each other!",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // ✅ Safe photoUrl check
            photoUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 75,
                    backgroundImage: NetworkImage(photoUrl),
                  )
                : const CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.person, size: 70, color: Colors.white),
                  ),

            const SizedBox(height: 20),
            Text(
              name.isNotEmpty ? name : "Someone",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Start a conversation now 💬",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 50),

            // ✅ Start Chat button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.chat_bubble, color: Colors.white),
              label: const Text(
                "Start Chat 💬",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 16),

            // ✅ Keep swiping button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Keep Swiping",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}