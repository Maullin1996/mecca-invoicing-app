import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  AppDatabase.test(Database database) {
    _database = database;
  }

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'mecca.db');

    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await AppDatabase.createSchema(db);
      },
    );
  }

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        minutes_balance INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        service TEXT NOT NULL,
        minutes_worked INTEGER NOT NULL,
        hours_charged INTEGER NOT NULL,
        value_per_hour INTEGER NOT NULL,
        extras_json TEXT NOT NULL,
        extra_value INTEGER NOT NULL,
        total_day INTEGER NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY(company_id) REFERENCES companies(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE jobs_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE
      )
    ''');
  }
}
