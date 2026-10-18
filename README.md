# 📚 LibraryHub — Digital Library Management System

> A production-grade, full-stack Library Management System built with **Flutter**, **Firebase Authentication**, **Cloud Firestore**, and **Provider**.

---

## 🚀 Quick Access & Credentials

### 👑 Administrator Credentials
| Parameter | Value |
|---|---|
| **Portal** | Dedicated Admin Dashboard |
| **Email ID** | `admin@libraryhub.com` |
| **Password** | `admin123` |
| **Quick Action** | Tap **"Admin Login"** on the Sign-In screen to auto-fill |

### 🎓 Student Access
* Students can register any email & password directly via the **"Create Account"** button on the Sign-In screen.
* Students must complete their profile (**Contact**, **Education**, and **Address**) before borrowing books.

---

## 🔗 Direct Firebase Links

Access and manage your backend directly with these one-click links:

* 🌐 **[Firebase Project Dashboard](https://console.firebase.google.com/project/libraryhub-7a835/overview)** — Main project control center.
* 🔐 **[Firebase Authentication Dashboard](https://console.firebase.google.com/project/libraryhub-7a835/authentication/users)** — View registered user accounts and manage authentication.
* 🗄️ **[Cloud Firestore Database](https://console.firebase.google.com/project/libraryhub-7a835/firestore/databases/-default-/data)** — View and edit live collections (`users`, `books`, `borrow_history`).
* 📜 **[Firestore Security Rules](https://console.firebase.google.com/project/libraryhub-7a835/firestore/rules)** — Inspect and edit security rules.
* 📦 **[Firebase Project Settings](https://console.firebase.google.com/project/libraryhub-7a835/settings/general)** — View registered apps (Web, Android, Windows).

> 💡 **For a dedicated, step-by-step handover walkthrough, see [CLIENT_SETUP_GUIDE.md](file:///c:/Users/rutvik/OneDrive/Desktop/Library%20Management%20System/CLIENT_SETUP_GUIDE.md).**

---

## 📋 System Requirements & Prerequisites

Before running the application on a new machine, ensure you have:

1. **Flutter SDK**: Version `3.22.x` or higher ([Download Flutter](https://docs.flutter.dev/get-started/install)).
2. **Dart SDK**: Automatically included with Flutter.
3. **Web Browser**: Google Chrome or Microsoft Edge (for Web target).
4. **Mobile (Optional)**: Android phone with USB Debugging enabled, or Android Studio Emulator.
5. **Code Editor**: VS Code (recommended) with Flutter & Dart extensions, or Android Studio.

Verify your environment by running:
```bash
flutter doctor
```

---

## ⚡ Instant Setup (Client Machine)

This repository already includes pre-configured Firebase configuration (`lib/firebase_options.dart` and `android/app/google-services.json`). You can run it immediately without running setup commands!

### Step 1: Open the Project
Open a terminal in the project directory:
```bash
cd "Library Management System"
```

### Step 2: Fetch Dependencies
Download all required packages:
```bash
flutter pub get
```

### Step 3: Launch the Application

#### Option A: Run on Google Chrome (Fastest & Recommended)
```bash
flutter run -d chrome
```

#### Option B: Run on Android Phone (USB Connected)
1. Enable **Developer Options** on your Android phone (Settings > About Phone > Tap *Build Number* 7 times).
2. Enable **USB Debugging** (Settings > Developer Options > USB Debugging).
3. Connect your phone via USB and allow debugging permission.
4. Run:
```bash
flutter run
```

#### Option C: Install Standalone APK on Android Phone
If you don't want to run from code, install the pre-compiled APK directly:
* Location: `build/app/outputs/flutter-apk/app-release.apk`
* Transfer to phone via WhatsApp / Google Drive / USB, tap to install!

---

## 🛠️ (Optional) Connecting a New Firebase Project

If you want to connect this app to your own separate Firebase account:

1. Install the tools:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
2. Log in to Firebase:
   ```bash
   firebase login
   ```
3. Enable Email/Password Auth in [Firebase Console](https://console.firebase.google.com/) > **Authentication** > **Sign-in method** > **Email/Password**.
4. Create Cloud Firestore in **Test Mode** (or with rules below).
5. Run the configurator in the project root:
   ```bash
   flutterfire configure
   ```
   *(Select your project and platforms: android, web, windows)*.

---

## 🗃️ Firestore Database Schema

The system uses 3 collections in Cloud Firestore:

### 1. `users` Collection
Stores student and administrator profile data:
```json
{
  "uid": "USER_FIREBASE_UID",
  "email": "student@libraryhub.com",
  "name": "John Doe",
  "contact": "+91 9876543210",
  "education": "BCA Semester 4",
  "address": "Hostel Block B, Room 204",
  "role": "student" // or "admin"
}
```

### 2. `books` Collection
Stores library catalogue books:
```json
{
  "bookId": "UUID_OR_AUTO_ID",
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "description": "A Handbook of Agile Software Craftsmanship.",
  "availableCopies": 5
}
```

### 3. `borrow_history` Collection
Tracks all loan and return transactions:
```json
{
  "transactionId": "TRANSACTION_UUID",
  "userId": "STUDENT_UID",
  "bookId": "BOOK_ID",
  "bookTitle": "Clean Code",
  "borrowDate": "Timestamp",
  "returnDate": "Timestamp (Due Date)",
  "status": "Active" // or "Returned"
}
```

---

## 🛡️ Recommended Firestore Security Rules

Paste these rules into [Firestore Rules Console](https://console.firebase.google.com/project/libraryhub-7a835/firestore/rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users Collection
    match /users/{userId} {
      allow read, write: if isAuthenticated();
    }

    // Books Collection
    match /books/{bookId} {
      allow read: if true;
      allow write: if isAuthenticated();
    }

    // Borrow History Collection
    match /borrow_history/{historyId} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

---

## 🎯 Key Application Features & Workflows

### 🎓 Student User Journey
1. **Registration & Login**: Clean dark-mode UI with password toggle and instant validation.
2. **Profile Completion Requirement**: Students **cannot borrow books** without first filling in their **Contact Number**, **Education**, and **Address** (prevents unverified loans).
3. **Real-time Catalogue**: Instant search by Title or Author name, live stock badges (`X left` or `Unavailable`).
4. **Borrowing Flow**: Select return due date via integrated calendar picker; atomic batch updates stock count and logs history.
5. **My Books Tab**: View all active and returned loans with real-time status badges (`Active`, `Overdue`, `Returned`).
6. **One-Tap Return**: Tap **"Return"** on active borrow cards with confirmation dialog — immediately restores 1 copy back to the catalogue.

### 👑 Administrator Journey
1. **Dedicated Portal**: Login with `admin@libraryhub.com` / `admin123`.
2. **Live KPI Analytics**: Total registered students, active loans, and returned books.
3. **Student Activity Tracking**: See every registered student with full details (Name, Email, Mobile, Education, Address) and loan metrics (`Issued: X`, `Returned: Y`). Tap to expand full borrow history.
4. **Book Inventory**: View all titles in inventory with live stock counters and increment/decrement buttons (`+` / `-`).
5. **Add New Book**: Publish new titles directly from the app (Title, Author, Copies, Description) — instantly visible in student catalogue.
6. **Seamless Switching**: Admin can switch to "Student View" to preview the student experience and return to Admin Portal anytime.

---

## ❓ Troubleshooting & FAQs

### Q1: `flutter run` gives "No supported devices connected"
**Solution**: Run `flutter create .` to re-generate local platform folders, or specify `-d chrome` for web.

### Q2: Android phone not showing up in `flutter devices`
**Solution**: 
1. Make sure **USB Debugging** is turned ON in phone Developer Options.
2. Unplug and reconnect the USB cable.
3. Check phone screen for popup *"Allow USB debugging from this computer?"* and select **Always Allow**.

### Q3: How do I change an existing account to Admin?
**Solution**: Go to [Firestore Console](https://console.firebase.google.com/project/libraryhub-7a835/firestore), open the `users` collection, select the user's document, and change the `role` field value from `"student"` to `"admin"`.

---

## 🏆 Technology Stack

* **Frontend Framework**: [Flutter 3.x](https://flutter.dev) (Dart)
* **Authentication**: [Firebase Authentication](https://firebase.google.com/docs/auth)
* **Database**: [Cloud Firestore](https://firebase.google.com/docs/firestore)
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Design & Typography**: Custom Design System with [Google Fonts (Outfit)](https://fonts.google.com/specimen/Outfit)
* **Architecture**: Clean Service-Provider-View Architecture with Models & Repositories

---
*Built with ❤️ for LibraryHub Library Management Project Submission.*
