import '../models.dart';

class HomeInteractionService {
  List<Wallet> walletsToSettle({
    required List<Wallet> wallets,
    required double Function(String walletId) getWalletBalance,
  }) {
    final settled = <Wallet>[];

    for (final wallet in wallets) {
      if (wallet.isSettled || wallet.targetAmount == null) {
        continue;
      }

      var effectiveTarget = wallet.targetAmount!;
      if (wallet.type == WalletType.debt &&
          wallet.interestRate != null &&
          wallet.interestRate! > 0) {
        effectiveTarget = effectiveTarget * (1 + wallet.interestRate! / 100);
      }

      final balance = getWalletBalance(wallet.id);
      if (balance >= effectiveTarget) {
        settled.add(wallet.copyWith(isSettled: true));
      }
    }

    return settled;
  }
}
