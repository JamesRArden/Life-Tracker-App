import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            tracker TEXT unique,
            value INTEGER
          )
        ''');

        await db.execute('''
              CREATE TABLE tracker_meta_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                tracker TEXT unique,
                colour1 INTEGER,
                colour2 INTEGER
                )
          ''');
      },
    );
  }
}
