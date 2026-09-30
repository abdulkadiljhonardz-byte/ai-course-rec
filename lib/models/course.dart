class Course {
  const Course({
    this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    this.isPaid = false,
  });

  final int? id;
  final String code;
  final String name;
  final String category;
  final String description;
  final bool isPaid;

  factory Course.fromMap(Map<String, Object?> map) {
    return Course(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      isPaid: map['is_paid'] == true || map['is_paid'] == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'description': description,
      'is_paid': isPaid ? 1 : 0,
    };
  }
}
