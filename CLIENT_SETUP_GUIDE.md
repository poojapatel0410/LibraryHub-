# 📖 LibraryHub — Client Onboarding & System Setup Guide

Welcome to the **LibraryHub** Project! This document provides a complete, foolproof walkthrough for setting up, running, testing, and managing the Library Management System on any computer or mobile device.

---

## ⚡ 1. Instant Access & Credentials

Everything is pre-configured and connected to a live Cloud Firestore backend. You can log in right away using the credentials below:

### 👑 Administrator Credentials (Full System Management)
| Field | Value | Notes |
|---|---|---|
| **Portal** | Dedicated Admin Dashboard | Real-time monitoring & stock control |
| **Admin Email** | `admin@libraryhub.com` | Pre-registered in Firebase Auth |
| **Admin Password** | `admin123` | Secure default password |
| **Quick Action** | **"Admin Login" button** | Click the purple button on the Sign-In screen to auto-fill credentials |

> **What the Admin Can Do:**
> - 📊 View live KPI stats (Total Students, Active Loans, Returned Books)
> - 👥 Track all registered students (Name, Contact, Education, Address, Registration Email)
> - 📜 Monitor student loans (See how many books each student has borrowed vs. returned, expand to see details)
> - 📦 Live Inventory Management (Increase `+` or decrease `-` available book stock)
> - ➕ Add new books to the catalogue (Title, Author, Copies, Description, and Cover Photo directly from Gallery or Web URL)

---

### 🎓 Student User Access (Borrow & Return Books)
* **Registration**: Any student can create an account using their email and password by clicking **"Create Account"** on the Sign-In screen.
* **Profile Verification Rule**: Students **must complete their profile** (Contact Number, Education, and Address) before they are allowed to borrow books. If incomplete, the system will prompt them with a 1-click shortcut to complete it.
* **Borrowing**: Select a book, choose the return due date from the calendar, and confirm.
* **My Books**: Students can track their borrowed books and return them with a single click.

---

## 🔗 2. Direct Firebase Management Links

Use these direct links to monitor, inspect, or manage the backend directly in the Firebase Console:

| Resource | Direct Link | Purpose |
|---|---|---|
| 🌐 **Firebase Project Console** | [Open Project Overview](https://console.firebase.google.com/project/libraryhub-7a835/overview) | Main Firebase dashboard for `libraryhub-7a835` |
| 🔐 **Authentication Users** | [Open Firebase Auth](https://console.firebase.google.com/project/libraryhub-7a835/authentication/users) | View, disable, or add student and admin accounts |
| 🗄️ **Cloud Firestore Database** | [Open Firestore Database](https://console.firebase.google.com/project/libraryhub-7a835/firestore/databases/-default-/data) | Inspect live collections: `users`, `books`, `borrow_history` |
| 📜 **Security Rules** | [Open Firestore Rules](https://console.firebase.google.com/project/libraryhub-7a835/firestore/rules) | View and configure database read/write permissions |
| ⚙️ **Project Settings** | [Open Project Settings](https://console.firebase.google.com/project/libraryhub-7a835/settings/general) | View registered web, android, and windows application keys |

---

## 💻 3. Setting Up on a New Client Machine (Step-by-Step)

Follow these steps to run the project from source code on any Windows, macOS, or Linux computer.

### Step 1: Check Prerequisites
Make sure the client machine has:
1. **Flutter SDK** (Version 3.22 or higher) — [Download Flutter](https://docs.flutter.dev/get-started/install)
2. **Dart SDK** (comes bundled automatically with Flutter)
3. **Google Chrome** (recommended for instant web running) OR **Android Studio / USB-connected Android phone**
4. **Git** (optional, for version control)

To verify the setup, open PowerShell or Terminal and run:
```bash
flutter doctor
```
*(Ensure Flutter and Chrome or Android toolchains show green checkmarks).*

---

### Step 2: Extract & Open the Project
1. Unzip the project folder or open it in your code editor (e.g., VS Code or Android Studio).
2. Open a terminal inside the project root folder (`Library Management System`):
```bash
cd "Library Management System"
```

---

### Step 3: Fetch Dependencies
Download all project dependencies from pub.dev:
```bash
flutter pub get
```

---

### Step 4: Run the Application

You have multiple convenient ways to run the project:

#### 🌐 Method A: Run on Google Chrome (Fastest & Zero Setup)
Run this command in the terminal:
```bash
flutter run -d chrome
```
* The app will compile and automatically open in Google Chrome with full responsiveness.
* All Firebase Authentication and Cloud Firestore features are 100% active.

---

#### 📱 Method B: Run on a Physical Android Phone via USB
1. On your Android phone, enable **Developer Options**:
   - Go to **Settings** > **About Phone** > Tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. Enable **USB Debugging**:
   - Go to **Settings** > **Developer Options** > Turn on **USB Debugging**.
3. Connect your phone to your computer with a USB cable.
4. When prompted on your phone screen (*"Allow USB debugging?"*), select **"Always allow"** and tap **OK**.
5. Verify your device is recognized:
   ```bash
   flutter devices
   ```
6. Run the app directly onto your phone:
   ```bash
   flutter run
   ```

---

#### 📦 Method C: Install Pre-Compiled APK Directly (No Code Needed!)
If the client just wants to test or showcase the app on an Android phone without installing Flutter:
1. Find the compiled release APK already generated in the project:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
2. Send this file to the Android device via **WhatsApp**, **Google Drive**, **Email**, or **USB transfer**.
3. Tap on the APK file on the phone and select **Install** (*enable "Install from unknown sources" if prompted*).
4. Open **LibraryHub** and start testing!

---

## 🏗️ 4. System Architecture & Database Structure

The project connects to Google Cloud Firestore with three collections:

```
Cloud Firestore
├── 📁 users
│    └── {userId} (document)
│         ├── uid: String
│         ├── email: String
│         ├── name: String
│         ├── contact: String
│         ├── education: String
│         ├── address: String
│         └── role: "admin" | "student"
│
├── 📁 books
│    └── {bookId} (document)
│         ├── bookId: String
│         ├── title: String
│         ├── author: String (or auther)
│         ├── description: String
│         ├── availableCopies: int
│         └── imageUrl: String
│
└── 📁 borrow_history
     └── {transactionId} (document)
          ├── transactionId: String
          ├── userId: String
          ├── bookId: String
          ├── bookTitle: String
          ├── borrowDate: Timestamp
          ├── returnDate: Timestamp (Due Date)
          └── status: "Active" | "Returned"
```

---

## 🧪 5. Testing Checklist for Client / Evaluation

Here is a recommended testing flow to demonstrate all features:

### Test Case 1: Admin Features
1. Open the app, click **"Admin Login"** (auto-fills `admin@libraryhub.com` / `admin123`), and click **Sign In**.
2. **Dashboard Overview**: Review the top KPI cards showing Total Students, Active Loans, and Returned Books.
3. **Student Directory**: Scroll down to view the registered students. Notice their contact, education, and address details along with loan counts (`Issued: X`, `Returned: Y`).
4. **Loan Details**: Tap on any student card to expand their borrowing history with exact dates and statuses.
5. **Inventory Tab**: Click the "Inventory" tab to see all books and use the `+` / `-` buttons to adjust stock live.
6. **Add Book Tab**: Click "Add Book", enter Title, Author, Description, and Copies, then tap "Add Book to Catalogue".

### Test Case 2: Student Registration & Profile Requirement
1. Sign out from Admin.
2. Click **"Create Account"** and register with a new student email (e.g., `student1@test.com` / `pass123`).
3. Try to borrow a book immediately:
   - Notice the system displays a verification banner and **blocks borrowing** because the profile is incomplete.
4. Click **"Complete Profile Now"** (or go to Profile tab > Edit Profile).
5. Fill in **Full Name**, **Contact Number**, **Education**, and **Address**, then tap **Save Profile**.
6. Return to the catalogue and tap any book.
7. Tap **"Borrow Book"**, choose a return due date from the calendar, and confirm.
8. Verify that the available copies count decreased by 1 in real time!

### Test Case 3: Returning a Book
1. Go to the **"My Books"** tab at the bottom navigation bar.
2. See the active book loan with its due date and status badge (`Active`).
3. Tap **"Return Book"** and confirm.
4. The status turns to **"Returned"**, and 1 copy is instantly restored back to the inventory catalogue!

### Test Case 4: Overdue Book Late Fine (₹3 / day - Cash)
1. If a student holds an active book past its scheduled due date, it is automatically flagged as **Overdue**.
2. **Student Side**:
   - Each overdue book displays an alert: `Overdue by X day(s) • Fine: ₹(X * 3)`.
   - Top banner aggregates: `Total Cash Fine Due: ₹Total. Please pay in cash at the library desk.`
   - Return confirmation dialog warns the student to pay the cash fine at the counter when handing in the book.
3. **Admin Side**:
   - Top KPI highlights: `Total Cash Fines to Collect: ₹Total`.
   - Student directory cards display individual fine badges: `Fine: ₹X (Cash)`.
   - Expanded student records detail overdue days and book-wise cash amounts to collect.

---

## 🛠️ 6. Useful Commands Reference

| Action | Command |
|---|---|
| Check installation health | `flutter doctor` |
| Get packages | `flutter pub get` |
| Run on Chrome | `flutter run -d chrome` |
| Run on connected Android device | `flutter run` |
| Build fresh Release APK | `flutter build apk --release` |
| Code quality analysis | `flutter analyze` |
| Clean build cache | `flutter clean` |

---

## 📞 7. Need Help or Support?

- **Firebase Project ID**: `libraryhub-7a835`
- **Application Package ID**: `com.example.library_hub`
- **Flutter Framework Version**: `3.22.x+` (Dart 3.x)

*LibraryHub — Seamless, secure, and modern digital library management.*
