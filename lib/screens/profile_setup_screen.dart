import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'swipe_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? imageFile;
  String? uploadedPhotoUrl;

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final bioController = TextEditingController();

  String selectedGender = "Male";
  bool isLoading = false;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => isLoading = true);

    try {
      setState(() {
        imageFile = File(picked.path);
      });

      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child("${user.uid}.jpg");

      await ref.putFile(imageFile!);
      final imageUrl = await ref.getDownloadURL();

      // ✅ FIXED: use set with merge instead of update
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "photoUrl": imageUrl,
      }, SetOptions(merge: true));

      setState(() => uploadedPhotoUrl = imageUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo uploaded ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo upload failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  void saveProfile() async {
    // ✅ Validate name
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    // ✅ Validate age
    if (ageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your age")),
      );
      return;
    }

    // ✅ Validate age is a valid number
    final age = int.tryParse(ageController.text.trim());
    if (age == null || age < 18 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid age (18-100)")),
      );
      return;
    }

    // ✅ Validate bio
    if (bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your bio")),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // ✅ FIXED: use set with merge: true
      // This creates the document if it doesn't exist,
      // or updates it if it already exists — no more not-found error!
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "email": user.email ?? "",
        "name": nameController.text.trim(),
        "age": age,
        "gender": selectedGender,
        "bio": bioController.text.trim(),
        "profileCompleted": true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved 🎉")),
      );

      // ✅ Navigate to SwipeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SwipeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set up your profile"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ✅ Profile image picker
              GestureDetector(
                onTap: isLoading ? null : pickAndUploadImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.pink.shade100,
                  backgroundImage:
                      imageFile != null ? FileImage(imageFile!) : null,
                  child: imageFile == null
                      ? const Icon(Icons.camera_alt,
                          size: 35, color: Colors.pink)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tap to add photo",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ✅ Name field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Age field
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Age",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Gender dropdown
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (value) {
                  setState(() => selectedGender = value!);
                },
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Bio field
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 30),

              // ✅ Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Profile",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}