import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/professional_user_model.dart';

enum AdminStateStatus { initial, loading, loaded, error }

class AdminController extends ChangeNotifier {
  final AdminRemoteDataSource remoteDataSource;

  AdminStateStatus _status = AdminStateStatus.initial;
  List<ProfessionalUserModel> _professionals = [];
  ProvisionedAccountResult? _lastProvisioned;
  String? _errorMessage;

  AdminController({required this.remoteDataSource});

  AdminStateStatus get status => _status;
  List<ProfessionalUserModel> get professionals => _professionals;
  ProvisionedAccountResult? get lastProvisioned => _lastProvisioned;
  String? get errorMessage => _errorMessage;

  void clearLastProvisioned() {
    _lastProvisioned = null;
    notifyListeners();
  }

  Future<void> loadProfessionals() async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _professionals = await remoteDataSource.listProfessionals();
      _status = AdminStateStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<bool> createDoctor({
    required String email,
    required String fullName,
    String? phone,
    String? medicalLicenseNumber,
    String? specialization,
    String? facilityName,
  }) async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastProvisioned = await remoteDataSource.createDoctor(
        email: email,
        fullName: fullName,
        phone: phone,
        medicalLicenseNumber: medicalLicenseNumber,
        specialization: specialization,
        facilityName: facilityName,
      );
      _status = AdminStateStatus.loaded;
      _errorMessage = null;
      await loadProfessionals();
      return true;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAsha({
    required String email,
    required String fullName,
    String? phone,
    String? workerIdCode,
    String? assignedArea,
    String? primaryHealthCenter,
  }) async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastProvisioned = await remoteDataSource.createAsha(
        email: email,
        fullName: fullName,
        phone: phone,
        workerIdCode: workerIdCode,
        assignedArea: assignedArea,
        primaryHealthCenter: primaryHealthCenter,
      );
      _status = AdminStateStatus.loaded;
      _errorMessage = null;
      await loadProfessionals();
      return true;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(String userId, bool newStatus) async {
    try {
      final success = await remoteDataSource.toggleUserStatus(
        userId: userId,
        isActive: newStatus,
      );
      if (success) {
        await loadProfessionals();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }
}
