import 'dart:async';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start timing an operation
  static void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();
    print('⏱️ Started timing: $operationName');
  }

  /// End timing an operation and log the result
  static void endTimer(String operationName) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsed;

      // Store measurement for averaging
      _measurements.putIfAbsent(operationName, () => []).add(duration);

      // Calculate average
      final measurements = _measurements[operationName]!;
      final average = measurements.fold<Duration>(
            Duration.zero,
            (sum, duration) => sum + duration,
          ) ~/
          measurements.length;

      print(
          '⏱️ $operationName completed in ${duration.inMilliseconds}ms (avg: ${average.inMilliseconds}ms)');

      // Warn if operation is slow
      if (duration.inMilliseconds > 1000) {
        print(
            '⚠️  SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms');
      }

      _timers.remove(operationName);
    }
  }

  /// Time an async operation
  static Future<T> timeAsync<T>(
      String operationName, Future<T> Function() operation) async {
    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }

  /// Get performance statistics
  static Map<String, Map<String, dynamic>> getStatistics() {
    final stats = <String, Map<String, dynamic>>{};

    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      final total = measurements.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final average = total ~/ measurements.length;
      final min = measurements.reduce((a, b) => a < b ? a : b);
      final max = measurements.reduce((a, b) => a > b ? a : b);

      stats[entry.key] = {
        'count': measurements.length,
        'average_ms': average.inMilliseconds,
        'min_ms': min.inMilliseconds,
        'max_ms': max.inMilliseconds,
        'total_ms': total.inMilliseconds,
      };
    }

    return stats;
  }

  /// Clear all measurements
  static void clear() {
    _timers.clear();
    _measurements.clear();
  }

  /// Print performance summary
  static void printSummary() {
    final stats = getStatistics();
    if (stats.isEmpty) {
      print('📊 No performance data available');
      return;
    }

    print('📊 Performance Summary:');
    for (final entry in stats.entries) {
      final data = entry.value;
      print('  ${entry.key}:');
      print('    Count: ${data['count']}');
      print('    Average: ${data['average_ms']}ms');
      print('    Min: ${data['min_ms']}ms');
      print('    Max: ${data['max_ms']}ms');
      print('    Total: ${data['total_ms']}ms');
    }
  }
}
