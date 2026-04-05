import 'package:moula_flow/models.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  static Future<void> exportTransactionsToCSV(List<Transaction> transactions) async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'ID',
      'Date',
      'Libellé',
      'Montant',
      'Type',
      'Catégorie',
      'Portefeuille',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final tx in transactions) {
      rows.add([
        tx.id,
        dateFormat.format(tx.date),
        tx.description,
        tx.amount,
        tx.type.name,
        tx.categoryId ?? '',
        tx.walletId ?? '',
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    
    // On mobile/desktop, share the content
    final now = DateTime.now();
    final fileName = 'MoulaFlow_Export_${now.year}${now.month}${now.day}.csv';
    
    await Share.share(
      csvData,
      subject: 'MoulaFlow Transactions Export',
      sharePositionOrigin: null, // Can be useful for iPad
    );
  }
}
