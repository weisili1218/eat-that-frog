/// GTD buckets a task can live in.
///
/// `done` is *not* a bucket — completion is tracked by `completedAt` so a task
/// keeps its bucket when finished (matching the prototype behaviour).
enum TaskBucket { inbox, today, later, someday }

extension TaskBucketX on TaskBucket {
  bool get isToday => this == TaskBucket.today;
}
