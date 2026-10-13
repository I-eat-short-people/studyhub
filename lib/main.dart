import 'package:flutter/material.dart';
import 'core/database/database_global.dart';
import 'core/database/platform/shared.dart';
import 'core/services/firebase_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Drift Database with Cashew MultiExecutor pattern
  database = await constructDb('studyhub');

  // Seed sample subjects and documents on first launch
  await database.seedInitialDataIfEmpty();

  // Khởi tạo Firebase Service (Authentication & Cloud Storage)
  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  // Khởi tạo Supabase Service (Cloud Storage & Document Sharing)
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Supabase init fallback: $e');
  }

  runApp(const StudyHubApp());
}

class StudyHubApp extends StatefulWidget {
  const StudyHubApp({super.key});

  @override
  State<StudyHubApp> createState() => _StudyHubAppState();
}

class _StudyHubAppState extends State<StudyHubApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyHub - Quản Lý Tài Liệu Môn Học',
      debugShowCheckedModeBanner: false,
      theme: getAppTheme(Brightness.light),
      darkTheme: getAppTheme(Brightness.dark),
      themeMode: _themeMode,
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}
