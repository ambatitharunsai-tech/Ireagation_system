# Current Internal Architecture Map
Flutter UI ↓ Providers / State ↓ Services ↓ DAO / Repository ↓ Supabase / Local Database ↓ IoT / AI / Weather

## Core Layers
1. **Flutter UI:** `screens/` and `widgets/` present data and capture input.
2. **Providers / State:** `providers/` (e.g., `FarmProvider`, `FinanceProvider`) hold business logic and UI state.
3. **Services:** `services/` (`GeminiAIService`, `WeatherService`, `IoTService`, `AuthService`) handle external APIs and authentication logic.
4. **DAO / Repository:** `database/daos/` encapsulates database queries.
5. **Database:** `database/local_database.dart` serves as the offline cache and storage layer. `supabase_schema.sql` defines the cloud equivalent.
