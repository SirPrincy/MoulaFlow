import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'storage_keys.dart';

class CategoryRepository {
  Future<List<TransactionCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? catsData = prefs.getString(StorageKeys.categories);
    if (catsData != null) {
      final List<dynamic> jsonList = jsonDecode(catsData);
      return jsonList.map((json) => TransactionCategory.fromJson(json)).toList();
    } else {
      final defaultCategories = _getDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
  }

  Future<void> saveCategories(List<TransactionCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.categories, jsonEncode(categories.map((c) => c.toJson()).toList()));
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
      ]),
      TransactionCategory(id: 'cat_divers', name: 'Divers'),
    ];
  }
}
