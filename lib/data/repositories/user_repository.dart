import 'package:drift/drift.dart';
import '../database/app_database.dart';

class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  // Получение списка всех пользователей (реактивно)
  Stream<List<User>> watchUsers() => _db.select(_db.users).watch();

  // Добавление пользователя (email уникален)
  Future<int> createUser({required String name, required String email}) async {
    return await _db.into(_db.users).insert(
      UsersCompanion.insert(
        name: name,
        email: email,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Удаление пользователя с проверкой: есть ли у него незавершённые задачи
  Future<bool> deleteUser(int userId) async {
    // Ищем незавершённые задачи исполнителя (статус НЕ 'done' и НЕ 'cancelled')
    final activeTasksCount = await (_db.select(_db.tasks)
      ..where((t) =>
      t.assigneeId.equals(userId) &
      t.status.isNotIn(['done', 'cancelled']) &
      t.deletedAt.isNull()))
        .get();

    if (activeTasksCount.isNotEmpty) {
      // Запрещаем удаление, если есть незавершённые задачи[cite: 2]
      throw Exception('Нельзя удалить пользователя с незавершёнными задачами!');
    }

    // Если всё чисто — удаляем
    return await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go() > 0;
  }
}