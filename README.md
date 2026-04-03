![Moula Flow logo](assets/logo_moula.svg)

# Moula Flow 🦇 (v0.03)

This project is **100% vibe coded** with Flutter.

Moula Flow est une application minimaliste de suivi de finances personnelles développée avec **Flutter**. Elle fonctionne **100% hors ligne** avec `SharedPreferences`.

## Fonctionnalités Principales 🚀

- **Tableau de Bord Dynamique** (Nouveau) : Personnalisez l'ordre et la visibilité de vos widgets (Soldes, Flux, Catégories, Tendances, Récents).
- **Gestion Multi-Wallets & Objectifs** : Créez des comptes (Courant, Épargne, Dette) avec **montants cibles** et **dates d'échéance**.
- **Aperçus Spécifiques** : Vues détaillées pour l'Épargne et les Dettes avec suivi de progression et statut de règlement.
- **Catégorisation Hiérarchique** :
  - **Sélecteur modal** : Recherche et filtrage en temps réel.
  - **UI Catégorie retravaillée (v0.03)** : panneaux expansibles animés et actions contextuelles plus fluides.
  - **Bibliothèque Riche** : Catégories par défaut injectées au démarrage.
- **Transactions & Transferts** : Dépenses, Revenus et Transferts entre comptes.
- **Paiements Récurrents** : Identifiez et suivez vos transactions habituelles dans une vue dédiée.
- **Thème Sombre / Clair** : Look "Premium" noir et blanc persistant.
- **Zone de Danger** : Réinitialisation complète des données avec confirmation sécurisée.

## Architecture 🛠️

Le projet suit une architecture en couches pour séparer les responsabilités :

### 📂 Data Layer
- `lib/data/transaction_repository.dart` : Gestion des transactions.
- `lib/data/category_repository.dart` : Gestion des catégories.
- `lib/data/wallet_repository.dart` : Gestion des portefeuilles.
- `lib/data/dashboard_repository.dart` : Configuration du tableau de bord.
- `lib/data/settings_repository.dart` : Thème et préférences.

### 🧩 Domain Layer
- `lib/domain/balance_service.dart` : Logique de calcul des soldes et filtrage.

### 🎨 UI Layer
- `lib/pages/` : Écrans principaux (`home_page.dart`, `category_overview_page.dart`, `recurring_payments_page.dart`, etc.).
- `lib/widgets/` : Composants UI (`dashboard_cards.dart`, `widgets.dart`).

## Versioning 📌
- **v0.03** : Refonte UI de la gestion des catégories + documentation design consolidée.
- **v0.02** : Dashboard dynamique, Overviews (Dettes/Épargne), et support des objectifs.
- **v0.01** : Refactorisation initiale, repositories, et tests unitaires.

## Documentation 📚
Plus de détails disponibles dans le dossier `docs/` :
- [Architecture](docs/ARCHITECTURE.md)
- [Fonctionnalités](docs/FEATURES.md)
- [Développement](docs/DEVELOPMENT.md)
- [Design System](docs/Design.md)

## Build 🏗️
Testé via `flutter build linux` et `flutter build apk`. 🎉

## Android : mise à jour & données 📱

Les données sont stockées localement via `SharedPreferences` (mode hors ligne), donc **une mise à jour classique de l'application conserve normalement les données**.

Les données peuvent en revanche être perdues dans ces cas :
- désinstallation complète de l'app ;
- nettoyage manuel du stockage de l'application par l'utilisateur ;
- usage de la fonctionnalité **"Réinitialiser les données"** (Zone de Danger).

Conseil : avant une version majeure, prévoir un export/sauvegarde (fonction non incluse pour le moment).

## License 📜
Ce projet est sous licence **MIT**.  
Copyright (c) 2026 SirPrincy
