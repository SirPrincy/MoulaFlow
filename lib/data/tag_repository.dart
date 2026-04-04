import 'package:moula_flow/data/database/app_database.dart';
import 'package:drift/drift.dart';
import '../models.dart';

class TagRepository {
  final AppDatabase db;

  TagRepository(this.db);

  TagEntity _toEntity(TagDefinition tag) {
    return TagEntity(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      icon: tag.icon,
      description: tag.description,
      goalAmount: tag.goalAmount,
      type: tag.type,
      createdAt: tag.createdAt,
    );
  }

  TagDefinition _fromEntity(TagEntity entity) {
    return TagDefinition(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      color: entity.color,
      icon: entity.icon,
      description: entity.description,
      goalAmount: entity.goalAmount,
      createdAt: entity.createdAt,
    );
  }

  Future<List<TagDefinition>> loadTags() async {
    final entities = await db.select(db.tags).get();
    return entities.map(_fromEntity).toList();
  }

  Stream<List<TagDefinition>> watchTags() {
    return db.select(db.tags).watch().map((entities) => entities.map(_fromEntity).toList());
  }

  Future<void> insertTag(TagDefinition tag) async {
    await db.into(db.tags).insert(_toEntity(tag));
  }

  Future<void> updateTag(TagDefinition tag) async {
    await db.update(db.tags).replace(_toEntity(tag));
  }

  Future<void> deleteTag(String id) async {
    await (db.delete(db.tags)..where((t) => t.id.equals(id))).go();
  }

  Future<List<TagDefinition>> getTagsForTransaction(String transactionId) async {
    final query = db.select(db.tags).join([
      innerJoin(
        db.transactionTags,
        db.transactionTags.tagId.equalsExp(db.tags.id),
      ),
    ])
      ..where(db.transactionTags.transactionId.equals(transactionId));

    final rows = await query.get();
    return rows.map((row) => _fromEntity(row.readTable(db.tags))).toList();
  }

  Future<void> setTagsForTransaction(String transactionId, List<String> tagIds) async {
    await db.transaction(() async {
      // Remove old links
      await (db.delete(db.transactionTags)..where((t) => t.transactionId.equals(transactionId))).go();
      
      // Add new links
      for (final tagId in tagIds) {
        await db.into(db.transactionTags).insert(
              TransactionTagsCompanion.insert(
                transactionId: transactionId,
                tagId: tagId,
              ),
            );
      }
    });
  }
}
