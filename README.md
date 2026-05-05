# 📚 Book Butler: Your Personal Reading Companion

Welcome to **Book Butler**, a powerful and elegant Flutter application designed to revolutionize your reading experience. Built with a robust **Serverpod** backend, Book Butler helps you manage your digital library, track your reading progress, and leverage AI to dive deeper into your books.

---

## ✨ Key Features

-   **📖 Versatile Reader**: Seamlessly read and manage PDF files.
-   **🤖 AI Deep Dive**: Ask questions about specific page content and get context-aware answers powered by AI (Gemini).
-   **📊 Insightful Analytics**: Track your reading habits with detailed statistics and a dynamic activity heatmap.
-   **🏆 Global Leaderboards**: Compete with other readers and track your progress through points, books finished, and pages read.
-   **🔔 Smart Notifications**: Stay engaged with local and push notifications (FCM) for reading reminders and community updates.
-   **🔐 Secure Authentication**: Integrated Serverpod Auth for secure user accounts and identity management.
-   **💾 Local-First Storage**: Your reading data is saved securely on your device. Server interaction is primarily used for leaderboard rankings and global updates.

---

## 🛠 Tech Stack

### Frontend (Flutter)
-   **State Management**: Riverpod
-   **Networking**: Serverpod Client
-   **UI Components**: Rive (animations), `pdfrx`, `docx_file_viewer`
-   **Local Storage**: `shared_preferences`, `flutter_secure_storage`
-   **Services**: Firebase (Cloud Messaging), Home Widget integration

### Backend (Serverpod)
-   **Language**: Dart
-   **Database**: PostgreSQL (managed by Serverpod)
-   **Authentication**: Serverpod Auth (Email/JWT)
-   **AI Integration**: `dartantic_ai` wrapper for Google Gemini

---

## 🚀 Backend Anatomy: Serverpod Endpoints

The backend architecture is built on Serverpod, exposing several logical endpoints for the client to interact with.

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| **`ai`** | `askAboutPage` | Queries AI regarding specific page content provided by the user. |
| **`auth`** | `createAccountDirectly` | Specialized endpoint for direct account creation (Dev/Testing). |
| **`emailIdp`** | `login` | Handles standard email/password authentication flow. |
| **`greeting`** | `hello` | A simple example endpoint returning a personalized greeting. |
| **`leaderboardEntry`** | `getTopEntries` | Fetches the top leaderboard rankings. |
| | `upsertEntry` | Updates or creates a user's leaderboard progress record. |
| | `streamTopEntries` | Provides a real-time stream of the current top players. |
| **`notification`** | `registerDeviceToken` | Registers FCM tokens for push notification delivery. |
| | `sendReadingStarted` | Broadcasts a notification when a user starts a new book. |
| **`user`** | `getCurrentUser` | Retrieves the authenticated user's profile and settings. |
| | `updateProfile` | Allows users to modify their username, bio, and preferences. |

---

## 🏁 Getting Started

### Prerequisites
-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x recommended)
-   [Docker](https://www.docker.com/products/docker-desktop/) (for running the Serverpod database)
-   [Serverpod CLI](https://docs.serverpod.dev/getting-started/install-cli)

### Setting Up the Backend
1.  Navigate to the server directory: `cd project_thera_server`
2.  Start the database: `docker-compose up -d`
3.  **Generate code:** Run `serverpod generate` to generate the communication protocols and database models.
4.  Configure secrets:
    -   Create `config/passwords.yaml` (this file is excluded from version control for security).
    -   Add your `aiApiKey` for Gemini integration and database credentials.
5.  Run the server: `dart bin/main.dart`

### Running the Flutter App
I added the build files here 
- BookButler_app-release.apk
- BookButler_v7a-release.apk

  
1.  Navigate to the app directory: `cd project_thera`
2.  Install dependencies: `flutter pub get`
3.  Launch the app: `flutter run`

---

## 📄 License

This project is proprietary. Please refer to the repository owner for licensing details.
