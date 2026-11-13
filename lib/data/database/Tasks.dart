
part of 'app_database.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get projectId => integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get assigneeId => integer().nullable().references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get priority => text().withDefault(const Constant('medium'))(); // low, medium, high, critical
  TextColumn get status => text().withDefault(const Constant('todo'))(); // todo, inProgress, done, cancelled
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Для Задания 1 (Soft Delete)
}
