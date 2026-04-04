# Technical & Functional Specifications (v0.04)

This document serves as the comprehensive source of truth for the **Moula Flow** architecture, design system, and development standards.

---

## 🏗️ Technical Architecture

Moula Flow follow a standard three-layer architecture designed for offline-first resilience and high reactivity.

### 1. Data Layer (`lib/data/`)
Persistent storage and raw data retrieval.
- **Relational Database (Drift)**: A robust SQL-backed storage (`moula_flow.sqlite`) with strong typing.
    - Tables: `Wallets`, `Transactions`, `Categories`, `Budgets`, `RecurringPayments`.
    - Schema Management: Automatic migrations via Drift's `schemaVersion`.
- **Repositories**: Standardized interfaces for database interactions.
    - `TransactionRepository`: Handles all financial movements and transfers.
    - `WalletRepository`: Manages balances and targets.
    - `CategoryRepository`: Handles hierarchical categories with default injection.

### 2. State Management Layer (`lib/providers.dart`)
The brain of the application powered by **Riverpod**.
- **StreamProviders**: Used for real-time data flow from the database (e.g., `walletsProvider`, `transactionsProvider`).
- **Notifiers**: Manages simple global states like `ThemeMode`, `Onboarding`, and `AppAccessMethod`.
- **AsyncNotifiers**: Handles complex states like the `DashboardConfig`, enabling asynchronous loading and persistence.

### 3. UI Layer (`lib/pages/` & `lib/widgets/`)
The interactive surface of the application.
- **ConsumerWidget**: Stateless/Stateful widgets that reactively watch providers.
- **Responsive Navigation**: Adaptative UI with a persistent sidebar on Desktop and a Drawer on Mobile.
- **Modular Dashboard**: A widget-based system where users can toggle and reorder modules (Balance, Flows, Trends).

---

## 🎨 Design System & UX

Moula Flow adheres to a "Premium Minimalist" aesthetic.

- **Palette**: Monochromatic core with deliberate primary accents (`AppStyles.kPrimary`).
- **Typography**:
    - **Titles**: `Newsreader` (Google Fonts) for a sophisticated, magazine-like feel.
    - **Body**: `Work Sans` for clean, high-readability data display.
- **Micro-interactions**: Subtle hover effects, smooth expansion panels for categories, and animated transitions between views.
- **Theming**: Full support for High-Contrast Dark mode and a clean, airy Light mode.

---

## 🛠️ Development Standards

To maintain code quality and architectural integrity:

1. **Code Generation**: Mandated for Drift and Riverpod. 
   - Command: `dart run build_runner build`
2. **Global State**: All shared state MUST be placed in a Riverpod Provider. Avoid "prop-drilling" through widget constructors.
3. **Immutability**: Models (`lib/models.dart`) should follow immutable patterns where possible, especially when working with Riverpod Notifiers.
4. **Offline-First**: Never assume the existence of an external API. All services should operate on the local Drift database.

---

## ✨ Functional Features

### 📊 Comprehensive Dashboard
- **Flow Analysis**: Visual comparison of monthly Income vs Expenses.
- **Category Insights**: Spending distribution overview via fl_chart.
- **Recent Activity**: Quick access to the last 5 transactions.

### 💳 Financial Management
- **Multi-Wallet Support**: Savings (targets), Debt (due dates), and Current accounts.
- **Intelligent Budgets**: Historical analysis and future projections for better budgeting accuracy.
- **Recurring Operations**: Identification and tracking of fixed expenses (bills, subscriptions).

### 🏷️ Categorization & Tags
- **Two-tier Hierarchy**: Folders for broad categories and sub-items for precise tracking.
- **Fuzzy Search**: Rapid selection of categories via a bottom-sheet search bar.
- **Tagging System**: Add free-form labels (e.g., #trip2026) for custom cross-category analytics.
