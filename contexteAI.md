# Contexte AI - Moula Flow (v0.03)

## Ce qui a été fait
- Initialisation du projet Flutter `moula_flow`.
- **Mise à jour v0.03 (Fluidité UI Catégories & Docs)** :
    - Refonte de `category_management_page.dart` avec `ExpansionPanelList.radio` et transitions plus stables.
    - Actions contextualisées (ajout/modification/suppression) au niveau des catégories et sous-catégories.
    - Harmonisation documentaire : README, docs et ajout de `docs/Design.md`.
- **Refactoring architectural (v0.01)** : `main.dart`, `models.dart`, `home_page.dart`, `widgets.dart`, `settings_page.dart`, `category_management_page.dart`.
- **Mise à jour v0.02 (Dashboard & Overviews)** :
    - **Dashboard Dynamique** : Système de widgets configurables (Ordre, Visibilité : Balance, Flux, Catégories, Tendances, Récents).
    - **Gestion de la Dette & Épargne** : Pages d'aperçu spécifiques (`category_overview_page.dart`) avec barres de progression vers objectifs et gestion de l'échéance.
    - **Suivi des Paiements Récurrents** : Page dédiée pour filtrer les transactions marquées comme récurrentes.
    - **Persistance Avancée** : Ajout de `DashboardRepository` pour sauvegarder la configuration utilisateur du tableau de bord.
- **Gestion des Catégories (Hiérarchique)** :
    - Système complet avec catégories principales et sous-catégories.
    - Recherche en temps réel via un `showModalBottomSheet`.
- **Formulaire de Transaction Avancé** :
    - Champs complets (Montant, Date, Catégorie, Wallet, Tags).
    - Support de la récurrence (flag `isRecurring`).
- **Paramètres & "Zone de Danger"** :
    - Thème Dark/Light persistant.
    - Reset global des données.

## Ce qu'il reste à faire
- **Automatisation des Récurrences** : Planification réelle avec notifications ou ajout automatique au changement de mois.
- **Graphiques Avancés** : Intégration de `fl_chart` pour les tendances et diagrammes circulaires (actuellement placeholders/simplifiés).
- **Sauvegarde Cloud/Export** : Export CSV/JSON pour la portabilité des données.
- **Recherche Globale** : Barre de recherche sur l'ensemble des transactions.

## Décisions prises
- Architecture basée sur le pattern Repository pour isoler `shared_preferences`.
- Pas de state management complexe (Provider/Riverpod) -> `setState` suffisant pour le moment.
- Style minimaliste "Premium" noir/blanc avec icônes subtiles.

## Contraintes techniques respectées:
- Flutter pur, minimal dependencies.
- Stockage JSON local.
- Responsive (Mobile/Desktop/Web).
