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

## Download Android app

After the first successful build on the `main` branch, the latest Android testing APK will be available here:

**[Download Ireagation System for Android](https://github.com/ambatitharunsai-tech/Ireagation_system/releases/latest/download/app-release.apk)**

Installation:
1. Download the APK on your Android phone.
2. Open the downloaded file and allow your browser or file manager to install unknown apps when Android asks.
3. Tap **Install**, then open **Ireagation System**.

This is a direct-install testing build, currently signed with the repository's debug signing configuration. It is not a Google Play Store release. If a later build cannot update an older installation because the signing key changed, uninstall the old test build first.

## CI/CD
Automated tests and Android APK packaging run in GitHub Actions. Pull request builds publish a 30-day APK artifact; successful builds on `main` publish a public GitHub Release.
