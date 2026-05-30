# Noor Al-Quran

Noor Al-Quran is a Flutter application for Quran reading, prayer times, adhan alerts, adhkar, qibla direction, and reading progress.

## Highlights

- Quran reader with surah list, search, bookmarks, and reading progress.
- Moroccan prayer times with local fallback and cached/offline behavior.
- Adhan notifications with selectable built-in sounds and custom audio from the phone.
- Background scheduling for adhan and prayer reminders.
- Qibla screen, adhkar, khatma planning, and home screen prayer widget.
- Arabic-first interface with support for light and dark themes.

## Tech Stack

- Flutter and Dart.
- Android native Kotlin for adhan playback and home screen widget.
- `flutter_local_notifications`, `workmanager`, `adhan`, `quran`, `geolocator`, and `just_audio`.

## Setup

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --release
```

The release APK is generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- Android adhan reliability depends on notification permission, exact alarm permission, battery optimization settings, and Do Not Disturb access when the user wants adhan to play during silent/DND modes.
- Audio files used for bundled adhan sounds are stored under `android/app/src/main/res/raw`.
