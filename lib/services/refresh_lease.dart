import 'dart:math';
import 'package:drift/drift.dart';
import '../data/app_database.dart';

/// SQLite coordinates foreground and background Flutter engines. An in-memory
/// mutex alone cannot serialize separate isolates; an expired lease recovers
/// after Android kills a process during renewal.
Future<T> withRefreshLease<T>(
  AppDatabase db,
  Future<T> Function() action,
) async {
  final token =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  String? lease;
  while (lease == null) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final candidate =
        '${now + const Duration(minutes: 5).inMilliseconds}|$token';
    final changed = await db.customUpdate(
      'INSERT INTO preferences (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value '
      'WHERE CAST(preferences.value AS INTEGER) < ?',
      variables: [
        Variable('refresh.lease'),
        Variable(candidate),
        Variable(now),
      ],
      updates: {db.preferences},
    );
    if (changed > 0) {
      lease = candidate;
      break;
    }
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Another schedule renewal is still running');
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  try {
    return await action();
  } finally {
    await db.customUpdate(
      'DELETE FROM preferences WHERE key = ? AND value = ?',
      variables: [Variable('refresh.lease'), Variable(lease)],
      updates: {db.preferences},
    );
  }
}
