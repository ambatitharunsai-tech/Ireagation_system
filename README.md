# Smart Agriculture & Irrigation System 🌱

A modern, production-ready Flutter application designed to help farmers and agricultural businesses manage their crops, automate irrigation through IoT, track finances, and receive AI-driven advice.

## ✨ Features

- **Dashboard & Analytics**: Real-time sparkline graphs that compute cumulative historical data for crops, tasks, and profit directly from the database.
- **Farm Management**: Track crop sowing dates, area sizes, and growth stages. Manage daily farming tasks with priorities and statuses.
- **Financial Tracking**: Log sales and expenses, and automatically compute total revenue and net profit.
- **IoT & Automation Ready**: Built-in framework to handle real-world moisture sensors, temperature/humidity sensors, water pumps, and valves. Generates critical alerts when thresholds are crossed.
- **AI Farm Assistant**: Powered by Google's **Gemini API**. It reads active crops, financial health, live IoT sensor data, and current weather, compiling it to provide highly contextual, real-time farming advice.
- **Live Weather Integration**: Fetches real-time climate data and a 7-day forecast using the free Open-Meteo API.

## 🛠 Tech Stack

* **Frontend**: Flutter (Dart)
* **State Management**: `provider` (MultiProvider architecture)
* **Storage**: Offline-first JSON local database using `shared_preferences` (Architected with DAOs for easy migration to Supabase/Firebase)
* **UI/UX**: Material 3, `google_fonts` (Outfit), `fl_chart` for data visualization.

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd Ireagation_system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🧠 AI Integration (Gemini)

To enable the AI Farm Assistant:
1. Get a Gemini API Key from Google AI Studio.
2. Open the app and navigate to **Settings** → **API Keys**.
3. Enter your Gemini API key. The app will immediately start using live contextual data to generate smart farming advice.

## 🔌 IoT Integration

The `IoTService` (`lib/services/iot_service.dart`) is currently configured for a real-world production environment (simulation data has been removed). To connect physical sensors (ESP32/Arduino):
1. Integrate an MQTT client package (e.g., `mqtt_client`).
2. Subscribe to your sensor telemetry topics in `startSimulation()`.
3. Call `onDevicesUpdated` when new telemetry arrives to instantly update the UI and trigger Auto-Irrigation logic.

## 📄 License

This project is licensed under the MIT License.
