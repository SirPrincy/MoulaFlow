# Contexte AI - Moula Flow (v0.04)

## État Actuel du Projet
Moula Flow est passé d'une architecture simpliste à une infrastructure hautement réactive et structurée. La migration vers **Riverpod** et **Drift** est terminée (v0.04).
La base locale est actuellement en **schéma v9** avec migration non destructive vers la table `projects`.

## Milestone v0.04 (Stabilité & Performance)
- **Persistance Relationnelle** : Passage de `SharedPreferences` (JSON) à **Drift (SQLite)** pour une meilleure intégrité et performance des données.
- **Réactivité Globale** : Intégration de **Riverpod** (Notifiers, AsyncNotifiers, StreamProviders) pour un état d'application synchrone et sans "prop-drilling".
- **Refonte Navigation** : Amélioration de la stabilité de la barre latérale (Sidebar) et du tiroir (Drawer) avec correction des erreurs d'overflow.
- **Fiabilité DB renforcée** : Ajout de vérifications d'intégrité SQLite (`PRAGMA integrity_check`) et validation de tables critiques au démarrage.
- **Restauration backup sécurisée** : Import binaire avec remplacement atomique (`.tmp` / `.old`) pour éviter les états partiellement restaurés.
- **Aide de récupération UX** : Message contextuel si le profil est présent mais les données transactionnelles locales sont vides.

## Historique des Versions
- **v0.04** : Migration vers Drift & Riverpod. Documentation technique consolidée.
- **v0.03** : UI Catégories (Expansion Panels), fluidité des transitions.
- **v0.02** : Dashboard dynamique, suivi Dettes/Épargne, et objectifs financiers.
- **v0.01** : Initialisation, architecture Repository, et tests unitaires.

## Architecture & Organisation
- **Data Layer** : Repositories (Transaction, Wallet, Category, Budget, Recurring) injectés via `Provider`.
- **Data Safety** : `AppDatabase` exécute les checks d'intégrité au `beforeOpen`; `SettingsRepository` gère le backup binaire et la détection de scénario de récupération.
- **Domain Layer** : `BalanceService` pour le calcul temps réel des soldes et des flux.
- **UI Layer** : Widgets réactifs (`ConsumerWidget`), navigation adaptative (Desktop/Mobile).

## Décisions Techniques Clés
- **State Management** : Utilisation de **Riverpod** pour la gestion d'état immuable et facile à tester.
- **Database** : **Drift** pour le typage fort de la base de données SQL et les mises à jour automatiques via Streams.
- **Design System** : Minimalisme "Premium" avec typographie contrastée (Newsreader/Work Sans).

## Backlog / Prochaines Étapes
- **Export/Import CSV** : Restauration des données et portabilité.
- **Notifications & Scheduler** : Automatisation réelle des transactions périodiques.
- **Analytique Avancée** : Rapports mensuels et tendances visuelles via `fl_chart`.
- **Télémetrie migration avancée** : Historisation structurée des migrations réussies/échouées pour faciliter le support.

## Contraintes Techniques
- Flutter SDK Stable.
- Offline-First mandatory.
- Code generation (`build_runner`) requis pour Drift et Riverpod.
