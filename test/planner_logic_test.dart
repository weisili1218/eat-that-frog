import 'package:flutter_test/flutter_test.dart';

import 'package:eat_that_frog/core/enums.dart';
import 'package:eat_that_frog/data/local/subtask.dart';

/// Pure-logic tests for rules that must not silently regress before Beta 1.
void main() {
  group('difficulty ordering (planner + inbox sort)', () {
    test('hard sorts before medium before easy', () {
      final list = [Difficulty.easy, Difficulty.hard, Difficulty.medium]
        ..sort((a, b) => a.order.compareTo(b.order));
      expect(list, [Difficulty.hard, Difficulty.medium, Difficulty.easy]);
    });
  });

  group('subtask JSON round-trip (stored as a text column)', () {
    test('encodes and decodes without loss', () {
      final items = [
        const Subtask(id: 'a', title: '寫大綱', done: true),
        const Subtask(id: 'b', title: 'Draft intro'),
      ];
      final decoded = Subtask.decode(Subtask.encode(items));

      expect(decoded.length, 2);
      expect(decoded[0].title, '寫大綱');
      expect(decoded[0].done, isTrue);
      expect(decoded[1].done, isFalse);
    });

    test('bad or empty JSON degrades to an empty list, never throws', () {
      expect(Subtask.decode(null), isEmpty);
      expect(Subtask.decode(''), isEmpty);
      expect(Subtask.decode('not json'), isEmpty);
    });

    test('toggling a subtask preserves the others', () {
      final items = [
        const Subtask(id: 'a', title: 'one'),
        const Subtask(id: 'b', title: 'two'),
      ];
      final toggled = items
          .map((s) => s.id == 'b' ? s.copyWith(done: !s.done) : s)
          .toList();

      expect(toggled[0].done, isFalse);
      expect(toggled[1].done, isTrue);
      expect(toggled[1].title, 'two');
    });
  });

  group('bucket rules', () {
    test('only today counts as today; everything else is collect', () {
      expect(TaskBucket.today.isToday, isTrue);
      expect(TaskBucket.inbox.isToday, isFalse);
      expect(TaskBucket.inbox.isCollect, isTrue);
      // Legacy buckets fold into the collect list rather than vanishing.
      expect(TaskBucket.later.isCollect, isTrue);
      expect(TaskBucket.someday.isCollect, isTrue);
    });
  });
}
