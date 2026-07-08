import '../../domain/entities.dart';
import '../../domain/repositories.dart';

class WalletController {
  WalletController(this._repo);
  final WalletRepository _repo;

  Future<void> save({
    int? id,
    required String name,
    required WalletType type,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 40) {
      throw const DomainException('Name must be 1-40 characters.');
    }
    final wallet = Wallet(
      id: id ?? 0,
      name: trimmed,
      type: type,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
    );
    if (id == null) {
      await _repo.add(wallet);
    } else {
      await _repo.update(wallet);
    }
  }

  Future<void> archive(int id) => _repo.archive(id);
  Future<void> delete(int id) => _repo.delete(id);
}
