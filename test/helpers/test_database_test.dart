import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

void main() {
  TestDatabase? testDb;

  setUp(() async {
    testDb = await TestDatabase.create();
  });

  tearDown(() async {
    await testDb?.raw.close();
  });

  test('creates database with foreign keys enabled', () async {
    final rows = await testDb!.raw.rawQuery('PRAGMA foreign_keys');
    expect(rows, isNotEmpty);
    expect(rows.first['foreign_keys'], 1);
  });

  test('creates expected tables', () async {
    final rows = await testDb!.raw.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
      ORDER BY name
    ''');

    final tableNames = rows.map((row) => row['name']).toSet();
    expect(tableNames, contains('companies'));
    expect(tableNames, contains('jobs'));
    expect(tableNames, contains('jobs_photos'));
  });

  test('deletes dependent rows with cascading foreign keys', () async {
    final db = testDb!.raw;
    final companyId = await db.insert('companies', {
      'name': 'Acme',
      'email': 'a@a.com',
      'minutes_balance': 10,
      'address': null,
      'city': null,
    });

    final jobId = await db.insert('jobs', {
      'company_id': companyId,
      'date': '2026-03-28',
      'start_time': '08:00',
      'end_time': '10:00',
      'service': 'Limpieza',
      'minutes_worked': 120,
      'hours_charged': 2,
      'value_per_hour': 5000,
      'extras_json': '[]',
      'extra_value': 0,
      'total_day': 10000,
      'status': 'done',
    });

    await db.insert('jobs_photos', {
      'job_id': jobId,
      'path': 'path/to/photo.png',
      'created_at': '2026-03-28T10:00:00Z',
    });

    await db.delete('companies', where: 'id = ?', whereArgs: [companyId]);

    final jobs = await db.query('jobs');
    final photos = await db.query('jobs_photos');
    expect(jobs, isEmpty);
    expect(photos, isEmpty);
  });
}