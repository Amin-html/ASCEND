import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/core/utils/formatters.dart';
import 'package:ascend/features/focus/domain/focus_timer.dart';

void main() {
  final t0 = DateTime(2026, 10, 6, 10);
  DateTime at(Duration d) => t0.add(d);

  group('stopwatch', () {
    test('counts up while running', () {
      final timer = FocusTimer.stopwatch().start(t0);

      expect(timer.isRunning, isTrue);
      expect(timer.elapsed(at(const Duration(seconds: 90))),
          const Duration(seconds: 90));
      expect(timer.remaining(t0), isNull);
      expect(timer.isComplete(at(const Duration(hours: 5))), isFalse);
    });

    test('pause freezes the time and resume continues it', () {
      var timer = FocusTimer.stopwatch().start(t0);

      timer = timer.pause(at(const Duration(seconds: 90)));
      expect(timer.isPaused, isTrue);
      expect(timer.elapsed(at(const Duration(seconds: 1000))),
          const Duration(seconds: 90));

      timer = timer.resume(at(const Duration(seconds: 200)));
      expect(timer.isRunning, isTrue);
      expect(timer.elapsed(at(const Duration(seconds: 230))),
          const Duration(seconds: 120));
    });

    test('startedAt is kept across pauses', () {
      final timer = FocusTimer.stopwatch()
          .start(t0)
          .pause(at(const Duration(seconds: 10)))
          .resume(at(const Duration(seconds: 20)));

      expect(timer.startedAt, t0);
    });
  });

  group('countdown', () {
    const planned = Duration(minutes: 25);

    test('remaining shrinks as time passes', () {
      final timer = FocusTimer.countdown(planned).start(t0);

      expect(timer.remaining(t0), planned);
      expect(timer.remaining(at(const Duration(minutes: 10))),
          const Duration(minutes: 15));
      expect(timer.isComplete(at(const Duration(minutes: 10))), isFalse);
    });

    test('completes exactly at the planned time', () {
      final timer = FocusTimer.countdown(planned).start(t0);

      expect(timer.isComplete(at(const Duration(minutes: 25))), isTrue);
      expect(timer.remaining(at(const Duration(minutes: 25))), Duration.zero);
    });

    test('time past the end is clamped to the planned duration', () {
      final timer = FocusTimer.countdown(planned).start(t0);
      final late = at(const Duration(minutes: 30));

      expect(timer.elapsed(late), planned);
      expect(timer.remaining(late), Duration.zero);
      expect(timer.finish(late).elapsed(at(const Duration(hours: 2))), planned);
    });

    test('pausing after the end keeps the planned duration', () {
      final timer = FocusTimer.countdown(planned)
          .start(t0)
          .pause(at(const Duration(minutes: 30)));

      expect(timer.elapsed(at(const Duration(minutes: 99))), planned);
    });

    test('paused countdown does not run down', () {
      final timer = FocusTimer.countdown(planned)
          .start(t0)
          .pause(at(const Duration(minutes: 5)));

      expect(timer.remaining(at(const Duration(minutes: 20))),
          const Duration(minutes: 20));
      expect(timer.isComplete(at(const Duration(hours: 3))), isFalse);
    });
  });

  group('state transitions', () {
    test('finish freezes the elapsed time', () {
      final done = FocusTimer.stopwatch()
          .start(t0)
          .finish(at(const Duration(minutes: 3)));

      expect(done.isFinished, isTrue);
      expect(done.elapsed(at(const Duration(hours: 1))),
          const Duration(minutes: 3));
    });

    test('invalid transitions change nothing', () {
      final idle = FocusTimer.stopwatch();
      expect(idle.pause(t0).isIdle, isTrue);
      expect(idle.resume(t0).isIdle, isTrue);
      expect(idle.finish(t0).isIdle, isTrue);

      final running = idle.start(t0);
      expect(running.start(at(const Duration(seconds: 5))).startedAt, t0);
      expect(running.resume(t0).isRunning, isTrue);

      final done = running.finish(at(const Duration(seconds: 5)));
      expect(done.pause(t0).isFinished, isTrue);
      expect(done.resume(t0).isFinished, isTrue);
    });

    test('a clock that goes backwards never gives negative time', () {
      final timer = FocusTimer.stopwatch().start(t0);

      expect(
        timer.elapsed(t0.subtract(const Duration(minutes: 1))),
        Duration.zero,
      );
    });
  });

  group('helpers', () {
    test('ceilToSeconds', () {
      expect(ceilToSeconds(Duration.zero), Duration.zero);
      expect(ceilToSeconds(const Duration(milliseconds: -5)), Duration.zero);
      expect(ceilToSeconds(const Duration(milliseconds: 1)),
          const Duration(seconds: 1));
      expect(ceilToSeconds(const Duration(milliseconds: 59100)),
          const Duration(seconds: 60));
      expect(ceilToSeconds(const Duration(seconds: 25)),
          const Duration(seconds: 25));
    });

    test('formatClock', () {
      expect(formatClock(Duration.zero), '00:00');
      expect(formatClock(const Duration(seconds: 65)), '01:05');
      expect(formatClock(const Duration(minutes: 25)), '25:00');
      expect(formatClock(const Duration(seconds: 3725)), '1:02:05');
      expect(formatClock(const Duration(seconds: -4)), '00:00');
    });

    test('plural', () {
      expect(plural(0, 'task'), '0 tasks');
      expect(plural(1, 'task'), '1 task');
      expect(plural(2, 'task'), '2 tasks');
      expect(plural(1, 'person', 'people'), '1 person');
      expect(plural(3, 'person', 'people'), '3 people');
    });
  });
}