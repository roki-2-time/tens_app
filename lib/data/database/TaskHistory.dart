
part of 'app_database.dart';

class TaskHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get oldStatus => text()();
  TextColumn get newStatus => text()();
  IntColumn get changedByUserId => integer().references(Users, #id)();
  DateTimeColumn get timestamp => dateTime()();
}
