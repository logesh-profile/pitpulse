import 'package:flutter/material.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/datasources/pregnancy_remote_data_source.dart';
import 'package:pitpulse_mobile/features/pregnancy/data/models/pregnancy_model.dart';

class PregnancyController extends ChangeNotifier {
  final PregnancyRemoteDataSource _dataSource;

  PregnancyController({PregnancyRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? PregnancyRemoteDataSource();

  bool _isLoading = false;
  String? _errorMessage;
  List<PregnancyModel> _pregnancies = [];
  PregnancyModel? _activePregnancy;
  PregnancyModel? _selectedPregnancy;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PregnancyModel> get pregnancies => _pregnancies;
  PregnancyModel? get activePregnancy => _activePregnancy;
  PregnancyModel? get selectedPregnancy => _selectedPregnancy;

  Future<void> fetchMyPregnancies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pregnancies = await _dataSource.getMyPregnancies();
      _activePregnancy = _pregnancies.where((p) => p.isActive).firstOrNull;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PregnancyModel?> createPregnancy({
    required DateTime lmp,
    int? pregnancyNumber,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _dataSource.createPregnancy(
        lmp: lmp,
        pregnancyNumber: pregnancyNumber,
        notes: notes,
      );
      await fetchMyPregnancies();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PregnancyModel?> fetchPregnancyById(String pregnancyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPregnancy = await _dataSource.getMyPregnancyById(pregnancyId);
      return _selectedPregnancy;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePregnancyStatus({
    required String pregnancyId,
    required String status,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _dataSource.updateMyPregnancy(
        pregnancyId: pregnancyId,
        status: status,
        notes: notes,
      );
      _selectedPregnancy = updated;
      await fetchMyPregnancies();
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
