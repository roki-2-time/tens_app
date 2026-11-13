
part of 'app_database.dart';

// Описание таблицы пользователей
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
}