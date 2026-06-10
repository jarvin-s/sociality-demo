# Sociality

Companion app for the **Sociality** board game by InnerGames.

The app enables players to host and join game sessions, navigate interactive stories, and vote on choices together in real time, all tied to the physical board game experience. The physical board game is required to be able to use the app correctly.

---

## Team

Built by **Laura, Jarvin, Berkan and Yousef**, took over from https://git.fhict.nl/I537964/tweekracht-sociality and rebuilt.

---

## Development Notes

**Current features**
- **Host a game** - create a session and share a PIN or QR code with players
- **Join a game** - enter a 6-character code or scan a QR code to join
- **Interactive stories** - branching narratives with decision points per situation
- **Real-time multiplayer** - powered by Firebase Realtime Database
- **Deep link support** - join via URL with `?code=` on web

**To do**
- **start listing** 

---

## Tech Stack

| What | How |
|---|---|
| Framework | Flutter |
| Backend | UHH |
| QR scanning | mobile_scanner |
| QR generation | qr_flutter |
| HTTP requests | http |
| SVG assets | flutter_svg |
| Sound effects | audioplayers |

---

## Project Structure

```
sociality/
├── assets/                        # Images, SVGs, sounds
├── lib/
│   ├── api/
│   │   ├── api_config.dart        # Base API URL config
│   │   └── game_session_api.dart  # Join/create session API calls
│   ├── screens/
│   │   ├── config_screen.dart     # Host or join choice
│   │   ├── guest_lobby_screen.dart
│   │   ├── home_screen.dart       # Landing screen
│   │   ├── host_name_screen.dart  # Host enters their name
│   │   ├── join_screen.dart       # Join via code or QR
│   │   ├── overview_screen.dart   # Story/situation picker (host)
│   │   ├── participant_screen.dart
│   │   ├── story_play_screen.dart
│   │   └── welcome_screen.dart    # Introduction + features
│   ├── services/                  # Local services (e.g. player identity)
│   ├── widgets/                   # Shared reusable widgets
│   ├── firebase_options.dart      # Generated Firebase config
│   └── main.dart                  # App entry point + navigation
├── firebase.json
├── pubspec.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- A Firebase project with Realtime Database enabled
- Physical device or emulator (camera required for QR scanning)

### Setup

**1. Clone the repo**
```bash
git clone <your-repo-url>
cd sociality
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Add Firebase config**

Make sure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in the correct directories. The `firebase_options.dart` file should already be generated — if not, run:
```bash
flutterfire configure
```

**4. Add assets**

Make sure the following exist in your project:
```
assets/images/logo.png
assets/images/background_blue.png
assets/crown.svg
assets/sounds/click.wav
```

**5. Run the app**
```bash
flutter run
```

---

## Navigation Flow

```
HomeScreen
  └── WelcomeScreen
        └── ConfigScreen
              ├── OverviewScreen (host)
              │     └── HostNameScreen
              │           └── ParticipantScreen
              │                 └── StoryPlayScreen
              └── JoinScreen
                    └── GuestLobbyScreen
```

All transitions use a left-to-right slide animation defined globally in `main.dart`.

---

## Color Palette

| Name | Hex |
|---|---|
| Pink | `#EA1F86` |
| Navy | `#1F2070` |
| Pink light | `#FF67B5` |
| Dark pink | `#B60664` |

---

## Platform Support

| Platform | Status |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| Web | ⚠️ QR scanning requires native camera |