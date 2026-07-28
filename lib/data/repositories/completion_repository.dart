import '../local/completions_dao.dart';
import '../local/database.dart';

/// Read/reset access to the completions log (stats + streak source).
class CompletionRepository {
  CompletionRepository(this._dao, {this.onLocalChange});

  final CompletionsDao _dao;
  final Future<void> Function()? onLocalChange;

  Stream<List<Completion>> watchAll() => _dao.watchAll();
  Future<List<Completion>> getAll() => _dao.getAll();

  Future<void> resetAll() async {
    await _dao.clearAll();
    if (onLocalChange != null) await onLocalChange!();
  }
}
