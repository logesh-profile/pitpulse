enum AiSourceType {
  pregnancyRecord,
  maternalVitals,
  ashaHomeVisit,
  clinicalScreeningRule,
  curatedKnowledgeBase,
}

class AiSourceReference {
  final AiSourceType type;
  final String title;
  final String detail;

  const AiSourceReference({
    required this.type,
    required this.title,
    required this.detail,
  });

  String get typeLabel {
    switch (type) {
      case AiSourceType.pregnancyRecord:
        return 'Pregnancy Record';
      case AiSourceType.maternalVitals:
        return 'Recorded Vitals';
      case AiSourceType.ashaHomeVisit:
        return 'ASHA Home Visit';
      case AiSourceType.clinicalScreeningRule:
        return 'Screening Guideline';
      case AiSourceType.curatedKnowledgeBase:
        return 'Maternal Health Guidelines';
    }
  }
}
