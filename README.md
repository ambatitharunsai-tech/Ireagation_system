# Ireagation System 🌱

A comprehensive Smart Agriculture & Intelligent Irrigation application built with Flutter and Supabase.

## Features

- **Dashboard:** Unified view of crops, tasks, IoT sensors, and financial health.
- **Crop Management:** Add, update, and track the growth stages of various crops with expected harvest dates.
- **Task Tracking:** Prioritized todo lists for daily farm operations.
- **Finance:** Income and expense tracking for precise yield and profit calculations.
- **IoT & Automation:** Real-time MQTT telemetry from soil moisture and temperature sensors. Automated irrigation pump control using a deterministic rules engine.
- **AI Agronomist:** (Edge Function) Expert agricultural recommendations powered by Google Gemini AI, running securely on the backend.
- **Offline Support:** Seamless UI operation during network drops using local caching.
- **Weather Integration:** Live Open-Meteo forecasts combined with irrigation algorithms to conserve water (e.g., skip watering if high rain probability).

## Architecture

- **Frontend:** Flutter (State management via `Provider`).
- **Backend:** Supabase (PostgreSQL with strict Row Level Security).
- **IoT Messaging:** MQTT Broker.
- **AI Processing:** Supabase Edge Functions + Gemini API.

## Download Android app

The repository is public. Anyone can download the latest public Android release from:

**[Download Ireagation System for Android](https://github.com/ambatitharunsai-tech/Ireagation_system/releases/latest/download/app-release.apk)**

The app checks GitHub Releases for a newer version at startup (at most once every 12 hours). When an update is available, it displays the version and release notes and opens the APK download. Android will ask the user to confirm installation; ordinary apps cannot silently install APK updates.

### Enable safe in-app updates (one-time setup)

Android only allows an APK to update an installed app when the package ID and signing certificate match. The earlier public test APK used the temporary GitHub Actions debug key. Before publishing update-enabled releases, configure one permanent private release keystore:

1. On a trusted computer, generate a private keystore and keep a secure backup:
   ```bash
   keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ireagation-release
   ```
2. Convert it to Base64. On macOS:
   ```bash
   base64 -i upload-keystore.jks | pbcopy
   ```
   On Linux:
   ```bash
   base64 -w 0 upload-keystore.jks
   ```
3. In GitHub, open **Settings → Secrets and variables → Actions → New repository secret**. Add these four secrets:
   - `ANDROID_KEYSTORE_BASE64`: the Base64 content from step 2
   - `ANDROID_KEYSTORE_PASSWORD`: the keystore password you chose
   - `ANDROID_KEY_ALIAS`: `ireagation-release`
   - `ANDROID_KEY_PASSWORD`: the key password you chose
4. Keep the keystore and passwords private. Never commit them or put them in source code.
5. Push a new commit to `main`. CI will build, test, and publish a signed release. Subsequent releases will use the same key and can update that installation.

**One-time migration:** the currently published v1.0.34 test APK was signed with a temporary CI debug key. The first permanent-key release cannot install over that build. Existing test users must uninstall the old APK once and install the first permanent-key release. Cloud data stored in Supabase is unaffected, but device-only app data may be removed by uninstalling.

This direct APK distribution is public, but it is not a Google Play Store listing. Play Store distribution requires a Play Console developer account and a separate store publishing/review process.

## Setup Instructions

1. Clone the repository.
2. Ensure you have Flutter installed (`flutter doctor`).
3. Set up a Supabase project and execute the migrations in `supabase/migrations/` in order.
4. Pass your Supabase URL and Anon Key via environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
   ```
5. Run `flutter pub get`.
6. Run the app on your preferred emulator or device.

## CI/CD

Automated formatting, static analysis, tests, and Android APK packaging run in GitHub Actions. Pull request builds publish a 30-day CI artifact. After the permanent Android signing secrets are configured, successful pushes to `main` publish versioned public GitHub Releases. The in-app updater checks the latest release and offers the APK to install.
