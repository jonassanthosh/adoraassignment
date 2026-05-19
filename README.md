# Trail — Location Tracking

A Flutter app that records the device's GPS location in the foreground, in the
background, and — on iOS — even after the app has been terminated by the
system. Every fix is persisted to an on-device SQLite database and surfaced
through a Material 3 UI.

The project is a deliberate showcase of a production-leaning mobile
architecture: clean layering, BLoC state, compile-time dependency injection,
freezed unions, runtime permission flows, and platform-channel bridges to
native iOS code for headless background work.

---

## Highlights

- **Foreground + background tracking.** A single switch promotes the active
  session from "while in use" to a persistent Android foreground service or an
  iOS background-location session.
- **iOS Significant Location Changes (SLC).** Native Swift wraps
  `CLLocationManager.startMonitoringSignificantLocationChanges` so the system
  can wake the app — even after a force-quit — and persist fixes directly to
  SQLite from a headless launch.
- **First-class permission UX.** The BLoC understands `serviceDisabled`,
  `denied`, `deniedForever`, `whileInUse`, and `always`, and surfaces an
  "Open system settings" action whenever the user needs to leave the app.
- **On-device history.** Every fix (foreground, background, or SLC) is
  written to `locations.db` and rendered in a grouped, swipe-to-refresh
  history view.
- **Strict clean architecture.** Domain layer is pure Dart; platform code
  lives behind interfaces in `data/`; presentation depends only on the
  domain.
- **Tested.** Use cases, the `LocationModel`, and the `LocationBloc`'s
  permission and start/stop/toggle flows are unit-tested with
  `mocktail` + `bloc_test`.

---

## App tour

| Screen | What it does |
|---|---|
| **Home** | Hero `LocationCard` with live coordinates, source badge, and an animated status dot. Card tinting changes by state (idle / loading / tracking / problem). |
| **Background toggle** | Card-wrapped switch that requests the `Always` permission upgrade and reconfigures the active session in place — no need to stop and restart. |
| **Start / Stop button** | A single primary action that morphs based on state. `Stop` is rendered in the error-container palette to telegraph that it's destructive. |
| **History** | Recent 200 fixes, grouped by Today / Yesterday / date, with per-source icons (`foreground`, `background`, `slc`). Pull to refresh. |

---

## Project structure

```
lib/
├── app.dart                    MaterialApp + theme + MultiBlocProvider
├── main.dart                   Bootstrap: WidgetsBinding, DI, background service
├── core/
│   ├── di/                     get_it + injectable composition root
│   └── theme/                  AppTheme tokens & ThemeData factories
├── features/location/
│   ├── domain/                 Pure Dart — entities, repository interface, use cases
│   ├── data/                   Geolocator / permission datasources, repository impl, DTOs
│   └── presentation/           BLoC + Cubit, pages, widgets
├── services/background/        Foreground-service entry point, controller, iOS SLC bridge
└── storage/                    SQLite database wrapper

ios/Runner/
├── AppDelegate.swift                 Registers SLC method/event channels
├── SignificantLocationManager.swift  Wraps CLLocationManager for SLC
└── LocationStore.swift               Native SQLite writer for headless launches

test/
├── helpers/mocks.dart
└── features/location/
    ├── data/models/location_model_test.dart
    ├── domain/usecases/*.dart
    └── presentation/bloc/location_bloc_test.dart
```

Dependency direction is strictly inward: `presentation → domain ← data`.
Cross-cutting infrastructure (`BackgroundServiceController`,
`LocationDatabase`, `IosSlcBridge`) is hidden behind the
`LocationRepository` interface so the domain stays platform-free and
trivially testable.

---

## Architecture

### Layers
- **Domain** — `LocationEntity`, `LocationAuth`, `LocationRepository`, and
  use cases (`StartTracking`, `StopTracking`, `WatchLocations`,
  `GetLastLocation`). No Flutter imports.
- **Data** — `LocationRepositoryImpl` wires together
  `GeolocatorDataSource`, `PermissionDataSource`,
  `BackgroundServiceController`, `IosSlcBridge`, and `LocationDatabase`.
- **Presentation** — `LocationBloc` orchestrates permission flows and
  emits a sealed `LocationState` (idle / loading / tracking / failure).
  `SettingsCubit` persists the "track in background" preference.

### Dependency injection lifetimes
| Annotation | Used for |
|---|---|
| `@lazySingleton` | `GeolocatorDataSource`, `PermissionDataSource`, `LocationRepositoryImpl`, `BackgroundServiceController`, `IosSlcBridge`, `LocationDatabase`, `SettingsCubit` |
| `@injectable` (factory) | `LocationBloc` and every use case |
| `@preResolve` | `LocationDatabase.open()` — its `Future` is awaited once during `configureDependencies()` so the rest of the graph can resolve synchronously. |

### Background execution model
- **Android** — `flutter_background_service` runs a foreground service with
  `foregroundServiceType="location"` and a persistent notification. A
  separate Dart isolate (`backgroundEntry`) streams positions and posts
  them to the UI isolate via `service.invoke('update', …)`.
- **iOS (alive / suspended)** — `geolocator` with
  `AppleSettings.allowBackgroundLocationUpdates = true` and the
  `location` background mode keeps the blue indicator and continuous
  updates active.
- **iOS (terminated)** — `SignificantLocationManager.swift` registers for
  significant-location-changes; iOS will silently re-launch the app into
  the background on a meaningful movement (~500 m). `LocationStore.swift`
  writes the fix to `locations.db` directly from native code so data
  survives even if Flutter never starts.

### State
Sealed Freezed unions (`LocationState`, `LocationEvent`,
`LocationModel`, `SettingsState`) give us exhaustive `switch` matching
across the UI and the BLoC.

---

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.44 or newer |
| Dart | 3.12 or newer (for private-named-parameters) |
| Android SDK | min 23, target 35 |
| iOS deployment target | 13.0 |

---

## Running the app

```bash
# 1. Install Dart/Flutter dependencies
flutter pub get

# 2. Run code generation (freezed unions, JSON serializers, DI graph)
dart run build_runner build --delete-conflicting-outputs

# 3. (iOS only) Install CocoaPods
cd ios && pod install && cd ..

# 4. Launch on your device or simulator
flutter run
```

If you change anything annotated with `@freezed`, `@injectable`,
`@JsonSerializable`, etc., re-run step 2 — or use
`dart run build_runner watch` while you iterate.

---

## Running the tests

```bash
flutter test
```

The current suite covers:
- **Models** — `LocationModel` JSON round-trip, sqflite row parsing,
  numeric coercion, and entity mapping.
- **Use cases** — `StartTracking`, `StopTracking`, `WatchLocations`,
  `GetLastLocation` delegate correctly to the repository.
- **LocationBloc** — bootstrap behaviour, permission decision tree
  (`serviceDisabled`, `deniedForever`, `denied → request`, `whileInUse`,
  `always`), `useBackground` propagation, stop semantics, and the
  background-toggle "Always" upgrade flow.

---

## Permissions

The app requests the following at runtime:

| Permission | Why |
|---|---|
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Any GPS fix. |
| `ACCESS_BACKGROUND_LOCATION` (Android 10+) / `Always` (iOS) | "Track in background" sessions. iOS additionally requires "Always" for SLC. |
| `POST_NOTIFICATIONS` (Android 13+) | Foreground-service notification. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` | Declared in the manifest, granted at install time. |

The iOS `Info.plist` declares `UIBackgroundModes` (`location`, `fetch`),
`BGTaskSchedulerPermittedIdentifiers` (`dev.flutter.background.refresh`),
and the three `NSLocation*UsageDescription` strings needed for the
"Always" prompt.

---

## Tech stack

| Concern | Package |
|---|---|
| Location | [`geolocator`](https://pub.dev/packages/geolocator) |
| Permissions | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| State | [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) |
| DI | [`get_it`](https://pub.dev/packages/get_it) + [`injectable`](https://pub.dev/packages/injectable) |
| Codegen | [`freezed`](https://pub.dev/packages/freezed), [`json_serializable`](https://pub.dev/packages/json_serializable), [`build_runner`](https://pub.dev/packages/build_runner) |
| Background work | [`flutter_background_service`](https://pub.dev/packages/flutter_background_service) + [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) |
| Storage | [`sqflite`](https://pub.dev/packages/sqflite), [`path_provider`](https://pub.dev/packages/path_provider) |
| Persistence (settings) | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| Testing | [`mocktail`](https://pub.dev/packages/mocktail), [`bloc_test`](https://pub.dev/packages/bloc_test) |
