import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'Attachments.dart';
part 'Comments.dart';
part 'ProjectMembers.dart';
part 'Projects.dart';
part 'TaskHistory.dart';
part 'Tasks.dart';
part 'Users.dart';

part 'app_database.g.dart';

// Главный класс базы данных с миграциями
@DriftDatabase(tables: [Users, Projects, ProjectMembers, Tasks, TaskHistory, Comments, Attachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            // Пример миграции: добавление поля priority (Задание 4.2)
            await m.addColumn(tasks, tasks.priority);
            await customStatement(
                "UPDATE tasks SET priority = 'medium' WHERE priority IS NULL;");
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'task_flow_db');
  }

  AppDatabase.forTesting(super.e);
}