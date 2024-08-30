import 'dart:async';
import 'dart:ui';

class CountdownManager {
  late int _remainingDuration;
  final Function(int) onTick;
  final VoidCallback onComplete;
  Timer? _timer;

  CountdownManager({
    required int initialDuration,
    required this.onTick,
    required this.onComplete,
  }) {
    _remainingDuration = initialDuration;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingDuration > 0) {
        _remainingDuration--;
        onTick(_remainingDuration);
      } else {
        _timer?.cancel();
        onComplete();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
