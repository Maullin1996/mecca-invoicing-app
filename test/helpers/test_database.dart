import 'package:mecca/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDatabase {
  TestDatabase({required this.appDatabase, required this.raw});

  final AppDatabase appDatabase;
  final Database raw;

  static Future<TestDatabase> create() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await AppDatabase.createSchema(db);
      },
    );

    return TestDatabase(appDatabase: AppDatabase.test(db), raw: db);
  }
}
