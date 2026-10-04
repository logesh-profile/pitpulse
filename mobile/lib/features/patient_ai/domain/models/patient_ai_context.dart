import '../../../asha/data/models/asha_models.dart';
import '../../../pregnancy/data/models/pregnancy_model.dart';

class PatientAiContext {
  final String patientName;
  final String? healthRecordNumber;
  final String? villageLocality;
  final String? bloodGroup;
  final PregnancyModel? activePregnancy;
  final List<MaternalVitalRecordModel> vitals;
  final List<HomeVisitModel> homeVisits;
  final String? assignedAshaName;

  const PatientAiContext({
    required this.patientName,
    this.healthRecordNumber,
    this.villageLocality,
    this.bloodGroup,
    this.activePregnancy,
    this.vitals = const [],
    this.homeVisits = const [],
    this.assignedAshaName,
  });

  bool get hasActivePregnancy => activePregnancy != null;
  bool get hasVitals => vitals.isNotEmpty;
  bool get hasHomeVisits => homeVisits.isNotEmpty;

  MaternalVitalRecordModel? get latestVitals =>
      vitals.isNotEmpty ? vitals.first : null;

  HomeVisitModel? get latestHomeVisit =>
      homeVisits.isNotEmpty ? homeVisits.first : null;
}
