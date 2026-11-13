
part of 'app_database.dart';

class ProjectMembers extends Table {
  IntColumn get projectId => integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()(); // Owner, Admin, Member

  @override
  Set<Column> get primaryKey => {projectId, userId};
}