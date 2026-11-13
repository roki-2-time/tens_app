import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/stats_repository.dart';

import 'tabs/projects_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/stats_tab.dart';
import 'dialogs/create_project_dialog.dart';
import 'dialogs/create_task_dialog.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase database;

  const HomeScreen({super.key, required this.database});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final ProjectRepository _projectRepo;
  late final TaskRepository _taskRepo;
  late final StatsRepository _statsRepo;


@override
void initState() {
  super.initState();
  _projectRepo = ProjectRepository(widget.database);
  _taskRepo = TaskRepository(widget.database);
  _statsRepo = StatsRepository(widget.database);
}

@override
Widget build(BuildContext context) {
  final screens = [
    ProjectsTab(projectRepo: _projectRepo),
    TasksTab(taskRepo: _taskRepo),
    StatsTab(statsRepo: _statsRepo),
  ];

  return Scaffold(
    appBar: AppBar(
      title: const Text('TaskFlow — Управление задачами'),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
    ),
    body: screens[_currentIndex],
    floatingActionButton: _currentIndex != 2
        ? FloatingActionButton(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      onPressed: () {
        if (_currentIndex == 0) {
          showCreateProjectDialog(context, _projectRepo);
        } else {
          showCreateTaskDialog(context, widget.database, _projectRepo);
        }
      },
      child: const Icon(Icons.add),
    )
        : null,
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Проекты'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Задачи'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Статистика'),
      ],
    ),
  );
}
}