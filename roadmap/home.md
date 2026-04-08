# Home.md — Suivi refactor **codable**

> But: finaliser le découpage de `HomePage` pour obtenir une vue simple, testable, performante.

## ✅ Déjà fait
- Extraction de la mise en page des modules dashboard dans `lib/widgets/dashboard/modules_layout.dart`.
- Extraction des calculs métier principaux dans `home_metrics_service.dart`.
- Exposition réactive des données via `providers.dart`.
- Base de widgets dashboard mutualisés dans `widgets/dashboard_cards.dart`.
- Breakpoints alignés sur la cible (`mobile < 700`, `tablet 700-1099`, `desktop >= 1100`).
- Utilisation de `select` sur les providers principaux du dashboard pour limiter les rebuilds.
- Remplacement du `switch` modules Home par un mapping clair `DashboardWidgetType -> Widget builder`.
- Uniformisation des états `LoadingState`, `EmptyState`, `ErrorState` via `lib/widgets/dashboard/module_states.dart`.

---

## 🔄 Reste à faire

### PR-C — Découpage composants UI
- [x] Créer structure:
  - `lib/widgets/dashboard/balance_card.dart`
  - `lib/widgets/dashboard/flow_card.dart`
  - `lib/widgets/dashboard/category_card.dart`
  - `lib/widgets/dashboard/recent_activity_card.dart`
- [~] Remplacer les blocs volumineux restants de `HomePage` par ces composants dédiés (partiellement fait).
- [ ] Vérifier parité visuelle avant/après.

### PR-D — Responsive & accessibilité
- [ ] Ajuster finement layout (colonnes, paddings, densité) par breakpoint.
- [ ] Vérifier tailles de touch targets, contraste, labels.

### PR-E — Fiabilité interactions
- [x] Uniformiser feedback utilisateur (snackbar succès/erreur) sur les actions dashboard déjà refactorées.
- [x] Encadrer actions destructives par dialogues de confirmation.
- [x] Déplacer opérations composées restantes vers services métier (auto-settle extrait vers `HomeInteractionService`).

---

## Checklist de validation finale
- [ ] `HomePage` < 250 lignes (objectif lisibilité).
- [ ] Aucun calcul métier lourd restant dans la vue.
- [ ] Tests widget de 2 cartes dashboard minimum.
- [ ] `flutter analyze` vert.
- [ ] Vérification manuelle mobile + desktop.
