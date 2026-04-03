# Design System - Moula Flow

Ce document décrit les principes UI/UX de Moula Flow et sert de référence pour garder une expérience cohérente à travers l'application.

## Objectifs UX
- **Fluide** : transitions courtes, interfaces lisibles, interactions en 1-2 taps.
- **Calme** : palette sobre, peu de bruit visuel, focus sur les montants et actions principales.
- **Pratique** : hiérarchie claire entre aperçu global, action rapide, puis détail.

## Principes visuels
- **Style** : minimalisme "premium" sombre/clair.
- **Typographie** : titres forts (w700+), corps lisible, labels secondaires atténués.
- **Densité** : compacte mais respirante (espacements réguliers de 8/12/16 px).
- **Coins arrondis** : rayon standard basé sur `AppStyles.kDefaultRadius`.

## Pattern d'interaction

### 1. Gestion des catégories (révision v0.03)
- La page catégorie repose sur des **panneaux expansibles animés** (`ExpansionPanelList.radio`) pour éviter les sauts visuels.
- Les actions critiques (ajouter, modifier, supprimer) sont regroupées à portée immédiate sur chaque en-tête.
- Les sous-catégories conservent un rendu léger (liste dense + actions contextuelles).

### 2. Formulaires
- Dialogues courts avec validation explicite (`Valider`), annulation claire (`Annuler`).
- Feedback d'erreur via `SnackBar` pour les opérations bloquées (ex: suppression d'une catégorie parent non vide).

### 3. Dashboard
- Blocs configurables, priorité aux cartes de synthèse.
- Contenu secondaire (détails, historiques) dans des pages dédiées.

## Accessibilité
- Conserver un contraste élevé dans les deux thèmes.
- Éviter les zones de tap trop petites (< 40 px).
- Utiliser des libellés explicites dans les `tooltip` et les boutons d'action.

## Évolution
Pour toute évolution UI majeure :
1. mettre à jour ce fichier,
2. synchroniser `README.md` + `contexteAI.md`,
3. détailler les impacts techniques dans `docs/ARCHITECTURE.md` si un composant structurel change.
