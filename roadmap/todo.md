# Roadmap & TODOs (Moula Flow)

Ce document liste les chantiers potentiels identifiés lors de l'analyse du projet afin d'anticiper les prochaines évolutions.

## 🚀 À Implémenter (New Features)

- [ ] **Importation de données (CSV/JSON)** : Permettre d'importer l'historique de sa banque ou de l'application précédente.
- [ ] **Planification & Notifications (Scheduler)** : Ajouter des notifications locales pour alerter de l'échéance d'une facture récurrente ou générer automatiquement la transaction.
- [ ] **Analytique Avancée (Vue Rapports)** : Créer un onglet dédié à l'analytique avec `fl_chart` pour visualiser la répartition des dépenses par catégories sur plusieurs mois, l'évolution du patrimoine net, etc.
- [ ] **Ajout de Pièces Jointes** : Permettre d'ajouter une photo (reçu, ticket de caisse) ou un fichier à une transaction (stockage local).

## ✨ À Améliorer (Polish & Améliorations)

- [ ] **Couverture de Tests (Test Coverage)** : Ajouter des tests unitaires sur les Notifiers Riverpod (`BalanceService`, budgets) et des tests d'intégration sur Drift.
- [ ] **Harmonisation UI et Formulaires** : Centraliser et standardiser les champs de saisie (transactions, wallets, tags) avec une validation stricte (éviter les champs vides non gérés).
- [ ] **Internationalisation (l10n)** : S'assurer que tous les textes en dur restants dans les widgets soient migrés vers les `AppLocalizations` de Riverpod.
- [ ] **Optimisation Desktop/Web** : Les écrans complexes doivent garantir un affichage optimal sur grand écran en utilisant au mieux la largeur disponible au-delà du `AppSideMenu`.

## ⚙️ Architecture & Technique (Refactoring)

- [ ] **Système de Navigation (GoRouter)** : Migrer la navigation basique vers **GoRouter** pour faciliter le "deep linking", gérer proprement les redirections (lock screen biométrique) et unifier les transitions.
- [ ] **Injection des Préférences Locales** : Créer un unique `AppSettingsState` regroupant toute la configuration de l'application au lieu d'overrider individuellement chaque réglage dans le `main.dart`.
- [ ] **Stratégie de Migration de Base de Données (Drift)** : Implémenter et tester la mécanique `onUpgrade` avec le paquet `drift_dev` pour sécuriser les futures modifications des tables SQLite sans perte de données.
