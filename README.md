<!-- ASSUMPTIONS: repo name grocery_frontend_rider; adjust links if names differ -->
# Fresh Grocery — Rider App

Flutter app for delivery riders to accept nearby orders, navigate pickup-to-delivery, share live location, and chat/call the customer.

## Related repositories

| App | Description |
|---|---|
| [grocery_backend](../../../grocery_backend) | NestJS API powering the whole platform |
| [grocery_frontend_customer](../../../grocery_frontend_customer) | Customer shopping app |
| [grocery_frontend_store](../../../grocery_frontend_store) | Store/partner management app |
| [grocery_frontend_admin](../../../grocery_frontend_admin) | Admin console |

## Features

- Rider registration (awaiting admin approval before first login)
- Browse available orders near the rider's current location (radius-filtered, nearest-first)
- Accept/pick up an order, live location broadcasting during delivery
- **In-app chat** with the customer, scoped per order
- **Voice calling** with the customer (real-time audio via Agora), including a native incoming-call screen that rings even when the app is backgrounded or closed
- **Push notifications** (order assignments, chat messages, incoming calls) delivered via Firebase Cloud Messaging, with system tray banners
- Delivery history
- Account: forgot/reset password, profile editing

## Tech stack

- Flutter + `flutter_bloc`
- `dio` for networking
- `go_router` for navigation
- Location services for live position sharing
- `firebase_core` / `firebase_messaging` / `flutter_local_notifications` for push notifications
- `agora_rtc_engine` / `flutter_callkit_incoming` for real-time voice calling with a native ringing UI
- `permission_handler` for microphone/notification runtime permissions

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- The [backend](../../grocery-backend) running and reachable from your device/emulator
- Location permissions enabled on the test device/emulator
- A Firebase project with an Android/iOS app registered under this app's package name/bundle ID, with `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) added — see [backend README](../../grocery-backend#push-notifications-firebase) for full setup
- An Agora project App ID (from [console.agora.io](https://console.agora.io)) — same project/credentials as the customer app, so calls can connect between them

### Setup

```bash
git clone https://github.com/<your-username>/grocery_frontend_rider.git
cd grocery_frontend_rider
flutter pub get
```

Place `google-services.json` at `android/app/google-services.json` (Android) and add `GoogleService-Info.plist` to the `ios/Runner` target via Xcode (iOS). This must be a **separate** file from the customer app's — each app is registered under its own package name in Firebase Console.

### Backend connection

Set the API base URL for your target platform — see the equivalent section in the [customer app README](../../grocery_frontend_customer#backend-connection) for the exact pattern used across all four apps.

### Run

```bash
flutter run --dart-define=AGORA_APP_ID=your_agora_app_id
```

### Android notes

- `flutter_local_notifications` requires **core library desugaring** — already enabled in `android/app/build.gradle.kts`.
- Requires `RECORD_AUDIO`, `POST_NOTIFICATIONS`, and related call/notification permissions — already declared in `AndroidManifest.xml`.

### iOS notes

- Requires **Background Modes → Voice over IP** and **Push Notifications** capabilities enabled in Xcode (Signing & Capabilities), plus `NSMicrophoneUsageDescription` in `Info.plist`.

### First login

New rider accounts require admin approval before they can sign in — approve pending riders from the [admin console](../../grocery_frontend_admin).

## Project structure

```
lib/
├── core/ # network, theme, location services, notifications (FCM),
│ # calls (Agora audio)
├── data/ # API clients, models
├── logic/ # Cubits (state management)
├── presentation/ # screens and widgets
└── routes/ # go_router configuration
```

## License

Private project — not licensed for redistribution.
