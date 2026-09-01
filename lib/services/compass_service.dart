import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../qibla_logic.dart';

/// How much the magnetometer reading can be trusted right now.
enum CompassConfidence {
  /// No usable event has arrived yet.
  unknown,

  /// Readings are tight and the platform reports a small error.
  high,

  /// Usable, but worth a calibration nudge.
  medium,

  /// Readings are swinging or the platform reports a large error.
  low,

  /// No compass hardware, or the sensor never produced a reading.
  unavailable,
}

/// A smoothed, trust-scored compass heading.
///
/// Two things make this different from listening to [FlutterCompass] directly:
///
/// * The heading is low-pass filtered along the *shortest arc*, so it glides
///   instead of jittering and never spins the long way round at the 0/360 seam.
/// * Raw samples are kept in a short rolling window and measured for angular
///   spread, which is what a magnet or a steel desk actually looks like.
class CompassService {
  CompassService({
    this.smoothingFactor = 0.18,
    this.interferenceThresholdDegrees = 22.0,
    this.startupTimeout = const Duration(seconds: 5),
  });

  /// 0..1. Lower is smoother but laggier.
  final double smoothingFactor;

  /// Circular standard deviation above which we call it interference.
  final double interferenceThresholdDegrees;

  /// If no valid heading arrives in this long, assume there is no magnetometer.
  final Duration startupTimeout;

  /// Smoothed heading in degrees from **magnetic** north.
  final ValueNotifier<double?> heading = ValueNotifier<double?>(null);

  /// Smoothed heading in degrees from **true** north, i.e. [heading] corrected
  /// by the local magnetic declination. This is what the Qibla needle uses,
  /// because a Qibla bearing is a great-circle bearing from true north.
  ///
  /// Falls back to the magnetic heading whenever declination is unknown, so an
  /// unavailable model degrades to the old behaviour instead of no compass.
  final ValueNotifier<double?> trueHeading = ValueNotifier<double?>(null);

  /// Degrees to add to a magnetic heading to get a true heading, or null when
  /// the position is not yet known.
  final ValueNotifier<double?> declination = ValueNotifier<double?>(null);

  /// Current trust level. Changes rarely, so the surrounding UI can listen.
  final ValueNotifier<CompassConfidence> confidence =
      ValueNotifier<CompassConfidence>(CompassConfidence.unknown);

  /// True when the raw readings are swinging more than they should be.
  final ValueNotifier<bool> interferenceDetected = ValueNotifier<bool>(false);

  StreamSubscription<CompassEvent>? _subscription;
  Timer? _startupTimer;
  final Queue<double> _window = Queue<double>();
  double? _smoothed;
  double? _platformAccuracy;
  bool _started = false;
  bool _disposed = false;

  static const int _windowSize = 24;

  /// Begins listening. Safe to call more than once.
  void start() {
    if (_started || _disposed) return;
    _started = true;

    final events = FlutterCompass.events;
    if (events == null) {
      confidence.value = CompassConfidence.unavailable;
      return;
    }

    // If the sensor is absent the stream simply stays silent, so time it out
    // rather than leaving the user on a compass that never moves.
    _startupTimer = Timer(startupTimeout, () {
      if (_disposed) return;
      if (heading.value == null) {
        confidence.value = CompassConfidence.unavailable;
      }
    });

    _subscription = events.listen(
      _onEvent,
      onError: (Object error, StackTrace stackTrace) {
        // A dead platform channel must degrade, not crash the app.
        debugPrint('CompassService: sensor error: $error');
        if (_disposed) return;
        if (heading.value == null) {
          confidence.value = CompassConfidence.unavailable;
        }
      },
      cancelOnError: false,
    );
  }

  void _onEvent(CompassEvent event) {
    if (_disposed) return;

    final raw = event.heading;
    // A null heading means the sensor is still settling. Hold the last good
    // value instead of snapping the needle to north.
    if (raw == null || !raw.isFinite) return;

    final normalized = QiblaDirection.normalize(raw);
    _platformAccuracy = event.accuracy;

    _window.addLast(normalized);
    while (_window.length > _windowSize) {
      _window.removeFirst();
    }

    final previous = _smoothed;
    if (previous == null) {
      _smoothed = normalized;
    } else {
      final delta = QiblaDirection.shortestDelta(previous, normalized);
      _smoothed = QiblaDirection.normalize(previous + delta * smoothingFactor);
    }

    _startupTimer?.cancel();
    heading.value = _smoothed;
    _publishTrueHeading();
    _updateConfidence();
  }

  /// Supplies the local declination. Safe to call before any sensor reading.
  void setDeclination(double? degrees) {
    if (_disposed) return;
    if (degrees != null && !degrees.isFinite) return;
    if (declination.value == degrees) return;
    declination.value = degrees;
    _publishTrueHeading();
  }

  void _publishTrueHeading() {
    final magnetic = _smoothed;
    if (magnetic == null) return;
    final offset = declination.value ?? 0;
    trueHeading.value = QiblaDirection.normalize(magnetic + offset);
  }

  void _updateConfidence() {
    final spread = _circularStdDevDegrees();
    final interference =
        spread != null && spread > interferenceThresholdDegrees;

    if (interferenceDetected.value != interference) {
      interferenceDetected.value = interference;
    }

    final accuracy = _platformAccuracy;
    CompassConfidence next;
    if (interference) {
      next = CompassConfidence.low;
    } else if (accuracy == null) {
      // Android hard-codes accuracy for several devices, so fall back to the
      // observed spread when the platform will not tell us anything useful.
      if (spread == null) {
        next = CompassConfidence.unknown;
      } else if (spread <= 8) {
        next = CompassConfidence.high;
      } else if (spread <= interferenceThresholdDegrees) {
        next = CompassConfidence.medium;
      } else {
        next = CompassConfidence.low;
      }
    } else if (accuracy.abs() <= 15) {
      next = CompassConfidence.high;
    } else if (accuracy.abs() <= 30) {
      next = CompassConfidence.medium;
    } else {
      next = CompassConfidence.low;
    }

    if (confidence.value != next) confidence.value = next;
  }

  /// Circular standard deviation of the sample window, in degrees.
  ///
  /// Plain arithmetic stddev is wrong for angles: 359° and 1° are 2° apart, not
  /// 358°. This resolves each sample to a unit vector and measures the length
  /// of the mean resultant instead.
  double? _circularStdDevDegrees() {
    if (_window.length < 8) return null;

    var sumSin = 0.0;
    var sumCos = 0.0;
    for (final sample in _window) {
      final radians = sample * math.pi / 180.0;
      sumSin += math.sin(radians);
      sumCos += math.cos(radians);
    }

    final n = _window.length;
    final resultant = math.sqrt(sumSin * sumSin + sumCos * sumCos) / n;
    // Clamp guards against a resultant of exactly 0, where log() diverges.
    final clamped = resultant.clamp(1e-6, 1.0);
    final stdDevRadians = math.sqrt(-2 * math.log(clamped));
    return stdDevRadians * 180.0 / math.pi;
  }

  /// Drops the sample history, e.g. after the user has recalibrated.
  void resetCalibration() {
    _window.clear();
    interferenceDetected.value = false;
    confidence.value =
        heading.value == null ? CompassConfidence.unknown : confidence.value;
  }

  void dispose() {
    _disposed = true;
    _startupTimer?.cancel();
    _startupTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _window.clear();
    heading.dispose();
    trueHeading.dispose();
    declination.dispose();
    confidence.dispose();
    interferenceDetected.dispose();
  }
}
