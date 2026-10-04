import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../../patients/data/models/patient_profile_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/models/professional_user_model.dart';

enum AdminStateStatus { initial, loading, loaded, error }

class AdminController extends ChangeNotifier {
  final AdminRemoteDataSource remoteDataSource;

  AdminStateStatus _status = AdminStateStatus.initial;
  List<ProfessionalUserModel> _professionals = [];
  List<PatientProfileModel> _patients = [];
  ProvisionedAccountResult? _lastProvisioned;
  PatientProfileModel? _lastProvisionedPatient;
  String? _errorMessage;

  AdminController({required this.remoteDataSource});

  AdminStateStatus get status => _status;
  List<ProfessionalUserModel> get professionals => _professionals;
  List<ProfessionalUserModel> get doctors =>
      _professionals.where((p) => p.role.toUpperCase() == 'DOCTOR').toList();
  List<ProfessionalUserModel> get ashas =>
      _professionals.where((p) => p.role.toUpperCase() == 'ASHA').toList();
  List<PatientProfileModel> get patients => _patients;
  ProvisionedAccountResult? get lastProvisioned => _lastProvisioned;
  PatientProfileModel? get lastProvisionedPatient => _lastProvisionedPatient;
  String? get errorMessage => _errorMessage;

  void clearLastProvisioned() {
    _lastProvisioned = null;
    _lastProvisionedPatient = null;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final profsFuture = remoteDataSource.listProfessionals();
      final patientsFuture = remoteDataSource.listPatients();
      final results = await Future.wait([profsFuture, patientsFuture]);
      _professionals = results[0] as List<ProfessionalUserModel>;
      _patients = results[1] as List<PatientProfileModel>;
      _status = AdminStateStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<void> loadProfessionals() async {
    await loadAll();
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
      await loadAll();
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
      await loadAll();
      return true;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createPatient({
    required String email,
    required String fullName,
    String? phone,
    String? password,
    String? dateOfBirth,
    String? sex,
    String? bloodGroup,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? baselineHealthInfo,
  }) async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastProvisionedPatient = await remoteDataSource.createPatient(
        email: email,
        fullName: fullName,
        phone: phone,
        password: password,
        dateOfBirth: dateOfBirth,
        sex: sex,
        bloodGroup: bloodGroup,
        address: address,
        villageLocality: villageLocality,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        baselineHealthInfo: baselineHealthInfo,
      );
      _status = AdminStateStatus.loaded;
      _errorMessage = null;
      await loadAll();
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
        await loadAll();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    _status = AdminStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await remoteDataSource.deleteUser(userId: userId);
      if (success) {
        await loadAll();
        return true;
      }
      _status = AdminStateStatus.loaded;
      return false;
    } catch (e) {
      _status = AdminStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }
}

