import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Thin typed wrapper over the single SQLite file the app uses to
/// persist every fix. Schema and query helpers live here so the rest
/// of the codebase never sees raw SQL.
///
/// Same file (`locations.db`) is also opened from native Swift on iOS
/// for the headless SLC writes — that's why the schema columns are
/// duplicated in `LocationStore.swift`. Keep them in sync.
@lazySingleton
class LocationDatabase {
  LocationDatabase._(this._db);

  final Database _db;

  static const _filename = 'locations.db';
  static const _table = 'locations';

  /// Async factory wired into `injectable` via [factoryMethod] +
  /// [preResolve]: the future is awaited once during
  /// `configureDependencies()` so the rest of the graph can resolve
  /// synchronously. Anything that holds a `LocationDatabase` injected
  /// at construction time is therefore guaranteed an already-open DB.
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
        // Almost every query in the app is "give me the newest rows",
        // so we cover the ORDER BY ts DESC path explicitly.
        await db.execute('CREATE INDEX idx_locations_ts ON $_table(ts DESC)');
      },
    );
    // WAL allows the UI to read while a write is in flight — important
    // because the native iOS SLC writer can append to the same file
    // while the Dart UI is reading from it.
    //
    // `rawQuery` (not `execute`) because PRAGMA statements return a
    // result set on Android and sqflite refuses to silence it.
    await db.rawQuery('PRAGMA journal_mode = WAL');
    return LocationDatabase._(db);
  }

  /// Append a single fix. Returns the new row id, which we don't use
  /// today but keep around for free in case callers want it.
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

  /// Newest `limit` rows, in newest-first order. Page-side code (the
  /// history page) does grouping on top of this raw stream.
  Future<List<Map<String, Object?>>> recent({int limit = 50}) {
    return _db.query(_table, orderBy: 'ts DESC', limit: limit);
  }

  /// Most recent single row, or `null` on a fresh install. Used by the
  /// BLoC at boot to rehydrate the UI before the first live fix arrives.
  Future<Map<String, Object?>?> last() async {
    final rows = await _db.query(_table, orderBy: 'ts DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> close() => _db.close();
}
