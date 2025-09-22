class Medication {
  final int? id;
  final String name;
  final String officialName;
  final String form;
  final double maxDosage;
  final int minTimeBetweenDoses; // in minutes
  final bool notificationsEnabled;
  final String notificationSound;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    this.id,
    required this.name,
    required this.officialName,
    required this.form,
    required this.maxDosage,
    required this.minTimeBetweenDoses,
    this.notificationsEnabled = false,
    this.notificationSound = 'gentle',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'official_name': officialName,
      'form': form,
      'max_dosage': maxDosage,
      'min_time_between_doses': minTimeBetweenDoses,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'notification_sound': notificationSound,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      officialName: map['official_name'],
      form: map['form'],
      maxDosage: map['max_dosage'],
      minTimeBetweenDoses: map['min_time_between_doses'],
      notificationsEnabled: map['notifications_enabled'] == 1,
      notificationSound: map['notification_sound'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? officialName,
    String? form,
    double? maxDosage,
    int? minTimeBetweenDoses,
    bool? notificationsEnabled,
    String? notificationSound,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      officialName: officialName ?? this.officialName,
      form: form ?? this.form,
      maxDosage: maxDosage ?? this.maxDosage,
      minTimeBetweenDoses: minTimeBetweenDoses ?? this.minTimeBetweenDoses,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
