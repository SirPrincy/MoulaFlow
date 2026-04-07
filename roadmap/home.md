# Home.md — Spécification de refactor **codable**

> But: découper `HomePage` pour obtenir une vue simple, testable, performante.

## 1) Cible architecture

### État actuel (à corriger)
- `HomePage` mélange:
  - récupération de données,
  - calculs métier,
  - rendu UI,
  - orchestration d’actions.

### État cible
- `home_page.dart`: composition UI uniquement.
- `home_metrics_service.dart`: calculs purs (testables).
- `providers.dart`: exposition réactive des données.
- `widgets/dashboard/*`: cartes unitaires réutilisables.

---

## 2) Plan d’implémentation par PR

### PR-A — Extraire les métriques
- [ ] Créer `lib/domain/home_metrics_service.dart`.
- [ ] Déplacer les fonctions de calcul de `HomePage` vers ce service.
- [ ] Injecter dépendances minimales (transactions, wallets, catégories).
- [ ] Écrire tests unitaires:
  - [ ] total mensuel entrées/sorties,
  - [ ] solde global,
  - [ ] top catégories.

### PR-B — Providers dédiés dashboard
- [ ] Ajouter providers `homeMetricsProvider`, `homeFlowProvider`, `homeCategorySpendProvider` dans `lib/providers.dart`.
- [ ] Utiliser `select` quand possible pour limiter les rebuilds.
- [ ] Prévoir état unique `AsyncValue` par module.

### PR-C — Découpage composants UI
- [ ] Créer structure:
  - `lib/widgets/dashboard/balance_card.dart`
  - `lib/widgets/dashboard/flow_card.dart`
  - `lib/widgets/dashboard/category_card.dart`
  - `lib/widgets/dashboard/recent_activity_card.dart`
  - `lib/widgets/dashboard/module_states.dart`
- [ ] Remplacer les blocs volumineux de `HomePage` par ces composants.
- [ ] Vérifier parité visuelle avant/après.

### PR-D — Responsive & accessibilité
- [ ] Définir breakpoints explicites (`mobile < 700`, `tablet 700-1099`, `desktop >= 1100`).
- [ ] Ajuster layout (colonnes, paddings, densité) par breakpoint.
- [ ] Vérifier tailles de touch targets, contraste, labels.

### PR-E — Fiabilité interactions
- [ ] Uniformiser feedback utilisateur (snackbar succès/erreur).
- [ ] Encadrer actions destructives par dialogues de confirmation.
- [ ] Déplacer opérations composées vers services métier.

---

## 3) Contrat technique minimum

### API du service (proposition)
```dart
class HomeMetricsService {
  HomeMetrics compute({
    required List<TransactionModel> transactions,
    required List<WalletModel> wallets,
    DateTime? now,
  });
}
```

### Modèle de sortie (proposition)
```dart
class HomeMetrics {
  final double monthIncome;
  final double monthExpense;
  final double netWorth;
  final Map<String, double> spendByCategory;
  final List<TransactionModel> recents;
}
```

> Ces structures sont indicatives: adapter aux modèles réels déjà présents dans `lib/models.dart`.

---

## 4) Checklist de validation finale
- [ ] `HomePage` < 250 lignes (objectif lisibilité).
- [ ] Aucun calcul métier lourd restant dans la vue.
- [ ] Tests unitaires du service métriques présents.
- [ ] Tests widget de 2 cartes dashboard minimum.
- [ ] `flutter analyze` vert.
- [ ] Vérification manuelle mobile + desktop.
