
part of 'app_database.dart';

class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get authorId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()(); // Переименовали 'text' в 'body'
  DateTimeColumn get createdAt => dateTime()();
}