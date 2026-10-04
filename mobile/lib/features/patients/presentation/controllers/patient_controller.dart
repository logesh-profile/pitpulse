import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/patient_remote_data_source.dart';
import '../../data/models/patient_profile_model.dart';

enum PatientStateStatus { initial, loading, loaded, error }

class PatientController extends ChangeNotifier {
  final PatientRemoteDataSource remoteDataSource;

  PatientStateStatus _status = PatientStateStatus.initial;
  PatientProfileModel? _profile;
  String? _errorMessage;

  PatientController({required this.remoteDataSource});

  PatientStateStatus get status => _status;
  PatientProfileModel? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _status = PatientStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await remoteDataSource.getMyProfile();
      _status = PatientStateStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = PatientStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? dateOfBirth,
    String? sex,
    String? address,
    String? villageLocality,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? baselineHealthInfo,
  }) async {
    _status = PatientStateStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await remoteDataSource.updateMyProfile(
        dateOfBirth: dateOfBirth,
        sex: sex,
        address: address,
        villageLocality: villageLocality,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        bloodGroup: bloodGroup,
        baselineHealthInfo: baselineHealthInfo,
      );
      _status = PatientStateStatus.loaded;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PatientStateStatus.error;
      _errorMessage = e is Failure ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }
}
