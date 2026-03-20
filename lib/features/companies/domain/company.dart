class Company {
  const Company({
    this.id,
    required this.name,
    required this.minutesBalance,
    this.email,
  });

  final int? id;
  final String name;
  final int minutesBalance;
  final String? email;

  Company copyWith({
    int? id,
    String? name,
    int? minutesBalance,
    String? email,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      minutesBalance: minutesBalance ?? this.minutesBalance,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'minutes_balance': minutesBalance,
      'email': email,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      minutesBalance: map['minutes_balance'] as int,
    );
  }
}
