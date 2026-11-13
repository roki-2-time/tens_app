import 'package:drift/drift.dart';
import '../database/app_database.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  Stream<List<Project>> watchProjects() => _db.select(_db.projects).watch();

  // Создание проекта
  Future<int> createProject({
    required String name,
    String? description,
    DateTime? dueDate,
  }) async {
    return await _db.into(_db.projects).insert(
      ProjectsCompanion.insert(
        name: name,
        description: Value(description),
        createdAt: DateTime.now(),
        dueDate: Value(dueDate),
        status: 'active', // active, completed, archived[cite: 3]
      ),
    );
  }

  // Добавьте этот метод внутрь класса ProjectRepository
  Future<void> seedProjects(int count) async {
    final statuses = ['active', 'completed', 'archived'];
    final now = DateTime.now();

    // Генерируем список проектов
    final projectsList = List.generate(count, (index) {
      final number = index + 1;
      return ProjectsCompanion.insert(
        name: 'Тестовый проект №$number',
        description: Value('Автоматически сгенерированное описание для проекта $number'),
        createdAt: now,
        dueDate: Value(now.add(Duration(days: (number * 10)))), // Дедлайн через каждые 10 дней
        status: statuses[index % statuses.length], // Чередуем статусы
      );
    });

    // Пакетная вставка всех проектов в БД
    await _db.batch((batch) {
      batch.insertAll(_db.projects, projectsList);
    });
  }
  // Добавление участника в проект с ролью (Задание 4: проверка на дубликаты)[cite: 8]
  Future<void> addMemberToProject({
    required int projectId,
    required int userId,
    required String role, // Owner, Admin, Member[cite: 3]
  }) async {
    // Проверка: состоит ли уже пользователь в проекте, чтобы избежать повторного добавления
    final existing = await (_db.select(_db.projectMembers)
      ..where((m) => m.projectId.equals(projectId) & m.userId.equals(userId)))
        .getSingleOrNull();

    if (existing != null) {
      throw Exception('Пользователь уже добавлен в этот проект!');
    }

    await _db.into(_db.projectMembers).insert(
      ProjectMembersCompanion.insert(
        projectId: projectId,
        userId: userId,
        role: role,
      ),
    );
  }
}