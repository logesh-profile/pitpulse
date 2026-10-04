import 'package:pitpulse_mobile/core/network/api_client.dart';
import '../models/asha_models.dart';

class AshaRemoteDataSource {
  final ApiClient _apiClient;

  AshaRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  // ==========================================
  // ASHA Worker Endpoints
  // ==========================================

  /// Fetch all patients actively assigned to the authenticated ASHA
  Future<List<AshaAssignmentModel>> getMyAssignedPatients() async {
    final response = await _apiClient.get('/api/v1/asha/me/patients');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => AshaAssignmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch detail of a single assigned patient
  Future<AshaAssignmentModel> getAssignedPatientDetail(String patientId) async {
    final response = await _apiClient.get('/api/v1/asha/me/patients/$patientId');
    return AshaAssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// List home visits for an assigned patient
  Future<List<HomeVisitModel>> getPatientHomeVisits(String patientId) async {
    final response = await _apiClient.get('/api/v1/asha/me/patients/$patientId/home-visits');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> items = data['items'] ?? [];
    return items.map((json) => HomeVisitModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Create a new home visit record
  Future<HomeVisitModel> createHomeVisit({
    required String patientId,
    required String visitDate,
    String? pregnancyId,
    required String purpose,
    String? observations,
    String? notes,
    bool followUpRequired = false,
    String? followUpNotes,
  }) async {
    final body = <String, dynamic>{
      'visit_date': visitDate,
      'purpose': purpose,
      'follow_up_required': followUpRequired,
    };
    if (pregnancyId != null) body['pregnancy_id'] = pregnancyId;
    if (observations != null && observations.isNotEmpty) body['observations'] = observations;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (followUpNotes != null && followUpNotes.isNotEmpty) body['follow_up_notes'] = followUpNotes;

    final response = await _apiClient.post(
      '/api/v1/asha/me/patients/$patientId/home-visits',
      data: body,
    );
    return HomeVisitModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// List vitals for an assigned patient
  Future<List<MaternalVitalRecordModel>> getPatientVitals(String patientId) async {
    final response = await _apiClient.get('/api/v1/asha/me/patients/$patientId/vitals');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> items = data['items'] ?? [];
    return items.map((json) => MaternalVitalRecordModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Record vitals during a home visit
  Future<MaternalVitalRecordModel> recordVitals({
    required String patientId,
    required String visitId,
    int? systolicBp,
    int? diastolicBp,
    double? weightKg,
    double? temperatureC,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (systolicBp != null) body['systolic_bp'] = systolicBp;
    if (diastolicBp != null) body['diastolic_bp'] = diastolicBp;
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (temperatureC != null) body['temperature_c'] = temperatureC;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _apiClient.post(
      '/api/v1/asha/me/patients/$patientId/home-visits/$visitId/vitals',
      data: body,
    );
    return MaternalVitalRecordModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ==========================================
  // Patient Self-Service Endpoints
  // ==========================================

  /// Fetch active ASHA assignment for authenticated patient
  Future<AshaAssignmentModel?> getMyAshaAssignment() async {
    try {
      final response = await _apiClient.get('/api/v1/patients/me/asha-assignment');
      return AshaAssignmentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Fetch home visits for authenticated patient
  Future<List<HomeVisitModel>> getMyHomeVisits() async {
    final response = await _apiClient.get('/api/v1/patients/me/home-visits');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> items = data['items'] ?? [];
    return items.map((json) => HomeVisitModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch maternal vitals for authenticated patient
  Future<List<MaternalVitalRecordModel>> getMyVitals() async {
    final response = await _apiClient.get('/api/v1/patients/me/vitals');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> items = data['items'] ?? [];
    return items.map((json) => MaternalVitalRecordModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ==========================================
  // Admin Assignment Endpoints
  // ==========================================

  /// List all ASHA assignments across system
  Future<List<AshaAssignmentModel>> getAdminAssignments({String? status}) async {
    final query = status != null ? {'status': status} : null;
    final response = await _apiClient.get('/api/v1/admin/assignments/asha', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> items = data['items'] ?? [];
    return items.map((json) => AshaAssignmentModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Admin assign patient to ASHA
  Future<AshaAssignmentModel> assignPatientToAsha({
    required String ashaWorkerId,
    required String patientId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'asha_worker_id': ashaWorkerId,
      'patient_id': patientId,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _apiClient.post('/api/v1/admin/assignments/asha', data: body);
    return AshaAssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Admin deactivate/update assignment
  Future<AshaAssignmentModel> updateAssignmentStatus({
    required String assignmentId,
    required String status,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await _apiClient.patch('/api/v1/admin/assignments/asha/$assignmentId', data: body);
    return AshaAssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetch list of patients for admin assignment dropdown
  Future<List<Map<String, dynamic>>> getAdminPatientsList() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/patients');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Fetch list of ASHA workers for admin assignment dropdown
  Future<List<Map<String, dynamic>>> getAdminAshaWorkersList() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/asha-workers');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
