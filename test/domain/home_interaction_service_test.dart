import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/domain/home_interaction_service.dart';
import 'package:moula_flow/models.dart';

void main() {
  group('HomeInteractionService.walletsToSettle', () {
    test('returns savings wallet when balance reaches target', () {
      final service = HomeInteractionService();
      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Épargne',
          type: WalletType.savings,
          targetAmount: 1000,
        ),
      ];

      final result = service.walletsToSettle(
        wallets: wallets,
        getWalletBalance: (_) => 1200,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'w1');
      expect(result.first.isSettled, isTrue);
    });

    test('applies debt interest before settlement check', () {
      final service = HomeInteractionService();
      final wallets = [
        Wallet(
          id: 'd1',
          name: 'Dette',
          type: WalletType.debt,
          targetAmount: 1000,
          interestRate: 10,
        ),
      ];

      final notSettled = service.walletsToSettle(
        wallets: wallets,
        getWalletBalance: (_) => 1050,
      );
      final settled = service.walletsToSettle(
        wallets: wallets,
        getWalletBalance: (_) => 1100,
      );

      expect(notSettled, isEmpty);
      expect(settled, hasLength(1));
      expect(settled.first.id, 'd1');
      expect(settled.first.isSettled, isTrue);
    });
  });
}
