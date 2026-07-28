import 'dart:convert';

/// A checklist item nested under a task. Persisted as JSON in the task's
/// `subtasks` column (keeps sync simple — the whole task syncs as one row).
class Subtask {
  const Subtask({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory Subtask.fromMap(Map<String, dynamic> m) => Subtask(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '') as String,
        done: m['done'] == true,
      );

  static String encode(List<Subtask> items) =>
      jsonEncode(items.map((e) => e.toMap()).toList());

  static List<Subtask> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => Subtask.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
