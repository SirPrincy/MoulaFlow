# Architecture de Moula Flow

Ce document détaille l'organisation technique du projet Moula Flow.

## Principes de Conception
- **Minimalisme** : Dépendances limitées au strict nécessaire (`shared_preferences`, `intl`, `uuid`, etc.).
- **Performance** : Utilisation de `setState` et `ValueNotifier` pour une réactivité optimale sans surcoût de librairies tierces.
- **Offline-First** : Persistance locale systématique via JSON dans le stockage de l'appareil.

## Couches de l'Application

### 1. Data Layer (`lib/data/`)
Responsable de la persistance et de la récupération des données.
- **Repositories** : Abstraient l'accès à `SharedPreferences`.
    - `TransactionRepository` : CRUD pour les transactions.
    - `CategoryRepository` : Gestion des catégories et injection des défauts.
    - `WalletRepository` : Gestion des portefeuilles et soldes initiaux.
    - `DashboardRepository` : Configuration de l'affichage du tableau de bord.
- **Storage Keys** : Centralisation des clés de stockage pour éviter les collisions.

### 2. Domain Layer (`lib/domain/`)
Contient la logique métier pure, indépendante de l'interface Flutter.
- **BalanceService** : Calcule les soldes en temps réel, filtre les transactions par portefeuille ou par date, et génère les statistiques de flux.

### 3. UI Layer (`lib/pages/` & `lib/widgets/`)
Responsable de l'affichage et de l'interaction utilisateur.
- **Pages** : Conteneurs de haut niveau (HomePage, CategoryOverviewPage, CategoryManagementPage, etc.).
  - `CategoryManagementPage` : gestion hiérarchique via panneaux expansibles animés.
- **Widgets** : Composants réutilisables.
    - `DashboardCards` : Widgets spécialisés pour le tableau de bord (Soldes, Flux, Catégories).
    - `TransactionTile` : Affichage d'une transaction unique.

## Modèle de Données
Les modèles sont définis dans `lib/models.dart`. Ils incluent des méthodes `toJson()` et `fromJson()` pour la sérialisation, facilitant le stockage local.
