import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/enums.dart';
import '../local/database.dart';
import 'supabase_client.dart';

/// Maps between Drift [Completion] rows and the Supabase `completions` table.
class CompletionsRemote {
  SupabaseClient get _c => SupabaseService.instance.client;
  String? get _userId => SupabaseService.instance.user?.id;

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> toJson(Completion r, String userId) => {
        'id': r.id,
        'user_id': userId,
        'date': _dateStr(r.date),
        'type': r.type.name,
        'task_id': r.taskId,
        'deleted': r.deleted,
        'created_at': r.createdAt.toUtc().toIso8601String(),
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
      };

  static CompletionsCompanion fromJson(Map<String, dynamic> j) {
    return CompletionsCompanion(
      id: Value(j['id'] as String),
      date: Value(DateTime.parse(j['date'] as String)),
      type: Value(CompletionType.values
          .firstWhere((e) => e.name == j['type'], orElse: () => CompletionType.tadpole)),
      taskId: Value(j['task_id'] as String?),
      deleted: Value(j['deleted'] as bool? ?? false),
      userId: Value(j['user_id'] as String?),
      createdAt: Value(j['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(j['created_at'] as String).toLocal()),
      updatedAt: Value(j['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(j['updated_at'] as String).toLocal()),
      pendingSync: const Value(false),
    );
  }

  Future<void> upsert(List<Completion> rows) async {
    final uid = _userId;
    if (uid == null || rows.isEmpty) return;
    await _c.from('completions').upsert(rows.map((r) => toJson(r, uid)).toList());
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime? since) async {
    final uid = _userId;
    if (uid == null) return const [];
    var query = _c.from('completions').select().eq('user_id', uid);
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
