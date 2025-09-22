class DoseLog {
  final int? id;
  final int medicationId;
  final DateTime dateTime;
  final double doseGiven;
  final String givenBy;
  final String? note;
  final DateTime createdAt;

  DoseLog({
    this.id,
    required this.medicationId,
    required this.dateTime,
    required this.doseGiven,
    required this.givenBy,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'date_time': dateTime.millisecondsSinceEpoch,
      'dose_given': doseGiven,
      'given_by': givenBy,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'],
      medicationId: map['medication_id'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time']),
      doseGiven: map['dose_given'],
      givenBy: map['given_by'],
      note: map['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  DoseLog copyWith({
    int? id,
    int? medicationId,
    DateTime? dateTime,
    double? doseGiven,
    String? givenBy,
    String? note,
    DateTime? createdAt,
  }) {
    return DoseLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      dateTime: dateTime ?? this.dateTime,
      doseGiven: doseGiven ?? this.doseGiven,
      givenBy: givenBy ?? this.givenBy,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
