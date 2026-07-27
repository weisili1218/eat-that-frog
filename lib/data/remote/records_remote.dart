import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/database.dart';
import 'supabase_client.dart';

/// Maps between Drift [DailyRecord] rows and the Supabase `daily_records` table.
class RecordsRemote {
  SupabaseClient get _c => SupabaseService.instance.client;
  String? get _userId => SupabaseService.instance.user?.id;

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> toJson(DailyRecord r, String userId) => {
        'id': r.id,
        'user_id': userId,
        'date': _dateStr(r.date),
        'frog_completed': r.frogCompleted,
        'total_completed': r.totalCompleted,
        'current_streak': r.currentStreak,
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
      };

  static DailyRecordsCompanion fromJson(Map<String, dynamic> j) {
    return DailyRecordsCompanion(
      id: Value(j['id'] as String),
      date: Value(DateTime.parse(j['date'] as String)),
      frogCompleted: Value(j['frog_completed'] as bool? ?? false),
      totalCompleted: Value((j['total_completed'] as num?)?.toInt() ?? 0),
      currentStreak: Value((j['current_streak'] as num?)?.toInt() ?? 0),
      userId: Value(j['user_id'] as String?),
      updatedAt: Value(j['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(j['updated_at'] as String).toLocal()),
      pendingSync: const Value(false),
    );
  }

  Future<void> upsert(List<DailyRecord> records) async {
    final uid = _userId;
    if (uid == null || records.isEmpty) return;
    // Conflict target is (user_id, date) — supabase upsert on primary key id is
    // fine because we keep stable ids per (user, date) locally.
    await _c.from('daily_records').upsert(
          records.map((r) => toJson(r, uid)).toList(),
          onConflict: 'user_id,date',
        );
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime? since) async {
    final uid = _userId;
    if (uid == null) return const [];
    var query = _c.from('daily_records').select().eq('user_id', uid);
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
