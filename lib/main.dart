import 'package:flutter/material.dart';
import 'data/database/app_database.dart';
import 'presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(); // Инициализация базы данных SQLite через Drift

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: HomeScreen(database: database),
      debugShowCheckedModeBanner: false,
    );
  }
}