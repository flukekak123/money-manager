// Platform-split database connection. On native (mobile/desktop) we open a
// file-backed SQLite via NativeDatabase; on web we open a WasmDatabase backed
// by OPFS/IndexedDB. The conditional export ensures `dart:io`/`path_provider`
// are never referenced in a web build, and that importers of this file get the
// correct `openConnection()` for the current platform.
//
// IMPORTANT: this file must contain ONLY the conditional export. Declaring a
// local `openConnection()` here would shadow the exported one and get called
// instead (it previously threw "Unsupported operation" at runtime).
export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
