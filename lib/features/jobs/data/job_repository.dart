import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/job.dart';

class JobRepository {
  JobRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase();

  final AppDatabase _appDatabase;

  Future<Database> get _db async => _appDatabase.database;

  Future<int> insertDraftJob(Job job) async {
    if (job.status != Job.draft) {
      throw ArgumentError("insertDraftJob solo permite status 'draft'.");
    }

    final db = await _db;
    return db.insert('jobs', job.toMap());
  }

  Future<void> updateDraftJob(Job job) async {
    if (job.id == null) {
      throw ArgumentError('No se puede actualizar un job sin id.');
    }
    if (job.status != Job.draft) {
      throw ArgumentError("updateDraftJob solo permite status 'draft'.");
    }

    final db = await _db;
    await db.update('jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  Future<List<Job>> getJobsByCompany(int companyId) async {
    final db = await _db;
    final rows = await db.query(
      'jobs',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'id DESC',
    );
    return rows.map(Job.fromMap).toList();
  }

  Future<void> deleteDraftJob(int id) async {
    final db = await _db;

    final count = await db.rawDelete(
      'DELETE FROM jobs WHERE id = ? AND status = ?',
      [id, Job.draft],
    );

    if (count == 0) {
      throw StateError('El job no existe o no está en estado draft.');
    }
  }

  Future<void> finalizeJob(Job job, int newBalance) async {
    if (job.id == null) {
      throw ArgumentError('No se puede finalizar un job sin id.');
    }
    if (job.status != Job.draft) {
      throw ArgumentError("finalizeJob solo permite status 'draft'.");
    }

    final db = await _db;
    await db.transaction((txn) async {
      final updatedJobs = await txn.update(
        'jobs',
        {'status': Job.finalized},
        where: 'id = ?',
        whereArgs: [job.id],
      );
      if (updatedJobs == 0) {
        throw StateError('No se encontro el job para finalizar.');
      }

      final updatedCompanies = await txn.update(
        'companies',
        {'minutes_balance': newBalance},
        where: 'id = ?',
        whereArgs: [job.companyId],
      );
      if (updatedCompanies == 0) {
        throw StateError('No se encontro la company para actualizar saldo.');
      }
    });
  }

  Future<List<Map<String, dynamic>>> findOrphanJobs() async {
    final db = await _db;

    return db.rawQuery('''
    SELECT j.*
    FROM jobs j
    LEFT JOIN companies c ON j.company_id = c.id
    WHERE c.id IS NULL
  ''');
  }
}
