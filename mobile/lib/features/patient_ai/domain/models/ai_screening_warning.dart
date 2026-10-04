enum WarningSeverity {
  info,
  caution,
  emergency,
}

class AiScreeningWarning {
  final WarningSeverity severity;
  final String title;
  final String message;
  final String clinicalBasis;
  final String recommendedAction;

  const AiScreeningWarning({
    required this.severity,
    required this.title,
    required this.message,
    required this.clinicalBasis,
    required this.recommendedAction,
  });

  bool get isEmergency => severity == WarningSeverity.emergency;
  bool get isCaution => severity == WarningSeverity.caution;
}
