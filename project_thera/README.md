# 📚 The Flutter Butler

> Your intelligent reading companion that tracks, analyzes, and amplifies your reading journey.

**The Flutter Butler** isn't just a reading app; it's a productivity ecosystem. It records (Serverpod ORM), reminds (Future Calls), analyzes (Analytics Engine), and amplifies (AI Content Drafting). It removes the friction of habit tracking, allowing you to simply read while the Butler handles the logistics.

---

## 📑 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

The Flutter Butler is a comprehensive reading tracker and productivity app built with Flutter and Serverpod. It automates book tracking, session logging, social media content creation, and provides intelligent insights about your reading habits—all with a "butler" persona that handles the details so you can focus on reading.

---

## ✨ Features

### 1. 📖 The Log Keeper (Database & Entry)
Maintains your personal library with high precision.

- **Book Onboarding**: Scans a barcode or takes a title and fetches metadata (cover art, page count) via the Serverpod backend
- **Session Tracking**: Starts a timer when you open the book and stops it when you close it, calculating your "Pages Per Minute" automatically

### 2. 📱 The Social Secretary (Content Drafting)
Handles your social media presence so you don't have to think about what to post.

- **Drafting**: Uses the notes you took during reading to generate a structured thread or a single impactful tweet
- **Share Card Creation**: Automatically "paints" a high-quality image showing your progress, current book cover, and a key quote
- **Native Sharing**: Hands you the finished image and text to post with one tap

### 3. 📊 The Performance Analyst (Analytics)
Turns raw data into actionable insights.

- **Finish Date Prediction**: *"At your current pace of 12 pages/day, Sir, you will finish 'Dune' by next Tuesday."*
- **Reading Heatmaps**: Shows you exactly what time of day you are most focused
- **Milestone Rewards**: Generates a "Summary Report" every time you finish a book, detailing how many hours you spent and your average speed

### 4. 🔔 The Nudge Assistant (Reminders & Automation)
Acts as a gentle accountability partner.

- **Smart Reminders**: Notifies you if you haven't reached your daily goal, but with context: *"You're only 10 minutes away from your daily streak, shall we find a quiet corner?"*
- **Future Planning**: Using Serverpod Future Calls, it can schedule a "check-in" for the weekend to review your weekly reading progress

### 5. 🤖 The Intelligent Librarian (AI Integration)
Using Serverpod 3's Vector Database features:

- **Note Retrieval**: You can ask, *"Butler, what was that point I noted about stoicism in Chapter 2?"* and it finds the exact note
- **Contextual Summaries**: Can summarize your own notes to help you remember the book months after finishing it

---

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Serverpod 3
- **Database**: Serverpod ORM
- **AI Features**: Serverpod Vector Database
- **Platform**: iOS, Android, Web, Desktop

---

## 🚀 Installation

### Prerequisites

- Flutter SDK (^3.9.2)
- Dart SDK
- Serverpod CLI
- A code editor (VS Code, Android Studio, etc.)

### Setup Steps

1. Clone the repository:
```bash
git clone https://github.com/yourusername/project_thera.git
cd project_thera
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Set up Serverpod backend (if applicable):
```bash
# Configure your Serverpod endpoint in the app
```

4. Run the app:
```bash
flutter run
```

---

## 📱 Getting Started

1. **Add Your First Book**: Scan a barcode or enter a book title to add it to your library
2. **Start Reading**: Open a book to automatically start a reading session
3. **Take Notes**: Jot down thoughts while reading—the Butler will remember them
4. **View Analytics**: Check your reading heatmap and progress predictions
5. **Share Your Progress**: Generate and share beautiful reading cards on social media

---

## 📁 Project Structure

```
project_thera/
├── lib/
│   └── main.dart          # Main application entry point
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── web/                   # Web-specific files
├── test/                  # Test files
├── pubspec.yaml           # Flutter dependencies
└── README.md              # This file
```

---

## 🔧 How It Works

The Flutter Butler uses a multi-layered architecture:

- **Frontend (Flutter)**: Handles UI, user interactions, and local state management
- **Backend (Serverpod)**: Manages data persistence, API calls, and business logic
- **AI Layer**: Leverages Serverpod's Vector Database for semantic search and note retrieval
- **Automation**: Uses Serverpod Future Calls for scheduled reminders and check-ins

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🏆 Project Pitch

**The Flutter Butler** represents a new paradigm in reading productivity apps. By combining automated tracking, intelligent analytics, and AI-powered assistance, it removes all friction from the reading habit formation process. Whether you're a casual reader or a book enthusiast, the Butler works silently in the background, ensuring you never lose track of your progress and always have insights at your fingertips.

---

*Built with ❤️ using Flutter and Serverpod*