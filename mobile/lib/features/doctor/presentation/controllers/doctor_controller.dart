import 'package:flutter/material.dart';
import '../../data/datasources/doctor_remote_data_source.dart';
import '../../data/models/doctor_models.dart';

class DoctorController extends ChangeNotifier {
  final DoctorRemoteDataSource _dataSource;

  DoctorController({DoctorRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? DoctorRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;

  List<DoctorPatientModel> _allPatients = [];
  List<DoctorPatientModel> _unassignedPatients = [];
  List<DoctorAshaModel> _availableAshas = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DoctorPatientModel> get allPatients => _allPatients;
  List<DoctorPatientModel> get unassignedPatients => _unassignedPatients;
  List<DoctorAshaModel> get availableAshas => _availableAshas;

  Future<void> loadDoctorData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dataSource.getDoctorPatients(),
        _dataSource.getUnassignedPatients(),
        _dataSource.getAvailableAshas(),
      ]);

      _allPatients = results[0] as List<DoctorPatientModel>;
      _unassignedPatients = results[1] as List<DoctorPatientModel>;
      _availableAshas = results[2] as List<DoctorAshaModel>;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignAshaToPatient({
    required String patientId,
    required String ashaWorkerId,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.assignAshaToPatient(
        patientId: patientId,
        ashaWorkerId: ashaWorkerId,
        notes: notes,
      );
      await loadDoctorData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
