import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class ProjectRepository {
  final AppDatabase db;

  ProjectRepository(this.db);

  Stream<List<Project>> watchProjects() {
    return db.select(db.projects).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<Project>> loadProjects() async {
    final entities = await db.select(db.projects).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> insertProject(Project project) async {
    await db.into(db.projects).insert(_mapModelToCompanion(project), mode: InsertMode.replace);
  }

  Future<void> updateProject(Project project) async {
    await db.update(db.projects).replace(_mapModelToCompanion(project));
  }

  Future<void> deleteProject(String id) async {
    await (db.delete(db.projects)..where((t) => t.id.equals(id))).go();
  }

  Project _mapEntityToModel(ProjectEntity e) {
    return Project(
      id: e.id,
      title: e.title,
      icon: e.icon,
      linkedWalletId: e.linkedWalletId,
      items: e.items,
    );
  }

  ProjectsCompanion _mapModelToCompanion(Project p) {
    return ProjectsCompanion(
      id: Value(p.id),
      title: Value(p.title),
      icon: Value(p.icon),
      linkedWalletId: Value(p.linkedWalletId),
      items: Value(p.items),
    );
  }
}
