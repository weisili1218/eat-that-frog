import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/enums.dart';
import '../local/database.dart';
import 'supabase_client.dart';

/// Maps between Drift [Task] rows and the Supabase `tasks` table.
class TasksRemote {
  SupabaseClient get _c => SupabaseService.instance.client;
  String? get _userId => SupabaseService.instance.user?.id;

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> toJson(Task t, String userId) => {
        'id': t.id,
        'user_id': userId,
        'title': t.title,
        'note': t.note,
        'is_frog': t.isFrog,
        'ever_frog': t.everFrog,
        'bucket': t.bucket.name,
        'difficulty': t.difficulty.name,
        'due_date': t.dueDate == null ? null : _dateStr(t.dueDate!),
        'reminder_time': t.reminderTime,
        'duration_minutes': t.durationMinutes,
        'subtasks': jsonDecode(t.subtasks.isEmpty ? '[]' : t.subtasks),
        'completed_at': t.completedAt?.toUtc().toIso8601String(),
        'deleted': t.deleted,
        'created_at': t.createdAt.toUtc().toIso8601String(),
        'updated_at': t.updatedAt.toUtc().toIso8601String(),
      };

  static TasksCompanion fromJson(Map<String, dynamic> j) {
    return TasksCompanion(
      id: Value(j['id'] as String),
      title: Value(j['title'] as String? ?? ''),
      note: Value(j['note'] as String?),
      isFrog: Value(j['is_frog'] as bool? ?? false),
      everFrog: Value(j['ever_frog'] as bool? ?? false),
      bucket: Value(_enum(TaskBucket.values, j['bucket'], TaskBucket.inbox)),
      difficulty:
          Value(_enum(Difficulty.values, j['difficulty'], Difficulty.medium)),
      dueDate: Value(_date(j['due_date'])),
      reminderTime: Value(j['reminder_time'] as String?),
      durationMinutes: Value((j['duration_minutes'] as num?)?.toInt()),
      subtasks: Value(jsonEncode(j['subtasks'] ?? const [])),
      completedAt: Value(_dt(j['completed_at'])),
      deleted: Value(j['deleted'] as bool? ?? false),
      createdAt: Value(_dt(j['created_at']) ?? DateTime.now()),
      updatedAt: Value(_dt(j['updated_at']) ?? DateTime.now()),
      userId: Value(j['user_id'] as String?),
      pendingSync: const Value(false),
    );
  }

  Future<void> upsert(List<Task> tasks) async {
    final uid = _userId;
    if (uid == null || tasks.isEmpty) return;
    await _c.from('tasks').upsert(tasks.map((t) => toJson(t, uid)).toList());
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime? since) async {
    final uid = _userId;
    if (uid == null) return const [];
    var query = _c.from('tasks').select().eq('user_id', uid);
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static T _enum<T extends Enum>(List<T> values, dynamic name, T fallback) =>
      values.firstWhere((e) => e.name == name, orElse: () => fallback);

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);
}
