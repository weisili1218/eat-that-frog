/// GTD buckets a task can live in. v2 uses only [inbox] and [today];
/// [later]/[someday] are kept for backward-compat migration and are folded
/// into [inbox] at read time.
enum TaskBucket { inbox, today, later, someday }

extension TaskBucketX on TaskBucket {
  bool get isToday => this == TaskBucket.today;

  /// Anything not scheduled for today lives in the collect list.
  bool get isCollect => this != TaskBucket.today;
}

/// Task difficulty — drives the coloured pill and inbox sorting.
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  /// Sort weight: hard first.
  int get order => switch (this) {
        Difficulty.hard => 0,
        Difficulty.medium => 1,
        Difficulty.easy => 2,
      };
}

/// Completion type logged when a task is marked done.
enum CompletionType { frog, tadpole }
