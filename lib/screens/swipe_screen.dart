import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sparkmate/screens/match_popup_screen.dart';
import 'package:sparkmate/screens/match_list_screen.dart';
import 'package:sparkmate/screens/profile_edit_screen.dart';
import 'package:sparkmate/screens/filter_screen.dart';
import 'package:sparkmate/screens/who_liked_you_screen.dart';
import 'package:sparkmate/screens/swipe_limit_service.dart';

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
  int remainingSwipes = 10;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);

    remainingSwipes = await SwipeLimitService.getRemainingSwipes();

    final myDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();
    final myData = myDoc.data();
    final filters = myData?["filters"];
    final interestedIn = filters?["interestedIn"] ?? "Everyone";
    final minAge = (filters?["minAge"] ?? 18) as int;
    final maxAge = (filters?["maxAge"] ?? 60) as int;

    final usersSnap =
        await FirebaseFirestore.instance.collection("users").get();

    List<SwipeItem> items = [];

    for (var doc in usersSnap.docs) {
      if (doc.id == currentUser.uid) continue;

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

      if (interestedIn != "Everyone") {
        if ((data["gender"] ?? "") != interestedIn) continue;
      }

      final age = (data["age"] ?? 0) as int;
      if (age < minAge || age > maxAge) continue;

      items.add(
        SwipeItem(
          content: data,
          likeAction: () async {
            final canSwipe = await SwipeLimitService.canSwipe();
            if (!canSwipe) {
              if (mounted) {
                _showSwipeLimitDialog();
              }
              return;
            }

            await SwipeLimitService.incrementSwipeCount();
            setState(() => remainingSwipes--);

            final otherUserId = doc.id;
            await FirebaseFirestore.instance
                .collection("swipes")
                .doc(currentUser.uid)
                .collection("liked")
                .doc(otherUserId)
                .set({"timestamp": FieldValue.serverTimestamp()});

            final otherLike = await FirebaseFirestore.instance
                .collection("swipes")
                .doc(otherUserId)
                .collection("liked")
                .doc(currentUser.uid)
                .get();

            if (otherLike.exists) {
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

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchPopupScreen(
                      name: data["name"] ?? "User",
                      photoUrl: data["photoUrl"] ?? "",
                    ),
                  ),
                );
              }
            }
          },
          nopeAction: () async {
            final canSwipe = await SwipeLimitService.canSwipe();
            if (!canSwipe) {
              if (mounted) _showSwipeLimitDialog();
              return;
            }
            await SwipeLimitService.incrementSwipeCount();
            setState(() => remainingSwipes--);
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
      swipeItems = items;
      matchEngine = MatchEngine(swipeItems: swipeItems);
      isLoading = false;
    });
  }

  void _showSwipeLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Daily Limit Reached 😴"),
        content: const Text(
            "You've used all your free swipes for today.\nUpgrade to Premium for unlimited swipes!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text("Get Premium 💎"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite, color: Colors.pinkAccent, size: 26),
            SizedBox(width: 8),
            Text(
              "SparkMate",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.pinkAccent),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FilterScreen()),
              );
              if (result == true) loadUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye,
                color: Colors.pinkAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WhoLikedYouScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border,
                color: Colors.pinkAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MatchListScreen()),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.person_outline, color: Colors.grey),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileEditScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              setState(() {
                swipeItems = [];
                matchEngine = null;
              });
              await Future.delayed(
                  const Duration(milliseconds: 300));
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.pink))
          : Column(
              children: [
                if (remainingSwipes < 10)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    color: remainingSwipes <= 3
                        ? Colors.red.shade50
                        : Colors.pink.shade50,
                    child: Text(
                      remainingSwipes <= 0
                          ? "No swipes left today 😴 Upgrade to Premium!"
                          : "⚡ $remainingSwipes swipes remaining today",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: remainingSwipes <= 3
                            ? Colors.red
                            : Colors.pinkAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Expanded(
                  child: swipeItems.isEmpty
                      ? _buildEmptyState()
                      : _buildSwipeCards(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No more profiles nearby",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text("Come back later!",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 12),
            ),
            onPressed: loadUsers,
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCards() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SwipeCards(
              matchEngine: matchEngine!,
              onStackFinished: () {
                setState(() {
                  swipeItems = [];
                  matchEngine = null;
                });
              },
              itemBuilder: (context, index) {
                final user = swipeItems[index].content;
                return _buildCard(user);
              },
            ),
          ),
        ),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            user["photoUrl"] != null
                ? CachedNetworkImage(
                    imageUrl: user["photoUrl"],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.pinkAccent)),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildNoPhoto(user),
                  )
                : _buildNoPhoto(user),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${user["name"] ?? "User"}, ${user["age"] ?? ""}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user["gender"] ?? "",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user["bio"] ?? "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person,
                size: 100, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              user["name"] ?? "User",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => matchEngine?.currentItem?.nope(),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child:
                const Icon(Icons.close, color: Colors.red, size: 32),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => matchEngine?.currentItem?.superLike(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.star,
                color: Colors.blue, size: 26),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => matchEngine?.currentItem?.like(),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.favorite,
                color: Colors.pinkAccent, size: 32),
          ),
        ),
      ],
    );
  }
}