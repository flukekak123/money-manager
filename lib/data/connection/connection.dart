import 'package:drift/drift.dart';

// Platform-split database connection. On native (mobile/desktop) we open a
// file-backed SQLite via NativeDatabase; on web we open a WasmDatabase backed
// by OPFS/IndexedDB. The conditional export ensures `dart:io`/`path_provider`
// are never referenced in a web build.
export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

/// Implemented by each platform file: returns the executor for [AppDatabase].
QueryExecutor openConnection() => throw UnsupportedError(
      'openConnection is provided by a platform-specific implementation',
    );
