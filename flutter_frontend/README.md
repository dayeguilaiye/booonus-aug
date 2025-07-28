# Booonus Flutter Frontend

A Flutter implementation of the Booonus couple points management app.

## Features

- User authentication (login/register)
- Couple relationship management
- Points system
- Shop (item purchasing)
- Rules management
- Events management
- Profile management
- Cross-platform support (iOS, Android, Web)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Navigate to the flutter_frontend directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Building

For Android:
```bash
flutter build apk
```

For iOS:
```bash
flutter build ios
```

For Web:
```bash
flutter build web
```

## Project Structure

```
lib/
├── core/                   # Core functionality
│   ├── models/            # Data models
│   ├── providers/         # State management
│   ├── services/          # API and storage services
│   ├── theme/             # App theme and styling
│   └── utils/             # Utility functions
├── presentation/          # UI layer
│   ├── screens/           # App screens
│   └── widgets/           # Reusable widgets
└── main.dart              # App entry point
```

## Configuration

The app connects to the backend API. Make sure to configure the correct API base URL in the settings or through the API service configuration.

Default API URL: `http://192.168.31.248:8080/api/v1`
