import 'package:sqflite/sqflite.dart';

import 'package:mecca/core/database/app_database.dart';
import 'package:mecca/features/jobs/domain/job_photo.dart';

class JobPhotosRepository {
  JobPhotosRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase();

  final AppDatabase _appDatabase;

  Future<Database> get _db async => _appDatabase.database;

  Future<int> insertPhoto(JobPhoto photo) async {
    final db = await _db;

    return db.insert('jobs_photos', {
      'job_id': photo.jobId,
      'path': photo.path,
      'created_at': photo.createdAt,
    });
  }

  Future<List<JobPhoto>> getPhotosByJob(int id) async {
    final db = await _db;
    final rows = await db.query(
      'jobs_photos',
      where: 'job_id = ?',
      whereArgs: [id],
    );

    return rows.map(JobPhoto.fromMap).toList();
  }

  Future<void> deletePhotoById(int id) async {
    final db = await _db;
    await db.delete('jobs_photos', where: 'id = ?', whereArgs: [id]);
  }
}
