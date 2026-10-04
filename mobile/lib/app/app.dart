import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../features/health_check/data/datasources/health_remote_data_source.dart';
import '../features/health_check/presentation/screens/health_check_screen.dart';

class PitPulseApp extends StatelessWidget {
  final ApiClient apiClient;

  const PitPulseApp({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    final healthDataSource = HealthRemoteDataSourceImpl(apiClient: apiClient);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Medical teal
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: HealthCheckScreen(dataSource: healthDataSource),
    );
  }
}
