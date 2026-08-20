<!-- ASSUMPTIONS: repo name grocery_frontend_rider; adjust links if names differ -->

# Fresh Grocery — Rider App

Flutter app for delivery riders to accept nearby orders, navigate pickup-to-delivery, and share live location with customers.

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
- Delivery history
- Account: forgot/reset password, profile editing

## Tech stack

- Flutter + `flutter_bloc`
- `dio` for networking
- `go_router` for navigation
- Location services for live position sharing

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- The [backend](../../grocery-backend) running and reachable from your device/emulator
- Location permissions enabled on the test device/emulator

### Setup

```bash
git clone https://github.com/<your-username>/grocery_frontend_rider.git
cd grocery_frontend_rider
flutter pub get
```

### Backend connection

Set the API base URL for your target platform — see the equivalent section in the [customer app README](../../grocery_frontend_customer#backend-connection) for the exact pattern used across all four apps.

### Run

```bash
flutter run
```

### First login

New rider accounts require admin approval before they can sign in — approve pending riders from the [admin console](../../grocery_frontend_admin).

## Project structure

```
lib/
├── core/            # network, theme, location services
├── data/            # API clients, models
├── logic/           # Cubits (state management)
├── presentation/       # screens and widgets
└── routes/           # go_router configuration
```

## License

Private project — not licensed for redistribution.
