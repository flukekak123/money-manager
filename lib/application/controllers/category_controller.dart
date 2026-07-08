import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class CategoryController {
  CategoryController(this._repo);
  final CategoryRepository _repo;

  Future<void> save({
    int? id,
    required String name,
    required TransactionKind kind,
    required int iconCodePoint,
    required int colorValue,
    bool isDefault = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw const DomainException('Name must be 1-40 characters.');
    }
    final category = Category(
      id: id ?? 0,
      name: trimmed,
      kind: kind,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isDefault: isDefault,
    );
    if (id == null) {
      await _repo.add(category);
    } else {
      await _repo.update(category);
    }
  }

  Future<void> archive(int id) => _repo.archive(id);
  Future<void> delete(int id) => _repo.delete(id);
}
