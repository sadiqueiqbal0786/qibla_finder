/// Confirms alignment only after reliable readings stay near the target.
class AlignmentTracker {
  DateTime? _since;
  bool _aligned = false;
  bool update({
    required DateTime now,
    required double? delta,
    required bool reliable,
  }) {
    if (!reliable || delta == null || delta.abs() > (_aligned ? 8 : 5)) {
      _since = null;
      return _aligned = false;
    }
    _since ??= now;
    return _aligned = now.difference(_since!) >= const Duration(seconds: 1);
  }

  void reset() {
    _since = null;
    _aligned = false;
  }
}
