import '../models.dart';

enum TagQueryOperator { and, or }

class TagQuery {
  final Set<String> includeTags;
  final Set<String> excludeTags;
  final Set<TagType> includeTypes;
  final Set<TagType> excludeTypes;
  final TagQueryOperator operatorMode;

  const TagQuery({
    this.includeTags = const {},
    this.excludeTags = const {},
    this.includeTypes = const {},
    this.excludeTypes = const {},
    this.operatorMode = TagQueryOperator.or,
  });
}

class TagFilterService {
  List<Transaction> filterTransactions({
    required List<Transaction> transactions,
    required List<TagDefinition> tagDefinitions,
    required TagQuery query,
  }) {
    final byName = <String, TagDefinition>{
      for (final t in tagDefinitions) t.name.toLowerCase(): t,
    };
    final includes = query.includeTags.map((e) => e.toLowerCase()).toSet();
    final excludes = query.excludeTags.map((e) => e.toLowerCase()).toSet();

    return transactions.where((tx) {
      final txTags = tx.tags.map((e) => e.toLowerCase()).toSet();
      final txTypes = txTags
          .map((name) => byName[name]?.type)
          .whereType<TagType>()
          .toSet();

      if (excludes.isNotEmpty && txTags.any(excludes.contains)) return false;
      if (query.excludeTypes.isNotEmpty && txTypes.any(query.excludeTypes.contains)) {
        return false;
      }

      final nameCheck = includes.isEmpty
          ? true
          : (query.operatorMode == TagQueryOperator.and
              ? includes.every(txTags.contains)
              : includes.any(txTags.contains));

      final typeCheck = query.includeTypes.isEmpty
          ? true
          : (query.operatorMode == TagQueryOperator.and
              ? query.includeTypes.every(txTypes.contains)
              : query.includeTypes.any(txTypes.contains));

      return nameCheck && typeCheck;
    }).toList();
  }
}
