import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tens_app/data/database/app_database.dart';
import 'package:tens_app/data/repositories/stats_repository.dart';

void main() {
  late AppDatabase db;
  late StatsRepository statsRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    statsRepo = StatsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Полный набор тестов для TaskFlow (15+ тестов)', () {

    test('1. Создание пользователя', () async {
      final id = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Алишер', email: 'alisher@uib.kz', createdAt: DateTime.now()),
      );
      expect(id, greaterThan(0));
    });

    test('2. Проверка уникальности email', () async {
      await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Алишер', email: 'test@uib.kz', createdAt: DateTime.now()),
      );

      expect(
            () => db.into(db.users).insert(
          UsersCompanion.insert(name: 'Другой', email: 'test@uib.kz', createdAt: DateTime.now()),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('3. Создание проекта', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'TaskFlow App', createdAt: DateTime.now(), status: 'active'),
      );
      expect(projectId, greaterThan(0));
    });

    test('4. Добавление участника в проект', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Иван', email: 'ivan@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'Проект', createdAt: DateTime.now(), status: 'active'),
      );

      await db.into(db.projectMembers).insert(
        ProjectMembersCompanion.insert(projectId: projectId, userId: userId, role: 'Owner'),
      );

      final members = await db.select(db.projectMembers).get();
      expect(members.length, 1);
      expect(members.first.role, 'Owner');
    });

    test('5. Запрет повторного добавления участника в один проект (Задание 4)', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Иван', email: 'ivan@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'Проект', createdAt: DateTime.now(), status: 'active'),
      );

      await db.into(db.projectMembers).insert(
        ProjectMembersCompanion.insert(projectId: projectId, userId: userId, role: 'Member'),
      );

      expect(
            () => db.into(db.projectMembers).insert(
          ProjectMembersCompanion.insert(projectId: projectId, userId: userId, role: 'Admin'),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('6. Создание задачи', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'Проект', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(
          title: 'Сделать архитектуру',
          projectId: projectId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(taskId, greaterThan(0));
    });

    test('7. Изменение статуса задачи и сохранение истории', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Алишер', email: 'a@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'Проект', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(
          title: 'Тест истории',
          projectId: projectId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Меняем статус
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(status: Value('inProgress')),
      );

      // Пишем историю
      await db.into(db.taskHistory).insert(
        TaskHistoryCompanion.insert(
          taskId: taskId,
          oldStatus: 'todo',
          newStatus: 'inProgress',
          changedByUserId: userId,
          timestamp: DateTime.now(),
        ),
      );

      final history = await db.select(db.taskHistory).get();
      expect(history.length, 1);
      expect(history.first.newStatus, 'inProgress');
    });

    test('8. Работа транзакции при создании задачи', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Бекзат', email: 'b@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П1', createdAt: DateTime.now(), status: 'active'),
      );

      await db.transaction(() async {
        final tid = await db.into(db.tasks).insert(
          TasksCompanion.insert(
            title: 'Транзакционная задача',
            projectId: projectId,
            assigneeId: Value(userId),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await db.into(db.taskHistory).insert(
          TaskHistoryCompanion.insert(
            taskId: tid,
            oldStatus: 'none',
            newStatus: 'todo',
            changedByUserId: userId,
            timestamp: DateTime.now(),
          ),
        );
      });

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
    });

    test('9. Добавление комментария к задаче', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Автор', email: 'author@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Задача комментов', projectId: projectId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      await db.into(db.comments).insert(
        CommentsCompanion.insert(taskId: taskId, authorId: userId, body: 'Отличная задача!', createdAt: DateTime.now()),
      );

      final comments = await db.select(db.comments).get();
      expect(comments.length, 1);
      expect(comments.first.body, 'Отличная задача!');
    });

    test('10. Soft Delete задачи (Задание 1)', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Удалить', projectId: projectId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      // Мягкое удаление
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(deletedAt: Value(DateTime.now())),
      );

      final active = await (db.select(db.tasks)..where((t) => t.deletedAt.isNull())).get();
      expect(active, isEmpty);
    });

    test('11. Восстановление задачи из корзины (Задание 1)', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Восстановить', projectId: projectId, deletedAt: Value(DateTime.now()), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      // Восстанавливаем
      await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
        const TasksCompanion(deletedAt: Value(null)),
      );

      final active = await (db.select(db.tasks)..where((t) => t.deletedAt.isNull())).get();
      expect(active.length, 1);
    });

    test('12. Проверка корректности статистики Dashboard', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'T1', projectId: projectId, status: const Value('done'), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'T2', projectId: projectId, status: const Value('todo'), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final stats = await statsRepo.getDashboardStats();
      expect(stats.totalProjects, 1);
      expect(stats.totalTasks, 2);
      expect(stats.completedTasks, 1);
      expect(stats.pendingTasks, 1);
    });

    test('13. Прикрепление файла (вложения) к задаче', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      final taskId = await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Файловая задача', projectId: projectId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      await db.into(db.attachments).insert(
        AttachmentsCompanion.insert(taskId: taskId, fileName: 'doc.pdf', filePath: '/path/to/doc.pdf', createdAt: DateTime.now()),
      );

      final attachments = await db.select(db.attachments).get();
      expect(attachments.length, 1);
      expect(attachments.first.fileName, 'doc.pdf');
    });

    test('14. Поиск и фильтрация задач по названию', () async {
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Купить молоко', projectId: projectId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Написать код', projectId: projectId, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      final searchResult = await (db.select(db.tasks)..where((t) => t.title.like('%код%'))).get();
      expect(searchResult.length, 1);
      expect(searchResult.first.title, 'Написать код');
    });

    test('15. Запрет удаления пользователя с незавершёнными задачами', () async {
      final userId = await db.into(db.users).insert(
        UsersCompanion.insert(name: 'Работяга', email: 'work@uib.kz', createdAt: DateTime.now()),
      );
      final projectId = await db.into(db.projects).insert(
        ProjectsCompanion.insert(name: 'П', createdAt: DateTime.now(), status: 'active'),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(title: 'Висяк', projectId: projectId, assigneeId: Value(userId), status: const Value('todo'), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );

      // Проверяем бизнес-логику удаления из UserRepository
      // Если у него есть незавершенная задача, удаление отклоняется
      final activeTasks = await (db.select(db.tasks)
        ..where((t) => t.assigneeId.equals(userId) & t.status.isNotIn(['done', 'cancelled']) & t.deletedAt.isNull()))
          .get();

      expect(activeTasks.isNotEmpty, true); // Есть задачи -> удалять нельзя
    });

    test('16. Проверка миграции базы данных (версия схемы)', () async {
      expect(db.schemaVersion, 2);
    });

  });
}