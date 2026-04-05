### TODO : Database

Points à améliorer et optimisations
1. Intégrité des Données (Clés Étrangères)
Actuellement, beaucoup de tes colonnes (comme walletId dans Transactions) sont des TextColumn simples sans contraintes explicites de référence dans le code de définition, sauf pour TransactionTags.

Amélioration : Utilise .references(Wallets, #id) pour toutes les relations (Transactions -> Wallets, Budgets -> Budgets, etc.). Cela garantit que tu ne peux pas créer une transaction pour un portefeuille qui n'existe pas.

2. Gestion des Devises
Tu habites à Madagascar, où la monnaie (Ariary) a des valeurs numériques importantes.

Problème potentiel : Le type RealColumn (double) peut arrondir de manière imprévue lors de calculs financiers complexes.

Amélioration : Pour une application de finance, il est souvent préférable de stocker les montants en Cents (Entiers) pour éviter les erreurs de virgule flottante.

Exemple : 1000.50 Ar devient 100050 dans la base de données.

3. Optimisation des Listes (Converters)
Tu utilises StringListConverter pour stocker des IDs séparés par des virgules dans une seule colonne (ex: walletIds dans Budgets).

Le risque : C'est difficile à requêter nativement en SQL (ex: "Trouver tous les budgets qui incluent le portefeuille X").

Amélioration : Pour une scalabilité maximale, crée des tables de jointure (comme tu l'as fait pour TransactionTags). Cependant, pour des listes très courtes, ton approche actuelle avec TypeConverter est acceptable pour simplifier le code Flutter.

4. Statut des Transactions
Amélioration : Ajoute un champ isCleared ou status (Enum) à la table Transactions. Cela permet de distinguer une transaction "effectuée" d'une transaction "en attente" (utile pour le pointage bancaire).

5. Indexation pour la Performance
Ton application va accumuler des milliers de transactions.

Amélioration : Ajoute des index sur les colonnes souvent filtrées :

Dart
@override
List<Index> get indexes => [Index('idx_transaction_date', 'date')];

Suggestions de fonctionnalités techniques
Soft Delete : Ajoute une colonne deletedAt (nullable) sur les portefeuilles et catégories au lieu de les supprimer réellement. Cela évite de casser l'historique des transactions passées.

Audit : Ajoute updatedAt sur les tables Wallets et Budgets pour synchroniser plus facilement les données si tu ajoutes un backend plus tard.