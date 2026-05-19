import Foundation
import SQLite3

final class LocationStore {
  static let shared = LocationStore()
  private var db: OpaquePointer?
  private let queue = DispatchQueue(label: "location-store")

  private init() {}

  private func open() {
    queue.sync {
      guard db == nil else { return }
      let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      let path = docs.appendingPathComponent("locations.db").path
      if sqlite3_open(path, &db) == SQLITE_OK {
        sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
        sqlite3_exec(db, """
          CREATE TABLE IF NOT EXISTS locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            accuracy REAL NOT NULL,
            ts INTEGER NOT NULL,
            source TEXT NOT NULL
          );
        """, nil, nil, nil)
      }
    }
  }

  func append(lat: Double, lon: Double, acc: Double, ts: Int) {
    open()
    queue.async {
      var stmt: OpaquePointer?
      let sql = "INSERT INTO locations (lat, lon, accuracy, ts, source) VALUES (?, ?, ?, ?, 'slc');"
      if sqlite3_prepare_v2(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
        sqlite3_bind_double(stmt, 1, lat)
        sqlite3_bind_double(stmt, 2, lon)
        sqlite3_bind_double(stmt, 3, acc)
        sqlite3_bind_int64(stmt, 4, sqlite3_int64(ts))
        sqlite3_step(stmt)
      }
      sqlite3_finalize(stmt)
    }
  }
}