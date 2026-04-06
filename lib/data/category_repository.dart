import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class CategoryRepository {
  final AppDatabase db;

  CategoryRepository(this.db);

  Stream<List<TransactionCategory>> watchCategories() {
    return db.select(db.categories).watch().asyncMap((entities) async {
      await _syncDefaults(entities);
      final updatedEntities = await db.select(db.categories).get();
      return _buildCategoryTree(updatedEntities);
    });
  }

  Future<List<TransactionCategory>> loadCategories() async {
    final entities = await db.select(db.categories).get();
    await _syncDefaults(entities);
    final updatedEntities = await db.select(db.categories).get();
    return _buildCategoryTree(updatedEntities);
  }

  Future<void> _syncDefaults(List<CategoryEntity> existing) async {
    final defaults = _getDefaultCategories();
    final existingIds = existing.map((e) => e.id).toSet();

    await db.transaction(() async {
      for (final def in defaults) {
        if (!existingIds.contains(def.id)) {
          await insertCategory(def);
          existingIds.add(def.id);
        }
        for (final sub in def.subcategories) {
          if (!existingIds.contains(sub.id)) {
            await insertCategory(sub, parentId: def.id);
            existingIds.add(sub.id);
          }
        }
      }
    });
  }

  Future<void> insertCategory(TransactionCategory category, {String? parentId}) async {
    await db.into(db.categories).insert(CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      parentId: Value(parentId),
    ), mode: InsertMode.replace);

    for (final sub in category.subcategories) {
      await insertCategory(sub, parentId: category.id);
    }
  }

  Future<void> insertAll(List<TransactionCategory> categories) async {
    await db.transaction(() async {
      for (final cat in categories) {
        await insertCategory(cat);
      }
    });
  }

  Future<void> saveCategories(List<TransactionCategory> categories) async {
    await db.transaction(() async {
      await db.delete(db.categories).go();
      await insertAll(categories);
    });
  }

  List<TransactionCategory> _buildCategoryTree(List<CategoryEntity> entities) {
    final map = <String, TransactionCategory>{};
    final mainCats = <TransactionCategory>[];

    for (final e in entities) {
      map[e.id] = TransactionCategory(id: e.id, name: e.name, subcategories: []);
    }

    for (final e in entities) {
      if (e.parentId != null) {
        final parent = map[e.parentId!];
        if (parent != null) {
          parent.subcategories.add(map[e.id]!);
        }
      } else {
        mainCats.add(map[e.id]!);
      }
    }
    return mainCats;
  }

  List<TransactionCategory> _getDefaultCategories() {
    return [
      TransactionCategory(id: 'cat_aliment', name: 'Alimentation', subcategories: [
        TransactionCategory(id: 'cat_aliment_courses', name: 'Courses (Hype, Supermarché)'),
        TransactionCategory(id: 'cat_aliment_resto', name: 'Restaurants & Sorties'),
        TransactionCategory(id: 'cat_aliment_cafe', name: 'Bar & Café'),
        TransactionCategory(id: 'cat_aliment_boulange', name: 'Boulangerie & Pâtisserie'),
        TransactionCategory(id: 'cat_aliment_delivery', name: 'Fast-food & Livraison'),
      ]),
      TransactionCategory(id: 'cat_trans', name: 'Transports', subcategories: [
        TransactionCategory(id: 'cat_trans_essence', name: 'Carburant / Recharge électrique'),
        TransactionCategory(id: 'cat_trans_commun', name: 'Transports en commun'),
        TransactionCategory(id: 'cat_trans_taxi', name: 'Taxi / VTC / Uber'),
        TransactionCategory(id: 'cat_trans_long_dist', name: 'Train & Avion (Voyage long)'),
        TransactionCategory(id: 'cat_trans_parking', name: 'Parking & Péage'),
        TransactionCategory(id: 'cat_trans_entretien', name: 'Entretien & Réparations'),
        TransactionCategory(id: 'cat_trans_soft_mobility', name: 'Vélo & Mobilité douce'),
        TransactionCategory(id: 'cat_trans_fines', name: 'Amendes & Contraventions'),
      ]),
      TransactionCategory(id: 'cat_logement', name: 'Logement', subcategories: [
        TransactionCategory(id: 'cat_logement_loyer', name: 'Loyer / Prêt immobilier'),
        TransactionCategory(id: 'cat_logement_charges', name: 'Charges & Syndic'),
        TransactionCategory(id: 'cat_logement_energie', name: 'Électricité & Gaz'),
        TransactionCategory(id: 'cat_logement_eau', name: 'Eau'),
        TransactionCategory(id: 'cat_logement_entret', name: 'Produits d\'entretien'),
        TransactionCategory(id: 'cat_logement_travaux', name: 'Travaux & Rénovations'),
        TransactionCategory(id: 'cat_logement_deco', name: 'Meubles & Déco'),
        TransactionCategory(id: 'cat_logement_jardin', name: 'Jardinage'),
        TransactionCategory(id: 'cat_logement_insurance', name: 'Assurance habitation'),
      ]),
      TransactionCategory(id: 'cat_loisirs', name: 'Loisirs & Culture', subcategories: [
        TransactionCategory(id: 'cat_loisirs_entr', name: 'Cinéma, Musées & Spectacles'),
        TransactionCategory(id: 'cat_loisirs_gaming', name: 'Jeux Vidéo & Gaming'),
        TransactionCategory(id: 'cat_loisirs_books', name: 'Livres & Presse'),
        TransactionCategory(id: 'cat_loisirs_sport', name: 'Sport & Fitness'),
        TransactionCategory(id: 'cat_loisirs_hobbies', name: 'Hobbies & Loisirs créatifs'),
        TransactionCategory(id: 'cat_loisirs_voyage', name: 'Voyages & Vacances'),
        TransactionCategory(id: 'cat_loisirs_hotels', name: 'Hôtels & Hébergement'),
      ]),
      TransactionCategory(id: 'cat_sante', name: 'Santé & Soins', subcategories: [
        TransactionCategory(id: 'cat_sante_medecin', name: 'Consultations & Spécialistes'),
        TransactionCategory(id: 'cat_sante_pharma', name: 'Pharmacie & Médicaments'),
        TransactionCategory(id: 'cat_sante_dentiste', name: 'Dentiste / Opticien'),
        TransactionCategory(id: 'cat_sante_hospital', name: 'Hôpital & Analyses'),
        TransactionCategory(id: 'cat_sante_psy', name: 'Psychologue & Bien-être'),
        TransactionCategory(id: 'cat_sante_mutuelle', name: 'Mutuelle'),
      ]),
      TransactionCategory(id: 'cat_shopping', name: 'Shopping & Beauté', subcategories: [
        TransactionCategory(id: 'cat_shopping_vetements', name: 'Vêtements & Chaussures'),
        TransactionCategory(id: 'cat_shopping_beauty', name: 'Hygiène & Cosmétiques'),
        TransactionCategory(id: 'cat_shopping_hair', name: 'Coiffeur & Esthétique'),
        TransactionCategory(id: 'cat_shopping_tech', name: 'Électronique & High-Tech'),
        TransactionCategory(id: 'cat_shopping_cadeaux', name: 'Cadeaux aux proches'),
      ]),
      TransactionCategory(id: 'cat_abonnements', name: 'Abonnements & Services', subcategories: [
        TransactionCategory(id: 'cat_abonnements_internet', name: 'Internet & Fixe'),
        TransactionCategory(id: 'cat_abonnements_mobile', name: 'Téléphone mobile'),
        TransactionCategory(id: 'cat_abonnements_streaming', name: 'Streaming (Netflix, Spotify...)'),
        TransactionCategory(id: 'cat_abonnements_apps', name: 'Applications & Cloud'),
        TransactionCategory(id: 'cat_abonnements_fitness', name: 'Salles de sport'),
        TransactionCategory(id: 'cat_abonnements_assur', name: 'Assurances (Vie, Obsèques...)'),
      ]),
      TransactionCategory(id: 'cat_famille', name: 'Famille & Enfants', subcategories: [
        TransactionCategory(id: 'cat_famille_garde', name: 'Crèche & Garde'),
        TransactionCategory(id: 'cat_famille_ecole', name: 'Éducation & École'),
        TransactionCategory(id: 'cat_famille_toys', name: 'Jouets & Loisirs enfants'),
        TransactionCategory(id: 'cat_famille_pocket', name: 'Argent de poche'),
        TransactionCategory(id: 'cat_famille_pension', name: 'Pension alimentaire'),
        TransactionCategory(id: 'cat_famille_baby', name: 'Besoins bébé & enfant'),
      ]),
      TransactionCategory(id: 'cat_animaux', name: 'Animaux', subcategories: [
        TransactionCategory(id: 'cat_animaux_nourriture', name: 'Nourriture & Croquettes'),
        TransactionCategory(id: 'cat_animaux_veto', name: 'Vétérinaire & Soins'),
        TransactionCategory(id: 'cat_animaux_accessoires', name: 'Accessoires & Jouets'),
      ]),
      TransactionCategory(id: 'cat_pro', name: 'Professionnel', subcategories: [
        TransactionCategory(id: 'cat_pro_fournitures', name: 'Fournitures & Matériel'),
        TransactionCategory(id: 'cat_pro_logiciels', name: 'Logiciels & Services Cloud'),
        TransactionCategory(id: 'cat_pro_deplacements', name: 'Déplacements & Repas Pro'),
        TransactionCategory(id: 'cat_pro_marketing', name: 'Marketing & Communication'),
      ]),
      TransactionCategory(id: 'cat_epargne', name: 'Épargne & Invest.', subcategories: [
        TransactionCategory(id: 'cat_epargne_livret', name: 'Épargne (Livret A, LDDS...)'),
        TransactionCategory(id: 'cat_epargne_stock', name: 'Bourse & Actions'),
        TransactionCategory(id: 'cat_epargne_crypto', name: 'Crypto-monnaies'),
        TransactionCategory(id: 'cat_epargne_retraite', name: 'Retraite / PER'),
        TransactionCategory(id: 'cat_epargne_assur_vie', name: 'Assurance Vie & Placements'),
      ]),
      TransactionCategory(id: 'cat_dettes', name: 'Dettes & Emprunts', subcategories: [
        TransactionCategory(id: 'cat_dettes_loan_out', name: "Prêt d'argent (Sortie)"),
        TransactionCategory(id: 'cat_dettes_repay_in', name: "Remboursement reçu (Entrée)"),
        TransactionCategory(id: 'cat_dettes_loan_in', name: "Emprunt d'argent (Entrée)"),
        TransactionCategory(id: 'cat_dettes_repay_out', name: "Remboursement effectué (Sortie)"),
      ]),
      TransactionCategory(id: 'cat_impots', name: 'Impôts & Frais', subcategories: [
        TransactionCategory(id: 'cat_impots_revenu', name: 'Impôt sur le revenu'),
        TransactionCategory(id: 'cat_impots_taxes', name: 'Taxes locales (Foncière, etc.)'),
        TransactionCategory(id: 'cat_impots_bancaire', name: 'Frais de gestion bancaire'),
        TransactionCategory(id: 'cat_impots_interests', name: 'Agios & Intérêts'),
      ]),
      TransactionCategory(id: 'cat_dons', name: 'Cadeaux & Dons', subcategories: [
        TransactionCategory(id: 'cat_dons_gifts', name: 'Cadeaux offerts'),
        TransactionCategory(id: 'cat_dons_charity', name: 'Dons & Œuvres caritatives'),
        TransactionCategory(id: 'cat_dons_friends', name: 'Dépenses amicales'),
      ]),
      TransactionCategory(id: 'cat_revenus', name: 'Revenus', subcategories: [
        TransactionCategory(id: 'cat_revenus_salaire', name: 'Salaire & Primes'),
        TransactionCategory(id: 'cat_revenus_rembourse', name: 'Remboursements & Aides'),
        TransactionCategory(id: 'cat_revenus_freelance', name: 'Freelance & Missions'),
        TransactionCategory(id: 'cat_revenus_invest', name: 'Revenus locatifs & Placements'),
        TransactionCategory(id: 'cat_revenus_sales', name: 'Ventes d\'objets (Vinted, etc.)'),
        TransactionCategory(id: 'cat_revenus_gifts', name: 'Cadeaux reçus'),
      ]),
      TransactionCategory(id: 'cat_divers', name: 'Divers', subcategories: [
        TransactionCategory(id: 'cat_divers_atlantis', name: 'À classer'),
        TransactionCategory(id: 'cat_divers_cash', name: 'Retrait d\'espèces'),
      ]),
    ];
  }
}
