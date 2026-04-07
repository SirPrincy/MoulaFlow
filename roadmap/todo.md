# Moula Flow — Roadmap exécutable (TODO)

> Objectif: transformer la roadmap en **plan de livraison concret** avec des tâches techniques directement implémentables.

## Convention de suivi
- **[P0]** Bloquant / fondation
- **[P1]** Important / prochaine release
- **[P2]** Amélioration
- **Statut**: `todo` | `doing` | `done`

---

## v0.05 — Stabilisation architecture + Home refactor

### [P0] Initialisation applicative propre
- [ ] `todo` Créer `AppSettingsState` (agrégat unique des préférences) dans `lib/data/settings_repository.dart` + provider dédié dans `lib/providers.dart`.
- [ ] `todo` Modifier `lib/main.dart` pour ne plus charger les prefs une par une.
- [ ] `todo` Ajouter une stratégie de fallback si une préférence est corrompue (valeur par défaut + log clair).
- [ ] `todo` Ajouter un test du chargement initial (`test/data/` ou `test/domain/` selon implémentation).

### [P0] Refactor HomePage (découplage)
- [ ] `todo` Limiter `HomePage` à l’assemblage UI + callbacks utilisateur.

### [P1] Modularisation UI dashboard
- [ ] `todo` Créer des widgets par bloc dans `lib/widgets/dashboard_cards.dart` ou sous-dossier dédié:
  - `balance_card.dart`
  - `flow_card.dart`
  - `categories_card.dart`
  - `recent_transactions_card.dart`
- [ ] `todo` Remplacer les gros `switch`/conditions de `HomePage` par un mapping clair type `DashboardModule -> Widget`.
- [ ] `todo` Uniformiser composants `LoadingState`, `EmptyState`, `ErrorState`.

### [P1] Qualité formulaire & i18n
- [ ] `todo` Créer des validateurs partagés pour montants/champs obligatoires (transactions, wallets, tags).
- [ ] `todo` Retirer les textes en dur restants des pages critiques (`lib/home_page.dart`, `lib/pages/*.dart`, `lib/widgets/*.dart`).
- [ ] `todo` Ajouter clés manquantes dans `lib/l10n/app_fr.arb` et `lib/l10n/app_en.arb`.

---

## v0.06 — Features attendues

### [P1] Import CSV/JSON
- [ ] `todo` Définir format d’import minimal (date, montant, wallet, catégorie, note).
- [ ] `todo` Créer service d’import (`lib/data/import_service.dart`) avec phase de prévisualisation.
- [ ] `todo` Gérer mapping de colonnes + validation + rapport d’erreurs.
- [ ] `todo` Ajouter tests de parsing et test round-trip.

### [P1] Scheduler récurrences & notifications locales
- [ ] `todo` Étendre `recurring_payment_service` pour générer événements à échéance.
- [ ] `todo` Ajouter couche notifications locale (abstraction service + implémentation plateforme).
- [ ] `todo` Ajouter écran “À payer” filtré par fenêtre (J+3, J+7, retard).

### [P2] Analytics avancées
- [ ] `todo` Créer page rapports (`lib/pages/reports_page.dart`).
- [ ] `todo` Ajouter séries temporelles: dépenses par catégorie, évolution net, projections.
- [ ] `todo` Exploiter `fl_chart` avec thèmes clair/sombre cohérents.

---

## v0.07+ — Évolutions produit
- [ ] `todo` Migration navigation vers `go_router` (deep-link + redirections setup/verrouillage).
- [ ] `todo` Pièces jointes transaction (stockage local + métadonnées DB).
- [ ] `todo` Recherche globale cross-entités (transactions, catégories, projets, budgets).
- [ ] `todo` Insights automatiques (alertes dérives budget / dépenses atypiques).

---

## Definition of Done (obligatoire)
Une tâche est `done` uniquement si:
- [ ] code + tests ajoutés,
- [ ] l10n mise à jour (FR + EN),
- [ ] documentation impactée mise à jour,
- [ ] `flutter analyze` passe sans erreur,
- [ ] au moins un scénario manuel validé (mobile + desktop si UI).
