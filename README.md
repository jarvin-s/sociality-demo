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
- **Real-time multiplayer** - synchronizes session and voting state across players
- **Deep link support** - join via URL with `?code=` on web

**Suggestions**
- **Real-time data (WebSocket)​**
- **Story preview (currently only title)​**
- **Add images to stories​**
- **Debate & profile features​** 

---

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart

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
│   └── main.dart                  # App entry point + navigation
├── pubspec.yaml
└── README.md
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- A configured backend endpoint for game sessions
- Physical device or emulator (camera required for QR scanning)

### Setup

**1. Clone the repo**
```bash
git clone https://git.fhict.nl/I553467/sociality
cd sociality
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure the API**

Set the base API URL in `lib/api/api_config.dart` to point to your backend.

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

## Build & Deployment

### Debug build
```bash
flutter run
```

### Release build (Android)
```bash
flutter build apk --release
# or for Play Store
flutter build appbundle --release
```
Output: `build/app/outputs/flutter-apk/` or `build/app/outputs/bundle/release/`

### Release build (iOS)
```bash
flutter build ios --release
```
Then archive and upload via Xcode.

### Release build (Web)
```bash
flutter build web --release
```
Output: `build/web/` — deploy to any static host.

**Notes**
- Update the version number in `pubspec.yaml` before each release build.
- Make sure the API base URL is set correctly for the target environment (dev vs. production) before building.

---

## Known Limitations & Issues

- **Physical board game required** — the app cannot be used meaningfully on its own; it's a companion to the physical Sociality board game.
- **Web QR scanning** — scanning via the browser camera is unreliable or unsupported on some devices; joining via the `?code=` deep link is the more reliable path on web.
- **No reconnect handling** — if a player loses connection mid-session, there's currently no graceful rejoin flow.
- **No persistence across sessions** — game state lives only for the duration of a session; there's no history or replay of past games.
- **Story previews are limited** — only the story title is shown before starting.

---

## Future Development

- Move real-time updates to a WebSocket-based connection.
- Add richer story previews (beyond just the title).
- Add images to stories.
- Add debate and profile features.
- Add reconnect/rejoin support for dropped players.
- Add session history so hosts can review past games.
- Improve web platform support, particularly QR scanning.
- Add automated tests (unit/widget) for screens and API calls.
- Add CI/CD pipeline for automated builds and releases.

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
