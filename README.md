# Women Safety SOS App

A Flutter-based mobile application designed to enhance personal safety by allowing users to quickly send SOS alerts with their current location to pre-defined trusted contacts.

## Table of Contents

1.  [Features](#features)
2.  [Screenshots](#screenshots)
3.  [Tech Stack](#tech-stack)
4.  [Prerequisites](#prerequisites)
5.  [Getting Started](#getting-started)
    *   [Cloning the Repository](#cloning-the-repository)
    *   [Firebase Setup](#firebase-setup)
    *   [Running the App](#running-the-app)
6.  [App Functionality](#app-functionality)
    *   [Authentication](#authentication)
    *   [SOS Alerts](#sos-alerts)
    *   [Trusted Contacts](#trusted-contacts)
    *   [SOS History](#sos-history)
7.  [To-Do / Future Enhancements](#to-do--future-enhancements)

## Features

*   **User Authentication:** Secure email/password based login and signup using Firebase Authentication.
*   **SOS Alert:** Send emergency SMS messages containing the user's current GPS location to trusted contacts with a single tap.
*   **Trusted Contacts Management:**
    *   Add, edit, and delete trusted contacts.
    *   Contacts are stored persistently on the device.
*   **Location Services:** Utilizes device GPS to fetch and share accurate location.
*   **SMS Integration:** Sends SMS messages directly from the device.
*   **SOS History:** Keeps a log of when SOS alerts were sent.
*   **Intuitive UI:** Simple and easy-to-use interface with bottom navigation.


*   **Framework:** Flutter
*   **Programming Language:** Dart
*   **Backend & Authentication:** Firebase (Firebase Auth)
*   **Location Services:** `geolocator` package
*   **SMS Services:** `telephony` package
*   **Local Storage:** `shared_preferences` package (for trusted contacts)
*   **State Management:** `StatefulWidget` (with `setState`)

## Prerequisites

*   Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
*   An IDE like Android Studio or VS Code with Flutter plugins.
*   A Firebase project set up.
*   An Android device or emulator (iOS might require additional setup for location and SMS permissions).

## Getting Started

### Cloning the Repository

### Firebase Setup

1.  **Create a Firebase Project:** If you haven't already, create a project at [https://console.firebase.google.com/](https://console.firebase.google.com/).
2.  **Add an Android App to your Firebase project:**
    *   Use `com.example.your_app_name` (or your actual package name found in `android/app/build.gradle` - `applicationId`) as the Android package name.
    *   Download the `google-services.json` file.
3.  **Place `google-services.json`:** Move the downloaded `google-services.json` file into the `android/app/` directory of your Flutter project.
4.  **Enable Email/Password Authentication:** In the Firebase console, go to "Authentication" -> "Sign-in method" and enable "Email/Password".
5.  **(Optional but Recommended) Add Firebase SDK to your Gradle files:**
    *   Ensure your `android/build.gradle` file has the Google services classpath:

### Running the App

1.  **Get Dependencies:**
## App Functionality

### Authentication

*   Users can sign up for a new account using their email and password.
*   Existing users can log in with their credentials.
*   Authentication state is managed to keep users logged in across app sessions.

### SOS Alerts

*   From the "Home" tab, users can tap the "SEND SOS" button.
*   The app will request location and SMS permissions if not already granted.
*   It fetches the current GPS coordinates.
*   An SMS message, including a Google Maps link to the user's location, is sent to all trusted contacts.

### Trusted Contacts

*   The "Contacts" tab allows users to manage their list of trusted emergency contacts.
*   Users can add new contacts by providing a name (optional) and phone number.
*   Existing contacts can be edited or deleted.
*   These contacts are saved locally on the device and persist even if the app is closed.

### SOS History

*   The "History" tab displays a list of past SOS alerts, including the timestamp when they were sent.
## To-Do / Future Enhancements

*   [ ] iOS Support (testing and specific permission handling).
*   [ ] Option to send SOS via other channels (e.g., WhatsApp, Email).
*   [ ] In-app map view to show current location.
*   [ ] Background SOS trigger (e.g., shake device, volume button press).
*   [ ] Siren/Alarm feature.
*   [ ] User profile management.
*   [ ] Encrypting contacts data for enhanced security.
*   [ ] More robust unique ID generation for contacts (e.g., UUID).
*   [ ] Refactor contact storage into a dedicated service/repository pattern.
