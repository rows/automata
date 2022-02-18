import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:test/test.dart';

void main() {
  test('should set initial state', () {
    final machine = _createMachine();
    expect(machine.matchesStatePath([Start, Level1, Level11]), isTrue);
    expect(machine.matchesStatePath([Start, Level2, Level21]), isTrue);
  });

  test(
    'should transition to initial when first navigates into a compound state',
    () {
      final machine = _createMachine();
      machine.send(OnMove());
      expect(
        machine.matchesStatePath([Start, Level1, Level12, Level121]),
        isTrue,
      );
    },
  );

  test(
    'should transition to initial when first navigates into a parallel state',
    () {
      final machine = _createMachine();
      machine.send(OnMove());
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level221]),
        isTrue,
      );
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level222]),
        isTrue,
      );
    },
  );

  test(
    'should keep previous state if its already within a compound state',
    () {
      final machine = _createMachine();
      machine.send(OnMove());
      expect(
        machine.matchesStatePath([Start, Level1, Level12, Level121]),
        isTrue,
      );
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level221]),
        isTrue,
      );
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level222]),
        isTrue,
      );

      machine.send(OnMoveToFirstLevel());

      expect(
        machine.matchesStatePath([Start, Level1, Level11]),
        isTrue,
      );
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level221]),
        isTrue,
      );
      expect(
        machine.matchesStatePath([Start, Level2, Level22, Level222]),
        isTrue,
      );
    },
  );
}

class Start extends State {}

class Level1 extends State {}

class Level11 extends State {}

class Level12 extends State {}

class Level121 extends State {}

class Level122 extends State {}

class Level2 extends State {}

class Level21 extends State {}

class Level22 extends State {}

class Level221 extends State {}

class Level222 extends State {}

class OnMove extends Event {}

class OnMoveToFirstLevel extends Event {}

// https://stately.ai/viz/c722fba1-4f48-449f-8734-ad0d5c0c709a
StateMachine _createMachine() {
  final machine = StateMachine.create(
    (g) => g
      ..initial<Start>()
      ..state<Start>(
        type: StateNodeType.parallel,
        builder: (b) => b
          ..on<OnMoveToFirstLevel, Level1>()

          // States
          ..state<Level1>(
            builder: (b) => b
              ..initial<Level11>()
              ..state<Level11>(
                builder: (b) => b..on<OnMove, Level12>(),
              )
              ..state<Level12>(
                builder: (b) => b
                  ..initial<Level121>()
                  ..state<Level121>()
                  ..state<Level122>(),
              ),
          )
          ..state<Level2>(
            builder: (b) => b
              ..initial<Level21>()
              ..state<Level21>(
                builder: (b) => b..on<OnMove, Level22>(),
              )
              ..state<Level22>(
                type: StateNodeType.parallel,
                builder: (b) => b
                  ..state<Level221>()
                  ..state<Level222>(),
              ),
          ),
      ),
  );
  return machine;
}
