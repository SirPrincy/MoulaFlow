# Guide de Développement - Moula Flow

## Prérequis
- Flutter SDK (dernière version stable recommandée).
- Un IDE (VS Code ou Android Studio) avec les extensions Flutter/Dart.

## Installation
1. Clonez le dépôt.
2. Lancez `flutter pub get` pour installer les dépendances.
3. Exécutez l'application sur votre émulateur ou appareil physique : `flutter run`.

## Standards de Code
- **Formatage** : Utilisez `dart format .` avant chaque commit.
- **Linter** : Le fichier `analysis_options.yaml` définit les règles de style. Assurez-vous qu'aucune erreur d'analyse n'est présente.
- **State Management** : Nous privilégions le `setState` pour les états locaux et le découplage via les Repositories. Évitez d'ajouter des gestionnaires d'état lourds sans une justification de complexité majeure.

## Tests
Des tests unitaires sont disponibles dans le dossier `test/`. Ils couvrent :
- La logique de calcul du `BalanceService`.
- La sérialisation des modèles.
- Le comportement des repositories.

Lancez les tests avec :
```bash
flutter test
```

## Compilation
### Mobile (Android/iOS)
```bash
flutter build apk --split-per-abi
flutter build ios
```

### Desktop (Linux)
```bash
flutter build linux
```

## Ajout de nouvelles fonctionnalités
Lors de l'ajout d'une nouvelle fonctionnalité, n'oubliez pas d'actualiser :
1. Les modèles (`lib/models.dart`) si nécessaire.
2. Les repositories (`lib/data/`) pour la persistance.
3. Ce document et `contexteAI.md`.
4. `docs/Design.md` pour les décisions UI/UX.
