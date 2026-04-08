class CurrencyOption {
  final String code;
  final String symbol;
  final String label;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.label,
  });
}

const List<CurrencyOption> kSupportedCurrencies = [
  CurrencyOption(code: 'MGA', symbol: 'Ar', label: 'Ariary malgache'),
  CurrencyOption(code: 'EUR', symbol: '€', label: 'Euro'),
  CurrencyOption(code: 'USD', symbol: r'$', label: 'US Dollar'),
  CurrencyOption(code: 'GBP', symbol: '£', label: 'British Pound'),
  CurrencyOption(code: 'XOF', symbol: 'FCFA', label: 'Franc CFA'),
];

String symbolFromCurrencyCode(String code) {
  for (final currency in kSupportedCurrencies) {
    if (currency.code == code) return currency.symbol;
  }
  return 'Ar';
}
