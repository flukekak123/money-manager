import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import '../../data/backup_service.dart';
import '../../domain/entities.dart';

/// Orchestrates data export/import: file dialogs + [BackupService]. Works on
/// web (browser download / picker) and mobile (share sheet / picker).
class BackupController {
  BackupController(this._service);

  final BackupService _service;

  /// Exports all data to a JSON file. On web this triggers a download; on
  /// mobile it saves/shares a file. Returns the saved file path/name.
  Future<String> export() async {
    final json = await _service.exportJson();
    final bytes = Uint8List.fromList(utf8.encode(json));
    return FileSaver.instance.saveFile(
      name: 'money-manager-backup-${_todayStamp()}',
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.json,
    );
  }

  /// Prompts the user to pick a JSON backup and restores it (replace-all).
  /// Returns `false` if the user cancelled. Throws [DomainException] on an
  /// unreadable or invalid file.
  Future<bool> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      throw const DomainException('Could not read the selected file.');
    }
    await _service.importReplace(utf8.decode(bytes));
    return true;
  }

  String _todayStamp() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
