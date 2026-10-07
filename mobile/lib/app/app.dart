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

import '../features/asha/data/datasources/asha_remote_data_source.dart';
import '../features/asha/presentation/controllers/asha_controller.dart';
import '../features/doctor/data/datasources/doctor_remote_data_source.dart';
import '../features/doctor/presentation/controllers/doctor_controller.dart';
import '../features/common/presentation/screens/maatra_ribbon_reveal_screen.dart';
import '../features/pregnancy/data/datasources/pregnancy_remote_data_source.dart';
import '../features/pregnancy/presentation/controllers/pregnancy_controller.dart';

class PitPulseApp extends StatefulWidget {
  final ApiClient apiClient;
  final SecureStorageService? secureStorageService;
  final AuthRemoteDataSource? authRemoteDataSource;
  final AuthController? authController;
  final PatientRemoteDataSource? patientRemoteDataSource;
  final PatientController? patientController;
  final AdminRemoteDataSource? adminRemoteDataSource;
  final AdminController? adminController;
  final PregnancyController? pregnancyController;
  final AshaController? ashaController;
  final DoctorController? doctorController;

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
    this.pregnancyController,
    this.ashaController,
    this.doctorController,
  });

  @override
  State<PitPulseApp> createState() => _PitPulseAppState();
}

class _PitPulseAppState extends State<PitPulseApp> {
  late final AuthController _authController;
  late final PatientController _patientController;
  late final AdminController _adminController;
  late final PregnancyController _pregnancyController;
  late final AshaController _ashaController;
  late final DoctorController _doctorController;
  bool _hasShownReveal = false;

  @override
  void initState() {
    super.initState();
    ApiClient.setSharedInstance(widget.apiClient);

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

    final pregDs = PregnancyRemoteDataSource(apiClient: widget.apiClient);
    _pregnancyController = widget.pregnancyController ?? PregnancyController(dataSource: pregDs);

    final ashaDs = AshaRemoteDataSource(apiClient: widget.apiClient);
    _ashaController = widget.ashaController ?? AshaController(remoteDataSource: ashaDs);

    final docDs = DoctorRemoteDataSource(apiClient: widget.apiClient);
    _doctorController = widget.doctorController ?? DoctorController(dataSource: docDs);

    // Check existing session on launch
    _authController.checkAuthSession();
  }

  Widget _resolveHomeScreen(AuthController auth) {
    if (!auth.isAuthenticated) {
      _hasShownReveal = false;
      return LoginScreen(authController: auth);
    }

    final user = auth.currentUser;
    if (user == null) {
      _hasShownReveal = false;
      return LoginScreen(authController: auth);
    }

    // First login mandatory password change
    if (user.mustChangePassword) {
      return ChangePasswordScreen(authController: auth);
    }

    // Harmonious Ribbon Loop Reveal Screen after login
    if (!_hasShownReveal) {
      return MaatraRibbonRevealScreen(
        onCompleted: () {
          if (mounted) {
            setState(() {
              _hasShownReveal = true;
            });
          }
        },
      );
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
          doctorController: _doctorController,
        );
      case 'ASHA':
        return AshaDashboardScreen(
          authController: auth,
          ashaController: _ashaController,
        );
      case 'PATIENT':
      default:
        return PatientDashboardScreen(
          authController: auth,
          patientController: _patientController,
          pregnancyController: _pregnancyController,
          ashaController: _ashaController,
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
