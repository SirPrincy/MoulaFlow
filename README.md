![Moula Flow logo](assets/logo_moula.svg)

# Moula Flow 🦇 (v0.04 Beta)

Moula Flow is a minimalist, modern, and purely reactive personal finance application built with **Flutter**. It prioritizes a premium user experience with a clean "Vibe Coded" aesthetic and a robust offline-first architecture.

## Why Moula Flow? 🚀

- **Pure Reactivity**: Powered by **Riverpod**, every change in your data is instantly reflected across the entire app.
- **Local Sovereignty**: Your data stays on your device in a high-performance **Drift (SQLite)** database. No cloud, no tracking.
- **Premium Design**: A curated "Minimalist Finance" look with smooth transitions, glassmorphism, and a sleek dark mode.
- **Smart Tracking**: Manage multi-wallets (Savings, Debt, Current), track budgets with projections, and identify recurring payments.

## Core Features 💎

- **Modular Dashboard**: Customize your home screen with reorderable widgets (Balance, Flows, Categories, Trends, Recents).
- **Proactive Budgeting**: Set savings goals or debt deadlines with visual progress tracking.
- **Hierarchical Categories**: Deep organization with real-time fuzzy search for categories and sub-categories.
- **Advanced Transactions**: Support for transfers, tags, and recurrence flags.
- **Export & Portability**: (In development) Future-proof your data with CSV/JSON exports.
- **Resilient Local Data**: Non-destructive Drift migrations, SQLite integrity checks, and safer backup restore flow.
- **Recovery Guidance**: If profile metadata exists but local transactional data is empty, the app now shows a recovery hint.

## Tech Stack 🛠️

- **UI Framework**: Flutter (Material 3)
- **State Management**: [Riverpod](https://riverpod.dev/) (Notifiers, AsyncNotifiers, StreamProviders)
- **Persistence**: [Drift](https://drift.simonbinder.eu/) (SQLite)
- **Charts**: `fl_chart`
- **Fonts**: Google Fonts (Newsreader & Work Sans)

## Developer Guide 💻

### Prerequisites
- Flutter SDK (Stable)

### Installation & Run
1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate code (Drift & Riverpod):
   ```bash
   dart run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Database Reliability Notes
- Current Drift schema: **v9** (`schemaVersion = 9`).
- Upgrade path to v9 is non-destructive for existing user data (adds the `projects` table only).
- Startup includes:
  - `PRAGMA foreign_keys = ON`
  - `PRAGMA busy_timeout = 2000`
  - `PRAGMA integrity_check` validation + critical table presence checks.
- Binary backup import uses a safer file swap strategy (`.tmp` then rename with `.old` rollback).

## Documentation 📚

All detailed technical specifications are consolidated in:
- [**Technical Specifications**](docs/SPECIFICATIONS.md)

---

## License 📜
This project is licensed under the **MIT License**.  
Copyright (c) 2026 SirPrincy
