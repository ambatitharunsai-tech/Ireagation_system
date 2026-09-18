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

## CI/CD
Automated testing and APK generation via GitHub Actions is included.
