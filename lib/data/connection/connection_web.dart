import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web: WasmDatabase persisted in OPFS (falls back to IndexedDB). Requires
/// `sqlite3.wasm` and `drift_worker.js` to be served from `web/`.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'money_manager',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
