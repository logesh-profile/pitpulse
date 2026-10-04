import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/admin/data/datasources/admin_remote_data_source.dart';
import '../features/admin/presentation/controllers/admin_controller.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/asha/presentation/screens/asha_dashboard_screen.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import '../features/patients/data/datasources/patient_remote_data_source.dart';
import '../features/patients/presentation/controllers/patient_controller.dart';
import '../features/patients/presentation/screens/patient_dashboard_screen.dart';

class PitPulseApp extends StatefulWidget {
  final ApiClient apiClient;
  final SecureStorageService? secureStorageService;
  final AuthRemoteDataSource? authRemoteDataSource;
  final AuthController? authController;
  final PatientRemoteDataSource? patientRemoteDataSource;
  final PatientController? patientController;
  final AdminRemoteDataSource? adminRemoteDataSource;
  final AdminController? adminController;

  const PitPulseApp({
    super.key,
    required this.apiClient,
    this.secureStorageService,
    this.authRemoteDataSource,
    this.authController,
    this.patientRemoteDataSource,
    this.patientController,
    this.adminRemoteDataSource,
    this.adminController,
  });

  @override
  State<PitPulseApp> createState() => _PitPulseAppState();
}

class _PitPulseAppState extends State<PitPulseApp> {
  late final AuthController _authController;
  late final PatientController _patientController;
  late final AdminController _adminController;

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

    final patientDs = widget.patientRemoteDataSource ?? PatientRemoteDataSourceImpl(apiClient: widget.apiClient);
    _patientController = widget.patientController ?? PatientController(remoteDataSource: patientDs);

    final adminDs = widget.adminRemoteDataSource ?? AdminRemoteDataSourceImpl(apiClient: widget.apiClient);
    _adminController = widget.adminController ?? AdminController(remoteDataSource: adminDs);

    // Check existing session on launch
    _authController.checkAuthSession();
  }

  Widget _resolveHomeScreen(AuthController auth) {
    if (!auth.isAuthenticated) {
      return LoginScreen(authController: auth);
    }

    final user = auth.currentUser;
    if (user == null) {
      return LoginScreen(authController: auth);
    }

    // First login mandatory password change
    if (user.mustChangePassword) {
      return ChangePasswordScreen(authController: auth);
    }

    // Role-specific routing
    switch (user.role) {
      case 'ADMIN':
        return AdminDashboardScreen(
          authController: auth,
          adminController: _adminController,
        );
      case 'DOCTOR':
        return DoctorDashboardScreen(
          authController: auth,
        );
      case 'ASHA':
        return AshaDashboardScreen(
          authController: auth,
        );
      case 'PATIENT':
      default:
        return PatientDashboardScreen(
          authController: auth,
          patientController: _patientController,
        );
    }
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
          home: _resolveHomeScreen(_authController),
        );
      },
    );
  }
}
