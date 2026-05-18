import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
class LocationDatabase {
  LocationDatabase._(this._db);

  final Database _db;

  static const _filename = 'locations.db';
  static const _table = 'locations';

  @factoryMethod
  @preResolve
  static Future<LocationDatabase> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, _filename);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            accuracy REAL NOT NULL,
            ts INTEGER NOT NULL,
            source TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_locations_ts ON $_table(ts DESC)');
      },
    );
    // Helps concurrent reads while a writer is open.
    await db.rawQuery('PRAGMA journal_mode = WAL');
    return LocationDatabase._(db);
  }

  Future<int> insertLocation({
    required double lat,
    required double lon,
    required double accuracy,
    required int tsMillis,
    required String source,
  }) {
    return _db.insert(_table, {
      'lat': lat,
      'lon': lon,
      'accuracy': accuracy,
      'ts': tsMillis,
      'source': source,
    });
  }

  Future<List<Map<String, Object?>>> recent({int limit = 50}) {
    return _db.query(_table, orderBy: 'ts DESC', limit: limit);
  }

  Future<Map<String, Object?>?> last() async {
    final rows = await _db.query(_table, orderBy: 'ts DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> close() => _db.close();
}