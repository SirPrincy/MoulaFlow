import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'storage_keys.dart';

class CategoryRepository {
  Future<List<TransactionCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? catsData = prefs.getString(StorageKeys.categories);
    final defaultCategories = _getDefaultCategories();

    if (catsData != null) {
      final List<dynamic> jsonList = jsonDecode(catsData);
      final savedCategories = jsonList.map((json) => TransactionCategory.fromJson(json)).toList();
      final mergedCategories = _mergeWithDefaults(savedCategories, defaultCategories);

      if (_categoriesChanged(savedCategories, mergedCategories)) {
        await saveCategories(mergedCategories);
      }
      return mergedCategories;
    } else {
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  Future<void> saveCategories(List<TransactionCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.categories, jsonEncode(categories.map((c) => c.toJson()).toList()));
  }

  List<TransactionCategory> _mergeWithDefaults(
    List<TransactionCategory> saved,
    List<TransactionCategory> defaults,
  ) {
    final merged = List<TransactionCategory>.from(saved);

    for (final defaultCategory in defaults) {
      final index = merged.indexWhere((c) => c.id == defaultCategory.id);
      if (index == -1) {
        merged.add(defaultCategory);
      } else {
        final existing = merged[index];
        final mergedSubcategories = List<TransactionCategory>.from(existing.subcategories);
        for (final defaultSub in defaultCategory.subcategories) {
          final exists = mergedSubcategories.any((s) => s.id == defaultSub.id);
          if (!exists) {
            mergedSubcategories.add(defaultSub);
          }
        }
        merged[index] = TransactionCategory(
          id: existing.id,
          name: existing.name,
          subcategories: mergedSubcategories,
        );
      }
    }

    return merged;
  }

  bool _categoriesChanged(List<TransactionCategory> before, List<TransactionCategory> after) {
    return jsonEncode(before.map((c) => c.toJson()).toList()) !=
        jsonEncode(after.map((c) => c.toJson()).toList());
  }

  List<TransactionCategory> _getDefaultCategories() {
    return [
      TransactionCategory(id: 'cat_aliment', name: 'Alimentation', subcategories: [
        TransactionCategory(id: 'cat_aliment_courses', name: 'Courses'),
        TransactionCategory(id: 'cat_aliment_resto', name: 'Restaurant'),
        TransactionCategory(id: 'cat_aliment_cafe', name: 'Bar & Café'),
      ]),
      TransactionCategory(id: 'cat_trans', name: 'Transports', subcategories: [
        TransactionCategory(id: 'cat_trans_essence', name: 'Carburant'),
        TransactionCategory(id: 'cat_trans_commun', name: 'Transports en commun'),
        TransactionCategory(id: 'cat_trans_parking', name: 'Parking & Péage'),
        TransactionCategory(id: 'cat_trans_entretien', name: 'Entretien véhicule'),
      ]),
      TransactionCategory(id: 'cat_logement', name: 'Logement', subcategories: [
        TransactionCategory(id: 'cat_logement_loyer', name: 'Loyer / Crédit'),
        TransactionCategory(id: 'cat_logement_energie', name: 'Électricité & Gaz'),
        TransactionCategory(id: 'cat_logement_eau', name: 'Eau'),
        TransactionCategory(id: 'cat_logement_assurance', name: 'Assurance habitation'),
        TransactionCategory(id: 'cat_logement_travaux', name: 'Travaux & Déco'),
      ]),
      TransactionCategory(id: 'cat_loisirs', name: 'Loisirs', subcategories: [
        TransactionCategory(id: 'cat_loisirs_sorties', name: 'Sorties & Spectacles'),
        TransactionCategory(id: 'cat_loisirs_abos', name: 'Abonnements (Netflix, Spotify...)'),
        TransactionCategory(id: 'cat_loisirs_sport', name: 'Sport'),
        TransactionCategory(id: 'cat_loisirs_voyage', name: 'Voyages & Vacances'),
      ]),
      TransactionCategory(id: 'cat_sante', name: 'Santé', subcategories: [
        TransactionCategory(id: 'cat_sante_medecin', name: 'Médecin'),
        TransactionCategory(id: 'cat_sante_pharma', name: 'Pharmacie'),
        TransactionCategory(id: 'cat_sante_dentiste', name: 'Dentiste / Opticien'),
        TransactionCategory(id: 'cat_sante_hospital', name: 'Hôpital & Analyses'),
        TransactionCategory(id: 'cat_sante_mutuelle', name: 'Mutuelle'),
      ]),
      TransactionCategory(id: 'cat_shopping', name: 'Shopping', subcategories: [
        TransactionCategory(id: 'cat_shopping_vetements', name: 'Vêtements & Accessoires'),
        TransactionCategory(id: 'cat_shopping_tech', name: 'High-Tech'),
        TransactionCategory(id: 'cat_shopping_cadeaux', name: 'Cadeaux'),
      ]),
      TransactionCategory(id: 'cat_impots', name: 'Impôts & Frais', subcategories: [
        TransactionCategory(id: 'cat_impots_revenu', name: 'Impôt sur le revenu'),
        TransactionCategory(id: 'cat_impots_taxes', name: 'Taxes locales'),
        TransactionCategory(id: 'cat_impots_bancaire', name: 'Frais bancaires'),
      ]),
      TransactionCategory(id: 'cat_revenus', name: 'Revenus', subcategories: [
        TransactionCategory(id: 'cat_revenus_salaire', name: 'Salaire'),
        TransactionCategory(id: 'cat_revenus_primes', name: 'Primes & Bonus'),
        TransactionCategory(id: 'cat_revenus_rembourse', name: 'Remboursements'),
        TransactionCategory(id: 'cat_revenus_freelance', name: 'Freelance'),
        TransactionCategory(id: 'cat_revenus_invest', name: 'Investissements'),
      ]),
      TransactionCategory(id: 'cat_education', name: 'Éducation', subcategories: [
        TransactionCategory(id: 'cat_education_scolarite', name: 'Scolarité'),
        TransactionCategory(id: 'cat_education_livres', name: 'Livres & Matériel'),
        TransactionCategory(id: 'cat_education_formation', name: 'Formations en ligne'),
      ]),
      TransactionCategory(id: 'cat_famille', name: 'Famille & Enfants', subcategories: [
        TransactionCategory(id: 'cat_famille_garde', name: 'Garde d\'enfants'),
        TransactionCategory(id: 'cat_famille_ecole', name: 'Frais scolaires'),
        TransactionCategory(id: 'cat_famille_besoins', name: 'Besoins du quotidien'),
      ]),
      TransactionCategory(id: 'cat_animaux', name: 'Animaux', subcategories: [
        TransactionCategory(id: 'cat_animaux_nourriture', name: 'Nourriture'),
        TransactionCategory(id: 'cat_animaux_veto', name: 'Vétérinaire'),
        TransactionCategory(id: 'cat_animaux_accessoires', name: 'Accessoires'),
      ]),
      TransactionCategory(id: 'cat_assurances', name: 'Assurances', subcategories: [
        TransactionCategory(id: 'cat_assurances_auto', name: 'Auto'),
        TransactionCategory(id: 'cat_assurances_habitation', name: 'Habitation'),
        TransactionCategory(id: 'cat_assurances_sante', name: 'Santé'),
      ]),
      TransactionCategory(id: 'cat_pro', name: 'Pro / Business', subcategories: [
        TransactionCategory(id: 'cat_pro_fournitures', name: 'Fournitures'),
        TransactionCategory(id: 'cat_pro_logiciels', name: 'Logiciels & SaaS'),
        TransactionCategory(id: 'cat_pro_deplacements', name: 'Déplacements pro'),
      ]),
      TransactionCategory(id: 'cat_epargne', name: 'Épargne & Placements', subcategories: [
        TransactionCategory(id: 'cat_epargne_livret', name: 'Livret'),
        TransactionCategory(id: 'cat_epargne_invest', name: 'Investissements'),
        TransactionCategory(id: 'cat_epargne_retraite', name: 'Retraite'),
      ]),
      TransactionCategory(id: 'cat_abonnements', name: 'Abonnements', subcategories: [
        TransactionCategory(id: 'cat_abonnements_streaming', name: 'Streaming'),
        TransactionCategory(id: 'cat_abonnements_mobile', name: 'Téléphone & Internet'),
        TransactionCategory(id: 'cat_abonnements_apps', name: 'Apps & Cloud'),
      ]),
      TransactionCategory(id: 'cat_divers', name: 'Divers'),
    ];
  }
}
