import 'package:flutter/material.dart';
import '../../data/repositories/stats_repository.dart';

class StatsTab extends StatelessWidget {
  final StatsRepository statsRepo;

  const StatsTab({super.key, required this.statsRepo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStats>(
      future: statsRepo.getDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _StatCard(title: 'Всего проектов', value: '${stats.totalProjects}', color: Colors.blue),
              _StatCard(title: 'Всего задач', value: '${stats.totalTasks}', color: Colors.orange),
              _StatCard(title: 'Завершено задач', value: '${stats.completedTasks}', color: Colors.green),
              _StatCard(title: 'В процессе', value: '${stats.pendingTasks}', color: Colors.purple),
              _StatCard(title: 'Просрочено', value: '${stats.overdueTasks}', color: Colors.red),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    const defaultTextStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: defaultTextStyle),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}