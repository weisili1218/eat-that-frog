import '../../core/enums.dart';
import 'database.dart';

/// Convenience getters over the Drift-generated [Task] row.
extension TaskX on Task {
  /// A task is "done" when it has a completion timestamp.
  bool get done => completedAt != null;

  bool get isTadpole => !isFrog;

  bool get inToday => bucket == TaskBucket.today;
}
