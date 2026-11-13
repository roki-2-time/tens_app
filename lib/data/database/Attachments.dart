
part of 'app_database.dart';

class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime()();
}