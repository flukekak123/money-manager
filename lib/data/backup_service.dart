import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/entities.dart' show DomainException;
import 'database.dart';

/// Serializes the whole database to/from a schema-versioned JSON document and
/// restores it atomically. See functional-design BR-B1..B6.
///
/// Enums are stored as their int index (matching the DB columns) and money
/// stays in integer minor units — no floating point crosses this boundary.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Current backup schema version.
  static const int schemaVersion = 1;

  /// Reads all tables and returns a pretty-printed JSON string.
  Future<String> exportJson() async {
    final wallets = await _db.select(_db.wallets).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final budgets = await _db.select(_db.budgets).get();

    final doc = <String, dynamic>{
      'version': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'wallets': [
        for (final w in wallets)
          {
            'id': w.id,
            'name': w.name,
            'type': w.type,
            'iconCodePoint': w.iconCodePoint,
            'colorValue': w.colorValue,
            'archived': w.archived,
          },
      ],
      'categories': [
        for (final c in categories)
          {
            'id': c.id,
            'name': c.name,
            'kind': c.kind,
            'iconCodePoint': c.iconCodePoint,
            'colorValue': c.colorValue,
            'isDefault': c.isDefault,
            'archived': c.archived,
          },
      ],
      'transactions': [
        for (final t in transactions)
          {
            'id': t.id,
            'amountMinor': t.amountMinor,
            'kind': t.kind,
            'categoryId': t.categoryId,
            'walletId': t.walletId,
            'date': t.date.toIso8601String(),
            'note': t.note,
            'createdAt': t.createdAt.toIso8601String(),
          },
      ],
      'budgets': [
        for (final b in budgets)
          {
            'id': b.id,
            'categoryId': b.categoryId,
            'limitMinor': b.limitMinor,
            'month': b.month,
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  /// Validates [jsonStr] and replaces ALL existing data with its contents inside
  /// a single transaction. On any error the transaction rolls back and the
  /// original data is left intact (BR-B5). Throws [DomainException] on invalid
  /// input.
  Future<void> importReplace(String jsonStr) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } on FormatException {
      throw const DomainException('Invalid or corrupt backup file');
    }

    if (decoded is! Map) {
      throw const DomainException('Invalid or corrupt backup file');
    }
    if (decoded['version'] != schemaVersion) {
      throw const DomainException('Unsupported backup version');
    }

    final wallets = _asList(decoded['wallets']);
    final categories = _asList(decoded['categories']);
    final transactions = _asList(decoded['transactions']);
    final budgets = _asList(decoded['budgets']);

    try {
      await _db.transaction(() async {
        // Delete children before parents (FK order).
        await _db.delete(_db.budgets).go();
        await _db.delete(_db.transactions).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.wallets).go();

        // Insert parents before children, preserving explicit ids.
        for (final w in wallets) {
          final m = _asMap(w);
          await _db.into(_db.wallets).insert(WalletsCompanion(
                id: Value(_int(m, 'id')),
                name: Value(_str(m, 'name')),
                type: Value(_int(m, 'type')),
                iconCodePoint: Value(_int(m, 'iconCodePoint')),
                colorValue: Value(_int(m, 'colorValue')),
                archived: Value(_bool(m, 'archived')),
              ));
        }
        for (final c in categories) {
          final m = _asMap(c);
          await _db.into(_db.categories).insert(CategoriesCompanion(
                id: Value(_int(m, 'id')),
                name: Value(_str(m, 'name')),
                kind: Value(_int(m, 'kind')),
                iconCodePoint: Value(_int(m, 'iconCodePoint')),
                colorValue: Value(_int(m, 'colorValue')),
                isDefault: Value(_bool(m, 'isDefault')),
                archived: Value(_bool(m, 'archived')),
              ));
        }
        for (final t in transactions) {
          final m = _asMap(t);
          await _db.into(_db.transactions).insert(TransactionsCompanion(
                id: Value(_int(m, 'id')),
                amountMinor: Value(_int(m, 'amountMinor')),
                kind: Value(_int(m, 'kind')),
                categoryId: Value(_int(m, 'categoryId')),
                walletId: Value(_int(m, 'walletId')),
                date: Value(_dateTime(m, 'date')),
                note: Value(m['note'] as String?),
                createdAt: Value(_dateTime(m, 'createdAt')),
              ));
        }
        for (final b in budgets) {
          final m = _asMap(b);
          await _db.into(_db.budgets).insert(BudgetsCompanion(
                id: Value(_int(m, 'id')),
                categoryId: Value(_int(m, 'categoryId')),
                limitMinor: Value(_int(m, 'limitMinor')),
                month: Value(_str(m, 'month')),
              ));
        }
      });
    } on DomainException {
      rethrow;
    } catch (_) {
      // Any type/DB error during restore surfaces as a clean domain error;
      // the transaction has already rolled back.
      throw const DomainException('Invalid or corrupt backup file');
    }
  }

  // --- defensive parsing helpers ---

  static List<dynamic> _asList(Object? v) {
    if (v is List) return v;
    throw const DomainException('Invalid or corrupt backup file');
  }

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map) return v.cast<String, dynamic>();
    throw const DomainException('Invalid or corrupt backup file');
  }

  static int _int(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is int) return v;
    throw const DomainException('Invalid or corrupt backup file');
  }

  static String _str(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String) return v;
    throw const DomainException('Invalid or corrupt backup file');
  }

  static bool _bool(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is bool) return v;
    throw const DomainException('Invalid or corrupt backup file');
  }

  static DateTime _dateTime(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    throw const DomainException('Invalid or corrupt backup file');
  }
}
