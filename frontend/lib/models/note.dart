class Note {
  final String? id;
  final String title;
  final String content;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String?,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: DateTime.parse(json['date']),
      createdAt: json['created_at'] != null && json['created_at'] != ''
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'] != ''
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String().substring(0, 10), // YYYY-MM-DD format
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}