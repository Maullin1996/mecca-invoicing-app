class JobPhoto {
  final int? id;
  final int jobId;
  final String path;
  final String createdAt;

  JobPhoto({
    this.id,
    required this.jobId,
    required this.path,
    required this.createdAt,
  });

  JobPhoto copyWith({int? id, int? jobId, String? path, String? createdAt}) {
    return JobPhoto(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'job_id': jobId,
      'path': path,
      'created_at': createdAt,
    };
    return map;
  }

  factory JobPhoto.fromMap(Map<String, dynamic> map) {
    return JobPhoto(
      id: map['id'] as int?,
      path: map['path'] as String,
      jobId: map['job_id'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}
