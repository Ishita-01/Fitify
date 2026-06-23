# Fitify

Fitify is a cross-platform fitness application built with Flutter. It generates a
personalised training program from a short onboarding questionnaire, guides the
user through workouts day by day, analyses exercise form from an uploaded video,
and includes an AI coach for questions about training and nutrition.

The interface uses an Apple-style "liquid glass" design with a light theme by
default and an optional dark theme that can be toggled in Settings.

## Features

- Personalised 28-day training program, organised into stages and a day-by-day
  timeline. Completed days collapse automatically so the plan opens on the
  current day.
- Discover tab with weekly progress charts, recent form-analysis results,
  recommendations, and a searchable workout library.
- Video form analysis for twelve exercises (upload from Photos or Files, or
  record up to sixty seconds).
- AI coach chat. With a free API key it gives personalised answers; without one
  it runs an offline rule-based assistant so the app always works.
- Light and dark themes, metric and imperial units, and onboarding that adapts
  the plan to the user's goals, experience, and preferred activities.

## Tech stack

- Flutter 3.41.5 (Dart 3.x)
- State management: `provider`
- Local storage: `shared_preferences`
- Networking: `http`
- Configuration: `flutter_dotenv`
- Fonts: `google_fonts`
- Media: `image_picker`, `file_picker`
- Visual effects: `liquid_glass_renderer`

## Supported platforms

Android, iOS, Web, macOS, Linux, and Windows are all supported from the single
codebase. The easiest way to try the app on any laptop is the Web target
(Google Chrome). iOS and macOS builds require a Mac.

## Prerequisites

Install these before running the app:

1. Flutter SDK 3.41.5 or newer. Follow the official guide for your operating
   system: https://docs.flutter.dev/get-started/install
2. Git.
3. One of the following run targets:
   - Google Chrome, for the Web target (works on Windows, macOS, and Linux).
   - Android Studio, for the Android emulator (works on Windows, macOS, Linux).
   - Xcode, for the iOS Simulator or macOS desktop (Mac only).

After installing, confirm the toolchain is healthy:

```bash
flutter doctor
```

Resolve any items marked with an x for the platform you intend to use. A few
green checks are enough; you do not need every platform configured.

## Setup

```bash
# 1. Clone the repository
git clone https://github.com/VishardMehta/Fitify.git
cd Fitify

# 2. Install dependencies
flutter pub get

# 3. Create the local config file (required, see below)
```

### Required: create the configuration file

The app reads an `assets/.env` file at startup. This file is intentionally not
committed to the repository, so you must create it once after cloning. The build
will fail if the file is missing, because it is declared as an asset.

Create a file at `assets/.env` with the following content:

```
GROQ_API_KEY=
```

Leaving the key empty is fine. The app will run with the built-in offline coach.
To enable the full AI coach, paste a free Groq API key after the equals sign (see
the "AI coach" section below).

On macOS and Linux you can create the file from the terminal:

```bash
mkdir -p assets
printf 'GROQ_API_KEY=\n' > assets/.env
```

On Windows (PowerShell):

```powershell
New-Item -ItemType Directory -Force assets | Out-Null
Set-Content -Path assets/.env -Value "GROQ_API_KEY="
```

## Running the app

List the devices Flutter can currently see:

```bash
flutter devices
```

Then run on the target you want. The sections below explain how to set up each
one.

### Web (recommended for the quickest start)

No emulator is needed. This works on Windows, macOS, and Linux as long as Chrome
is installed.

```bash
flutter run -d chrome
```

### Android emulator (Windows, macOS, or Linux)

An emulator is a virtual Android phone that runs on your computer, so a physical
phone is not required.

1. Install Android Studio.
2. Open Android Studio and go to the Device Manager (Tools menu, or the
   "More Actions" menu on the welcome screen).
3. Choose "Create Device", pick a phone such as Pixel 7, then select and
   download a system image (a recent stable Android version). Finish the wizard.
4. Press the play button next to the new device to start the emulator and wait
   for it to fully boot to the home screen.
5. With the emulator running, start the app:

   ```bash
   flutter run
   ```

   If more than one device is connected, target the emulator explicitly:

   ```bash
   flutter run -d emulator-5554
   ```

   (Use the exact id shown by `flutter devices`.)

### Android physical device

1. On the phone, enable Developer Options, then turn on USB debugging.
2. Connect the phone by USB and accept the debugging prompt.
3. Run `flutter run`.

### iOS Simulator (Mac only)

1. Install Xcode from the App Store.
2. Open the simulator with `open -a Simulator`, or run the app and let Flutter
   launch it.
3. Run the app:

   ```bash
   flutter run
   ```

### Desktop (macOS, Windows, Linux)

```bash
flutter run -d macos     # on a Mac
flutter run -d windows   # on Windows
flutter run -d linux     # on Linux
```

## AI coach (optional)

The AI coach works in two modes:

- Without a key: an offline, rule-based assistant. No setup, always available.
- With a key: a personalised assistant that uses the user's profile and plan.

To enable the full coach, create a free account at https://console.groq.com,
generate an API key, and place it in `assets/.env`:

```
GROQ_API_KEY=your_key_here
```

Then restart the app. Note that an API key placed in a client app is visible to
anyone who inspects the build; this is acceptable for a demo or class project,
but for production the request should be routed through a small server.

## Building release artifacts

```bash
flutter build apk      # Android
flutter build ios      # iOS (Mac only)
flutter build web      # Web
flutter build macos    # macOS
flutter build windows  # Windows
flutter build linux    # Linux
```

## Project structure

```
lib/
  core/
    navigation/        App routing
    theme/             Colors, text styles, light and dark themes
    widgets/           Shared widgets, including the liquid-glass surfaces
  data/
    models/            Plan, workout, profile, and analysis models
    repositories/      Workout, analysis, and assistant data sources
    services/          Plan engine, local storage, coach copy
  features/
    onboarding/        First-run onboarding flow
    app/               Main app: tabs, screens, providers, widgets
  main.dart            Entry point and provider wiring

assets/
  .env                 Local configuration (not committed)
```

## Machine-learning component

The pose-based exercise classifier and the "Shadow Trainer" form-analysis tool
are a separate Python pipeline. Setup and training instructions are documented
in `README_ML.md`. The Flutter app does not require this pipeline to run.

## Troubleshooting

- Build fails with a message about a missing `assets/.env`: create the file as
  described in the Setup section.
- `flutter devices` shows nothing: start an emulator or simulator first, or use
  `flutter run -d chrome` for the Web target.
- After installing Flutter, run `flutter doctor` and address the items flagged
  for your platform.
- If a command cannot find `flutter`, ensure the Flutter `bin` directory is on
  your system PATH and restart the terminal.

## License

This project is private and intended for educational use.
