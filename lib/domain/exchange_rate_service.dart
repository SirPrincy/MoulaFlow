import '../data/settings_repository.dart';

class ExchangeRateService {
  final SettingsRepository settingsRepository;

  ExchangeRateService(this.settingsRepository);

  Future<void> setRate({
    required String fromCode,
    required String toCode,
    required double rate,
    DateTime? effectiveDate,
  }) async {
    if (rate <= 0) {
      throw ArgumentError.value(rate, 'rate', 'Rate must be > 0');
    }
    final targetDate = effectiveDate ?? DateTime.now();
    final dateKey = _formatDateKey(targetDate);
    await settingsRepository.saveExchangeRate(
      fromCode,
      toCode,
      rate,
      effectiveDate: dateKey,
    );
    await settingsRepository.saveExchangeRate(
      toCode,
      fromCode,
      1 / rate,
      effectiveDate: dateKey,
    );
  }

  Future<double> getRate({
    required String fromCode,
    required String toCode,
    DateTime? atDate,
  }) async {
    if (fromCode == toCode) return 1;
    final rates = await settingsRepository.loadExchangeRates();
    final pairKey = '${fromCode}_$toCode';
    final targetDate = atDate ?? DateTime.now();

    final exactKey = '${_formatDateKey(targetDate)}|$pairKey';
    if (rates.containsKey(exactKey)) {
      return rates[exactKey]!;
    }
    if (rates.containsKey(pairKey)) {
      return rates[pairKey]!;
    }

    DateTime? bestDate;
    double? bestRate;
    for (final entry in rates.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) continue;
      if (parts[1] != pairKey) continue;
      final date = DateTime.tryParse(parts[0]);
      if (date == null || date.isAfter(targetDate)) continue;
      if (bestDate == null || date.isAfter(bestDate)) {
        bestDate = date;
        bestRate = entry.value;
      }
    }
    return bestRate ?? 1;
  }

  Future<double> convert({
    required double amount,
    required String fromCode,
    required String toCode,
    DateTime? atDate,
  }) async {
    final rate = await getRate(
      fromCode: fromCode,
      toCode: toCode,
      atDate: atDate,
    );
    return amount * rate;
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
