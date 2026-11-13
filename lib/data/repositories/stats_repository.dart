import 'package:drift/drift.dart';
import '../database/app_database.dart';

// Модель для хранения общей статистики
class DashboardStats {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final Map<String, int> tasksByPriority;

  DashboardStats({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.tasksByPriority,
  });
}

class StatsRepository {
  final AppDatabase _db;

  StatsRepository(this._db);

  // 1. Получение сводной статистики через SQL-выборки
  Future<DashboardStats> getDashboardStats() async {
    final now = DateTime.now();

    // Общее количество проектов
    final projectsCountExpr = _db.projects.id.count();
    final projectsQuery = _db.selectOnly(_db.projects)..addColumns([projectsCountExpr]);
    final totalProjects = await projectsQuery.map((row) => row.read(projectsCountExpr)).getSingle() ?? 0;

    // Общее количество активных (не удаленных) задач
    final tasksCountExpr = _db.tasks.id.count();
    final tasksQuery = _db.selectOnly(_db.tasks)
      ..addColumns([tasksCountExpr])
      ..where(_db.tasks.deletedAt.isNull());
    final totalTasks = await tasksQuery.map((row) => row.read(tasksCountExpr)).getSingle() ?? 0;

    // Завершенные задачи (done)
    final completedQuery = _db.selectOnly(_db.tasks)
      ..addColumns([tasksCountExpr])
      ..where(_db.tasks.status.equals('done') & _db.tasks.deletedAt.isNull());
    final completedTasks = await completedQuery.map((row) => row.read(tasksCountExpr)).getSingle() ?? 0;

    // Незавершенные задачи (не done и не cancelled)
    final pendingQuery = _db.selectOnly(_db.tasks)
      ..addColumns([tasksCountExpr])
      ..where(_db.tasks.status.isNotIn(['done', 'cancelled']) & _db.tasks.deletedAt.isNull());
    final pendingTasks = await pendingQuery.map((row) => row.read(tasksCountExpr)).getSingle() ?? 0;

    // Просроченные задачи (дедлайн прошёл и статус не done/cancelled)
    final overdueQuery = _db.selectOnly(_db.tasks)
      ..addColumns([tasksCountExpr])
      ..where(
        _db.tasks.dueDate.isSmallerThanValue(now) &
        _db.tasks.status.isNotIn(['done', 'cancelled']) &
        _db.tasks.deletedAt.isNull(),
      );
    final overdueTasks = await overdueQuery.map((row) => row.read(tasksCountExpr)).getSingle() ?? 0;

    // Количество задач по каждому приоритету (GROUP BY)
    final priorityCountExpr = _db.tasks.id.count();
    final priorityQuery = _db.selectOnly(_db.tasks)
      ..addColumns([_db.tasks.priority, priorityCountExpr])
      ..where(_db.tasks.deletedAt.isNull())
      ..groupBy([_db.tasks.priority]);

    final priorityRows = await priorityQuery.get();
    final Map<String, int> tasksByPriority = {
      'low': 0,
      'medium': 0,
      'high': 0,
      'critical': 0,
    };

    for (final row in priorityRows) {
      final priority = row.read(_db.tasks.priority);
      final count = row.read(priorityCountExpr);
      if (priority != null && count != null) {
        tasksByPriority[priority] = count;
      }
    }

    return DashboardStats(
      totalProjects: totalProjects,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      overdueTasks: overdueTasks,
      tasksByPriority: tasksByPriority,
    );
  }

  // 2. Процент выполнения конкретного проекта (отношение выполненных задач к общему числу)
  Future<double> getProjectProgress(int projectId) async {
    final totalExpr = _db.tasks.id.count();

    // Всего задач в проекте
    final totalQuery = _db.selectOnly(_db.tasks)
      ..addColumns([totalExpr])
      ..where(_db.tasks.projectId.equals(projectId) & _db.tasks.deletedAt.isNull());
    final total = await totalQuery.map((row) => row.read(totalExpr)).getSingle() ?? 0;

    if (total == 0) return 0.0;

    // Завершённых задач в проекте
    final completedQuery = _db.selectOnly(_db.tasks)
      ..addColumns([totalExpr])
      ..where(
        _db.tasks.projectId.equals(projectId) &
        _db.tasks.status.equals('done') &
        _db.tasks.deletedAt.isNull(),
      );
    final completed = await completedQuery.map((row) => row.read(totalExpr)).getSingle() ?? 0;

    return (completed / total) * 100.0;
  }
}