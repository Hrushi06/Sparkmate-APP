# 💘 SparkMate — Flutter Dating App

SparkMate is a Tinder-style dating mobile application built using **Flutter** and **Firebase**.
Users can create profiles, swipe through matches, like/pass, get mutual matches, and chat in real time.

---

# 📱 Features

### 🔐 Authentication

* Email & password login
* Firebase Authentication
* Auto login session

### 👤 Profile Setup

* Name, Age, Gender, Bio
* Profile photo upload
* Firebase Storage integration

### 🔥 Swipe System (Tinder Style)

* Swipe right → Like ❤️
* Swipe left → Pass ❌
* Skip already swiped users 
* Don't show own profile

### 💘 Match System

* Mutual like detection
* Match popup animation
* Match list screen

### 💬 Real-time Chat

* Firebase Firestore chat
* Live message updates
* Sender / receiver UI
* Chat per matched user

---

# 🛠 Tech Stack

### Frontend

* Flutter
* Dart
* Material UI

### Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

### Architecture

* Auth Gate Routing
* Firestore Collections
* Swipe Engine Logic
* Real-time Streams

---

# 📂 Project Structure

```
lib/
 ├── screens/
 │   ├── auth_gate.dart
 │   ├── email_login_screen.dart
 │   ├── profile_setup_screen.dart
 │   ├── swipe_screen.dart
 │   ├── match_list_screen.dart
 │   ├── match_popup_screen.dart
 │   └── chat_screen.dart
 │
 └── main.dart
```

---

# 🔥 Firestore Database Structure

### Users

```
users/{uid}
```

### Swipes

```
swipes/{uid}/liked/{otherUid}
swipes/{uid}/passed/{otherUid}
```

### Matches

```
matches/{uid}/users/{matchedUid}
```

### Chats

```
chats/{chatId}/messages/{messageId}
```

---

# 🚀 Getting Started

## 1. Clone repository

```
git clone https://github.com/Hrushi06/Sparkmate-APP.git
```

## 2. Open project

```
cd Sparkmate-APP
```

## 3. Install dependencies

```
flutter pub get
```

## 4. Run app

```
flutter run
```

---

# 📸 Screens (Optional — add later)

* Login Screen
* Profile Setup
* Swipe Cards
* Match Popup
* Match List
* Chat Screen

---

# ✨ Future Improvements

* Push notifications
* Location based matching
* Filters (age / gender)
* Profile editing
* Image gallery
* Video profiles
* Premium features

---

# 👨‍💻 Author

**Hrushikesh Bharat Kharade**
Flutter & AWS Developer

GitHub: https://github.com/Hrushi06

---

# ⭐ If you like this project

Give it a ⭐ on GitHub!
