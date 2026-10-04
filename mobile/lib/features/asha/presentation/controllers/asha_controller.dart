import 'package:flutter/foundation.dart';
import '../../data/datasources/asha_remote_data_source.dart';
import '../../data/models/asha_models.dart';

enum AshaStateStatus { initial, loading, success, error }

class AshaController extends ChangeNotifier {
  final AshaRemoteDataSource remoteDataSource;

  AshaController({AshaRemoteDataSource? remoteDataSource})
      : remoteDataSource = remoteDataSource ?? AshaRemoteDataSource();

  AshaStateStatus _status = AshaStateStatus.initial;
  String? _errorMessage;

  // ASHA Worker State
  List<AshaAssignmentModel> _assignedPatients = [];
  AshaAssignmentModel? _selectedPatient;
  List<HomeVisitModel> _patientVisits = [];
  List<MaternalVitalRecordModel> _patientVitals = [];

  // Patient Self-Service State
  AshaAssignmentModel? _myAssignment;
  List<HomeVisitModel> _myVisits = [];
  List<MaternalVitalRecordModel> _myVitals = [];

  // Admin Assignment State
  List<AshaAssignmentModel> _adminAssignments = [];
  List<Map<String, dynamic>> _adminPatients = [];
  List<Map<String, dynamic>> _adminAshaWorkers = [];

  AshaStateStatus get status => _status;
  String? get errorMessage => _errorMessage;

  List<AshaAssignmentModel> get assignedPatients => _assignedPatients;
  AshaAssignmentModel? get selectedPatient => _selectedPatient;
  List<HomeVisitModel> get patientVisits => _patientVisits;
  List<MaternalVitalRecordModel> get patientVitals => _patientVitals;

  AshaAssignmentModel? get myAssignment => _myAssignment;
  List<HomeVisitModel> get myVisits => _myVisits;
  List<MaternalVitalRecordModel> get myVitals => _myVitals;

  List<AshaAssignmentModel> get adminAssignments => _adminAssignments;
  List<Map<String, dynamic>> get adminPatients => _adminPatients;
  List<Map<String, dynamic>> get adminAshaWorkers => _adminAshaWorkers;

  bool get isLoading => _status == AshaStateStatus.loading;

  // ==========================================
  // ASHA Worker Actions
  // ==========================================

  Future<void> loadMyAssignedPatients() async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _assignedPatients = await remoteDataSource.getMyAssignedPatients();
      _status = AshaStateStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadPatientFullDetail(String patientId) async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        remoteDataSource.getAssignedPatientDetail(patientId),
        remoteDataSource.getPatientHomeVisits(patientId),
        remoteDataSource.getPatientVitals(patientId),
      ]);
      _selectedPatient = results[0] as AshaAssignmentModel;
      _patientVisits = results[1] as List<HomeVisitModel>;
      _patientVitals = results[2] as List<MaternalVitalRecordModel>;
      _status = AshaStateStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
    }
    notifyListeners();
  }

  Future<HomeVisitModel?> createHomeVisit({
    required String patientId,
    required String visitDate,
    String? pregnancyId,
    required String purpose,
    String? observations,
    String? notes,
    bool followUpRequired = false,
    String? followUpNotes,
  }) async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final visit = await remoteDataSource.createHomeVisit(
        patientId: patientId,
        visitDate: visitDate,
        pregnancyId: pregnancyId,
        purpose: purpose,
        observations: observations,
        notes: notes,
        followUpRequired: followUpRequired,
        followUpNotes: followUpNotes,
      );
      // Refresh patient visits list
      _patientVisits = await remoteDataSource.getPatientHomeVisits(patientId);
      _status = AshaStateStatus.success;
      notifyListeners();
      return visit;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<MaternalVitalRecordModel?> recordMaternalVitals({
    required String patientId,
    required String visitId,
    int? systolicBp,
    int? diastolicBp,
    double? weightKg,
    double? temperatureC,
    String? notes,
  }) async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final vital = await remoteDataSource.recordVitals(
        patientId: patientId,
        visitId: visitId,
        systolicBp: systolicBp,
        diastolicBp: diastolicBp,
        weightKg: weightKg,
        temperatureC: temperatureC,
        notes: notes,
      );
      // Refresh patient vitals list
      _patientVitals = await remoteDataSource.getPatientVitals(patientId);
      _status = AshaStateStatus.success;
      notifyListeners();
      return vital;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
      notifyListeners();
      return null;
    }
  }

  // ==========================================
  // Patient Self-Service Actions
  // ==========================================

  Future<void> loadPatientSelfData() async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        remoteDataSource.getMyAshaAssignment(),
        remoteDataSource.getMyHomeVisits(),
        remoteDataSource.getMyVitals(),
      ]);
      _myAssignment = results[0] as AshaAssignmentModel?;
      _myVisits = results[1] as List<HomeVisitModel>;
      _myVitals = results[2] as List<MaternalVitalRecordModel>;
      _status = AshaStateStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
    }
    notifyListeners();
  }

  // ==========================================
  // Admin Assignment Actions
  // ==========================================

  Future<void> loadAdminAssignmentsData() async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        remoteDataSource.getAdminAssignments(),
        remoteDataSource.getAdminPatientsList(),
        remoteDataSource.getAdminAshaWorkersList(),
      ]);
      _adminAssignments = results[0] as List<AshaAssignmentModel>;
      _adminPatients = results[1] as List<Map<String, dynamic>>;
      _adminAshaWorkers = results[2] as List<Map<String, dynamic>>;
      _status = AshaStateStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
    }
    notifyListeners();
  }

  Future<bool> assignPatient({
    required String ashaWorkerId,
    required String patientId,
    String? notes,
  }) async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await remoteDataSource.assignPatientToAsha(
        ashaWorkerId: ashaWorkerId,
        patientId: patientId,
        notes: notes,
      );
      await loadAdminAssignmentsData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateAssignment(String assignmentId, {String? notes}) async {
    _status = AshaStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await remoteDataSource.updateAssignmentStatus(
        assignmentId: assignmentId,
        status: 'INACTIVE',
        notes: notes,
      );
      await loadAdminAssignmentsData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AshaStateStatus.error;
      notifyListeners();
      return false;
    }
  }
}
