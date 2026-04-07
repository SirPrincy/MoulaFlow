# Schéma des étapes de l'application (Moula Flow)

Ce document résume **tout le parcours utilisateur principal** de Moula Flow, depuis le lancement jusqu'aux pages métier.

## Vue globale (flow principal)

```mermaid
flowchart TD
    A[Ouverture de l'app] --> B[Chargement des préférences locales]
    B --> C[AppLaunchFlowPage]

    C --> D{Écran d'accueil \n WelcomePage}

    D -->|Nouveau profil\n"C'est parti"| E[SetupWizardPage]
    D -->|Profil existant\n"Accéder à Moula Flow"| F[Vérification d'accès\nAppAccessGate]

    E --> E1[Étape 1: Intro]
    E1 --> E2[Étape 2: Identité & Style\nNom + Couleur + Avatar]
    E2 --> E3[Étape 3: Création du 1er wallet]
    E3 --> E4[Étape 4: Confirmation]
    E4 --> E5[Sauvegarde paramètres + wallet + onboardingSeen=true]
    E5 --> F

    F -->|Accès refusé| D
    F -->|Accès validé| G[Traitement paiements récurrents]
    G --> H[HomePage / Dashboard]

    H --> I[Modules Dashboard\nBalance, Flux, Catégories, Tendances, Récents]
    H --> J[Transactions]
    H --> K[À payer]
    H --> L[Dettes]
    H --> M[Épargne]
    H --> N[Projets]
    H --> O[Paiements récurrents]
    H --> P[Budgets]
    H --> Q[Paramètres]
```

## Détail des étapes d'onboarding (Setup Wizard)

1. **Intro**: présentation de la promesse produit (local-first, réactivité, UI premium).
2. **Identité & style**: l'utilisateur définit son nom, sa couleur d'accent et son avatar.
3. **Premier compte (wallet)**: création du compte principal via le formulaire wallet.
4. **Confirmation**: écran de succès.
5. **Finalisation technique**:
   - sauvegarde des préférences utilisateur,
   - insertion du wallet initial,
   - marquage `onboardingSeen=true`,
   - transition vers la vérification d'accès.

## Détail après connexion

Une fois l'accès validé, l'app:
1. traite les paiements récurrents automatiques,
2. ouvre la HomePage,
3. permet la navigation complète vers les écrans métier:
   - Dashboard,
   - Transactions,
   - À payer,
   - Dettes,
   - Épargne,
   - Projets,
   - Paiements récurrents,
   - Budgets,
   - Paramètres.
