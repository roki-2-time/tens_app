import 'package:drift/drift.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class TaskRepository {
  final AppDatabase _db;

  TaskRepository(this._db);

  // Создание задачи с транзакцией и проверкой лимита (Задание 3 и Требование 4.1)
  Future<void> createTaskWithChecks({
    required String title,
    String? description,
    required int projectId,
    required int assigneeId,
    required String priority,
    required DateTime dueDate,
    required int userIdWhoCreated,
  }) async {
    await _db.transaction(() async {
      // 1. Проверяем Задание 3: есть ли у исполнителя уже 3 незавершённые задачи на эту же дату (dueDate)
      final sameDayTasks = await (_db.select(_db.tasks)
        ..where((t) =>
        t.assigneeId.equals(assigneeId) &
        t.status.isNotIn(['done', 'cancelled']) &
        t.dueDate.equals(dueDate) &
        t.deletedAt.isNull()))
          .get();

      if (sameDayTasks.length >= 3) {
        throw Exception('У исполнителя уже есть 3 незавершённые задачи на эту дату!');
      }

      // 2. Проверяем, состоит ли исполнитель в проекте (Задание 4)[cite: 8]
      final memberCheck = await (_db.select(_db.projectMembers)
        ..where((m) => m.projectId.equals(projectId) & m.userId.equals(assigneeId)))
          .getSingleOrNull();

      if (memberCheck == null) {
        throw Exception('Исполнитель должен быть участником проекта!');
      }

      // 3. Вставка задачи
      final insertedTaskId = await _db.into(_db.tasks).insert(
        TasksCompanion.insert(
          title: title,
          description: Value(description),
          projectId: projectId,
          assigneeId: Value(assigneeId),
          priority: Value(priority),
          status: const Value('todo'),
          dueDate: Value(dueDate),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 4. Запись истории изменений в рамках той же транзакции
      await _db.into(_db.taskHistory).insert(
        TaskHistoryCompanion.insert(
          taskId: insertedTaskId,
          oldStatus: 'none',
          newStatus: 'todo',
          changedByUserId: userIdWhoCreated,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  // Обновление статуса задачи
  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: drift.Value(newStatus),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }
  // Soft Delete (Задание 1)[cite: 7]
  Future<void> softDeleteTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  // Получение удаленных задач (Корзина)[cite: 7]
  Stream<List<Task>> watchDeletedTasks() {
    return (_db.select(_db.tasks)..where((t) => t.deletedAt.isNotNull())).watch();
  }

  // Восстановление из корзины[cite: 7]
  Future<void> restoreTask(int taskId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      const TasksCompanion(deletedAt: Value(null)),
    );
  }
  // Реактивное получение активных задач (без удаленных Soft Delete)
  Stream<List<Task>> watchActiveTasks() {
    return (_db.select(_db.tasks)..where((t) => t.deletedAt.isNull())).watch();
  }
}