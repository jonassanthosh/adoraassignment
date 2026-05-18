# Location Tracking App

A Flutter app that records the device's location in both foreground and background modes and persists each fix to an on-device SQLite database. Built with **Clean Architecture**, **BLoC**, and `get_it` + `injectable` for dependency injection.

## Features

- Foreground location streaming via [`geolocator`](https://pub.dev/packages/geolocator) (10 m distance filter).
- Background tracking via [`flutter_background_service`](https://pub.dev/packages/flutter_background_service) with a persistent Android foreground-service notification.
- Runtime permission flow: `whileInUse` → `always` upgrade, with an "Open Settings" affordance when the user has permanently denied or services are off.
- On-device persistence in SQLite (`sqflite`) — every position (foreground or background) is written to a `locations` table.
- Toggle between foreground-only and background tracking from the UI; the mode is applied immediately, even while tracking is active.
- Material 3 UI with light/dark themes and a state-driven `LocationCard` showing latitude, longitude, accuracy, source, and timestamp.

## Project structure

```
lib/
├── app.dart                                  MaterialApp + MultiBlocProvider
├── main.dart                                 Bootstrap (DI + background service)
├── core/di/                                  injectable + get_it composition root
├── features/location/
│   ├── domain/                               Pure Dart: entities, repository interfaces, use cases
│   ├── data/                                 Concrete repos, datasources, DTOs
│   └── presentation/                         BLoC, pages, widgets
├── services/background/                      Foreground service entry point + controller
└── storage/                                  SQLite database wrapper
```

Dependency direction is strictly inward: `presentation → domain ← data`. The `BackgroundServiceController` and `LocationDatabase` are exposed to the domain layer via the `LocationRepository` interface.

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44+ |
| Dart | 3.12+ |

## How to run

1. **Install dependencies**

   ```bash
   flutter pub get
   ```

2. **Generate code** (Freezed unions, `injector.config.dart`, JSON serializers)

   ```bash
   dart run build_runner build
   ```

   Use `watch` instead of `build` if you're iterating on annotated classes.

3. **Run the app**

   ```bash
   flutter run
   ```

## Permissions

The app requests the following at runtime:

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — required for any location fix.
- `ACCESS_BACKGROUND_LOCATION` — required when "Track in background" is enabled (iOS: "Always"; Android 11+: must be granted from the system settings page).
- `POST_NOTIFICATIONS` — required on Android 13+ to display the foreground-service notification.
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` — declared in the manifest; granted at install time.

## Architecture notes

- **State:** Sealed Freezed unions (`LocationState`, `LocationEvent`) for exhaustive `switch` matching.
- **DI lifetimes:**
  - `@lazySingleton` — `GeolocatorDataSource`, `LocationRepositoryImpl`, `BackgroundServiceController`, `LocationDatabase`, `SettingsCubit`.
  - `@injectable` (factory) — `LocationBloc`, use cases (`StartTracking`, `StopTracking`, `WatchLocations`, `GetLastLocation`).
  - `LocationDatabase.open()` is `@preResolve` so its `Future<LocationDatabase>` is awaited once during `configureDependencies()`.
- **Background isolate:** runs `backgroundEntry` in a separate Dart isolate. It opens its own SQLite handle (WAL mode allows concurrent reads from the main isolate) and broadcasts updates back to the app via `service.invoke('update', ...)`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `'dart compile' does not support build hooks` | Use `dart run build_runner build --force-jit` (Dart 3.10 only; resolved on 3.11+). |
| `Plugin [id: 'org.jetbrains.kotlin.jvm', version: '...'] was not found` | Add `gradlePluginPortal()` to `pluginManagement.repositories` in the Flutter SDK's `flutter_tools/gradle/settings.gradle.kts` (known Flutter 3.44 issue). |
| `core library desugaring required` | Enable `isCoreLibraryDesugaringEnabled = true` and add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` in `android/app/build.gradle.kts`. |
| Background notification doesn't appear | Verify `POST_NOTIFICATIONS` is granted (Android 13+) and the "Track in background" toggle is on **before** tapping Start. |
