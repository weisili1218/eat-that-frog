import 'package:flutter/material.dart';

/// A user profile as seen on the leaderboard / friends list.
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.avatarColor,
    required this.streak,
    required this.frogsEaten,
    this.focusTask,
    this.focusStartedAt,
  });

  final String id;
  final String displayName;
  final String avatarColor;
  final int streak;
  final int frogsEaten;
  final String? focusTask;
  final DateTime? focusStartedAt;

  bool get isFocusing => focusStartedAt != null;

  int get focusMinutes => focusStartedAt == null
      ? 0
      : DateTime.now().difference(focusStartedAt!).inMinutes;

  String get initial =>
      displayName.trim().isEmpty ? '?' : displayName.trim().characters.first.toUpperCase();

  Color get color {
    final hex = avatarColor.replaceAll('#', '');
    final v = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return v == null ? const Color(0xFFB5502E) : Color(v);
  }

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: (m['display_name'] as String?)?.trim().isNotEmpty == true
            ? m['display_name'] as String
            : '青蛙夥伴',
        avatarColor: (m['avatar_color'] as String?) ?? '#B5502E',
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        frogsEaten: (m['frogs_eaten'] as num?)?.toInt() ?? 0,
        focusTask: m['focus_task'] as String?,
        focusStartedAt: m['focus_started_at'] == null
            ? null
            : DateTime.tryParse(m['focus_started_at'] as String)?.toLocal(),
      );
}

/// A group-chat message.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        text: (m['text'] as String?) ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

/// Avatar palette offered in the profile editor.
const kAvatarColors = [
  '#B5502E', '#3F8F5F', '#A8383D', '#4A6FA5', '#8A5CA8', '#C08A2E',
];
