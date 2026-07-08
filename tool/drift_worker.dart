// Source for the drift web worker. Kept out of web/ so the .dart source is not
// bundled. Recompile the shipped worker after a drift upgrade with:
//   dart compile js -O2 tool/drift_worker.dart -o web/drift_worker.js
// The compiled web/drift_worker.js is what the app loads at runtime
// (see lib/data/connection/connection_web.dart).
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
