import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/company.dart';

class CompanyRepository {
  CompanyRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase();

  final AppDatabase _appDatabase;

  Future<Database> get _db async => _appDatabase.database;

  Future<int> insertCompany(Company company) async {
    final db = await _db;
    return db.insert('companies', company.toMap());
  }

  Future<List<Company>> getAllCompanies() async {
    final db = await _db;
    final rows = await db.query('companies', orderBy: 'id ASC');
    return rows.map(Company.fromMap).toList();
  }

  Future<Company?> getCompanyById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Company.fromMap(rows.first);
  }

  Future<void> updateCompany(Company company) async {
    if (company.id == null) {
      throw ArgumentError('No se puede actualizar una empresa sin id.');
    }

    final db = await _db;
    await db.update(
      'companies',
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<void> deleteCompany(int id) async {
    final db = await _db;
    await db.delete(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
