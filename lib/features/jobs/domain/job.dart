import 'dart:convert';

class JobExtra {
  const JobExtra({required this.description, required this.value});

  final String description;
  final int value;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'description': description, 'value': value};
  }

  factory JobExtra.fromMap(Map<String, dynamic> map) {
    return JobExtra(
      description: map['description'] as String,
      value: (map['value'] as num).toInt(),
    );
  }
}

class Job {
  static const String draft = 'draft';
  static const String finalized = 'finalized';

  Job({
    this.id,
    required this.companyId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.minutesWorked,
    required this.hoursCharged,
    required this.valuePerHour,
    required this.extras,
    required this.totalDay,
    required this.status,
    required this.service,
  }) : extraValue = extras.fold<int>(0, (sum, item) => sum + item.value) {
    if (status != draft && status != finalized) {
      throw ArgumentError.value(
        status,
        'status',
        "status must be '$draft' or '$finalized'",
      );
    }
  }

  final int? id;
  final int companyId;
  final String date;
  final String startTime;
  final String endTime;
  final int minutesWorked;
  final int hoursCharged;
  final int valuePerHour;
  final List<JobExtra> extras;
  final int extraValue;
  final int totalDay;
  final String status;
  final String service;

  Job copyWith({
    int? id,
    int? companyId,
    String? date,
    String? startTime,
    String? endTime,
    int? minutesWorked,
    int? hoursCharged,
    int? valuePerHour,
    List<JobExtra>? extras,
    int? totalDay,
    String? status,
    String? service,
  }) {
    return Job(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      minutesWorked: minutesWorked ?? this.minutesWorked,
      hoursCharged: hoursCharged ?? this.hoursCharged,
      valuePerHour: valuePerHour ?? this.valuePerHour,
      extras: extras ?? this.extras,
      totalDay: totalDay ?? this.totalDay,
      status: status ?? this.status,
      service: service ?? this.service,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'company_id': companyId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'minutes_worked': minutesWorked,
      'hours_charged': hoursCharged,
      'value_per_hour': valuePerHour,
      'extras_json': jsonEncode(extras.map((item) => item.toMap()).toList()),
      'extra_value': extraValue,
      'total_day': totalDay,
      'status': status,
      'service': service,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    final rawExtras = map['extras_json'];
    final decoded = rawExtras is String && rawExtras.isNotEmpty
        ? jsonDecode(rawExtras)
        : <dynamic>[];
    final extras = (decoded as List<dynamic>)
        .map((item) => JobExtra.fromMap(item as Map<String, dynamic>))
        .toList();

    return Job(
      id: map['id'] as int?,
      companyId: map['company_id'] as int,
      date: map['date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      minutesWorked: map['minutes_worked'] as int,
      hoursCharged: map['hours_charged'] as int,
      valuePerHour: (map['value_per_hour'] as num).toInt(),
      extras: extras,
      totalDay: (map['total_day'] as num).toInt(),
      status: map['status'] as String,
      service: map['service'] as String,
    );
  }
}
