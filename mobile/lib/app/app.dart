import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/home_dashboard_stub_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';

class PitPulseApp extends StatefulWidget {
  final ApiClient apiClient;
  final SecureStorageService? secureStorageService;
  final AuthRemoteDataSource? authRemoteDataSource;
  final AuthController? authController;

  const PitPulseApp({
    super.key,
    required this.apiClient,
    this.secureStorageService,
    this.authRemoteDataSource,
    this.authController,
  });

  @override
  State<PitPulseApp> createState() => _PitPulseAppState();
}

class _PitPulseAppState extends State<PitPulseApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    final storage = widget.secureStorageService ?? FlutterSecureStorageServiceImpl();
    final authDs = widget.authRemoteDataSource ?? AuthRemoteDataSourceImpl(apiClient: widget.apiClient);
    _authController = widget.authController ??
        AuthController(
          authRemoteDataSource: authDs,
          secureStorageService: storage,
          apiClient: widget.apiClient,
        );

    // Check existing session on launch
    _authController.checkAuthSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, _) {
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
          home: _authController.isAuthenticated
              ? HomeDashboardStubScreen(authController: _authController)
              : LoginScreen(authController: _authController),
        );
      },
    );
  }
}
