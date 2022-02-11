import 'package:automata/automata.dart';
import 'package:test/test.dart';

void main() {
  group('when initial state is set', () {
    test('should transition to lose if the current points are negative', () {
      final state = Scoreboard(points: -50);
      final machine = _createMachine(state);

      expect(machine.isInState<Lose>(), isTrue);
      expect(machine.isInState<Win>(), isFalse);
    });

    test('should transition to lose if award points is higher than 99', () {
      final state = Scoreboard(points: 100);
      final machine = _createMachine(state);

      expect(machine.isInState<Lose>(), isFalse);
      expect(machine.isInState<Win>(), isTrue);
    });
  });

  group('when a transition is sent', () {
    test('should transition to lose if the current points are negative', () {
      final scoreboard = Scoreboard();
      final machine = _createMachine(scoreboard);

      expect(machine.isInState<Playing>(), isTrue);

      machine.send(OnAwardPoints(points: 50));
      expect(machine.isInState<Playing>(), isTrue);

      machine.send(OnAwardPoints(points: -110));

      expect(machine.isInState<Lose>(), isTrue);
      expect(machine.isInState<Win>(), isFalse);
    });

    test('should transition to lose if award points is higher than 99', () {
      final scoreboard = Scoreboard();
      final machine = _createMachine(scoreboard);

      expect(machine.isInState<Playing>(), isTrue);

      machine.send(OnAwardPoints(points: 100));

      expect(machine.isInState<Lose>(), isFalse);
      expect(machine.isInState<Win>(), isTrue);
    });
  });
}

class Scoreboard {
  int points;

  Scoreboard({this.points = 0});
}

class Playing extends State {}

class Win extends State {}

class Lose extends State {}

class OnAwardPoints extends Event {
  final int points;

  OnAwardPoints({required this.points});
}

StateMachine _createMachine<S extends State>(Scoreboard scoreboard) {
  return StateMachine.create(
    (g) => g
      ..initial<Playing>()
      ..state<Playing>(
        builder: (b) => b
          // Eventless transition
          // Will transition to either 'win' or 'lose' immediately upon
          // entering 'playing' state or receiving OnAwardPoints event
          // if the condition is met.
          ..always<Win>(condition: (_) => scoreboard.points > 99)
          ..always<Lose>(condition: (_) => scoreboard.points < 0)
          ..on<OnAwardPoints, Playing>(actions: [
            (OnAwardPoints e) {
              scoreboard.points += e.points;
            },
          ]),
      )
      ..state<Win>(type: StateNodeType.terminal)
      ..state<Lose>(type: StateNodeType.terminal),
  );
}
