import 'package:flutter_test/flutter_test.dart';
import 'package:state_machine/state_machine.dart';

StateMachine createMachine() {
  final machine = StateMachine.create(
    (g) => g
      ..initialState<Start>()
      ..state<Start>((g) => g..on<OnKickStart, Main>())
      ..state<Main>(
        (g) => g
          ..on<OnTickFirst, First>()
          ..on<OnTickSecond, Second>()
          ..coregion<First>(
            (g) => g
              ..initialState<One>()
              ..state<One>((g) => g..on<OnToggle, Two>())
              ..state<Two>((g) => g..on<OnToggle, One>()),
          )
          ..coregion<Second>(
            (g) => g
              ..initialState<Three>()
              ..state<Three>((g) => g..on<OnToggle, Four>())
              ..state<Four>((g) => g..on<OnToggle, Three>()),
          ),
      ),
  );
  return machine;
}

class OnKickStart implements Event {}

class Main implements State {}

class Start implements State {}

class First implements State {}

class Second implements State {}

class One implements State {}

class Two implements State {}

class Three implements State {}

class Four implements State {}

class OnTickFirst implements Event {}

class OnTickSecond implements Event {}

class OnToggle implements Event {}

void main() {
  test('should properly define initial state', () async {
    final machine = createMachine();
    expect(machine.isInState<Start>(), equals(true));
  });

  test('should transition to intial state of nested machine', () async {
    final machine = createMachine();

    machine.send(OnKickStart());
    expect(machine.isInState<Main>(), equals(true));
    // expect(machine.isInState<First>(), equals(true));
    // expect(machine.isInState<One>(), equals(true));
    // expect(machine.isInState<Second>(), equals(true));
    // expect(machine.isInState<Three>(), equals(true));
  });

  test('should be able to transition nested stated machines', () async {
    final machine = createMachine();

    machine.send(OnKickStart());
    expect(machine.isInState<Main>(), equals(true));
    expect(machine.isInState<First>(), equals(true));
    expect(machine.isInState<One>(), equals(true));
    expect(machine.isInState<Second>(), equals(true));
    expect(machine.isInState<Three>(), equals(true));

    machine.send(OnToggle());
    expect(machine.isInState<Main>(), equals(true));
    expect(machine.isInState<First>(), equals(true));
    expect(machine.isInState<Two>(), equals(true));
    expect(machine.isInState<Second>(), equals(true));
    expect(machine.isInState<Four>(), equals(true));
  });

  test(
    'should reset state back to initial state if transition to state '
    'machine again',
    () async {
      final machine = createMachine();

      machine.send(OnKickStart());
      expect(machine.isInState<Main>(), equals(true));
      expect(machine.isInState<First>(), equals(true));
      expect(machine.isInState<One>(), equals(true));
      expect(machine.isInState<Second>(), equals(true));
      expect(machine.isInState<Three>(), equals(true));

      machine.send(OnToggle());
      expect(machine.isInState<Main>(), equals(true));
      expect(machine.isInState<First>(), equals(true));
      expect(machine.isInState<Two>(), equals(true));
      expect(machine.isInState<Second>(), equals(true));
      expect(machine.isInState<Four>(), equals(true));

      machine.send(OnTickFirst());
      expect(machine.isInState<Main>(), equals(true));
      // First goes back to initial state
      expect(machine.isInState<First>(), equals(true));
      expect(machine.isInState<One>(), equals(true));
      // Second remains with previous state
      expect(machine.isInState<Second>(), equals(true));
      expect(machine.isInState<Four>(), equals(true));
    },
  );
}
