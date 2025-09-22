class Question {
  final int? id;
  final String title;
  final String questionText;
  final DateTime dateEntered;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Question({
    this.id,
    required this.title,
    required this.questionText,
    required this.dateEntered,
    this.answer,
    this.answeredAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'question_text': questionText,
      'date_entered': dateEntered.millisecondsSinceEpoch,
      'answer': answer,
      'answered_at': answeredAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      title: map['title'],
      questionText: map['question_text'],
      dateEntered: DateTime.fromMillisecondsSinceEpoch(map['date_entered']),
      answer: map['answer'],
      answeredAt: map['answered_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['answered_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  Question copyWith({
    int? id,
    String? title,
    String? questionText,
    DateTime? dateEntered,
    String? answer,
    DateTime? answeredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      title: title ?? this.title,
      questionText: questionText ?? this.questionText,
      dateEntered: dateEntered ?? this.dateEntered,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAnswered => answer != null && answer!.isNotEmpty;
  
  String get status {
    if (isAnswered) {
      return 'Answered';
    }
    return 'Pending';
  }
}
