import 'package:automata/automata.dart';
import 'package:test/test.dart';

StateMachine createMachine() {
  final machine = StateMachine.create(
    (g) => g
      ..initial<Start>()
      ..state<Start>(builder: (g) => g..on<OnKickStart, Main>())
      ..state<Main>(
        type: StateNodeType.parallel,
        builder: (g) => g
          ..on<OnTickFirst, First>()
          ..on<OnTickSecond, Second>()
          ..state<First>(
            builder: (g) => g
              ..initial<One>()
              ..state<One>(builder: (g) => g..on<OnToggle, Two>())
              ..state<Two>(builder: (g) => g..on<OnToggle, One>()),
          )
          ..state<Second>(
            builder: (g) => g
              ..initial<Three>()
              ..state<Three>(builder: (g) => g..on<OnToggle, Four>())
              ..state<Four>(builder: (g) => g..on<OnToggle, Three>()),
          ),
      ),
  );
  return machine;
}

class OnKickStart implements AutomataEvent {}

class Main implements AutomataState {}

class Start implements AutomataState {}

class First implements AutomataState {}

class Second implements AutomataState {}

class One implements AutomataState {}

class Two implements AutomataState {}

class Three implements AutomataState {}

class Four implements AutomataState {}

class OnTickFirst implements AutomataEvent {}

class OnTickSecond implements AutomataEvent {}

class OnToggle implements AutomataEvent {}

void main() {
  test('should properly define initial state', () async {
    final machine = createMachine();
    expect(machine.isInState<Start>(), isTrue);
  });

  test('should transition to intial state of compound machine', () async {
    final machine = createMachine();

    expect(machine.isInState<Start>(), isTrue);
    expect(machine.isInState<Main>(), isFalse);

    machine.send(OnKickStart());
    expect(machine.isInState<Main>(), isTrue);
    expect(machine.isInState<First>(), isTrue);
    expect(machine.isInState<One>(), isTrue);
    expect(machine.isInState<Two>(), isFalse);
    expect(machine.isInState<Second>(), isTrue);
    expect(machine.isInState<Three>(), isTrue);
    expect(machine.isInState<Four>(), isFalse);
  });

  test('should be able to transition compound stated machines', () async {
    final machine = createMachine();

    machine.send(OnKickStart());
    expect(machine.isInState<Main>(), isTrue);
    expect(machine.isInState<First>(), isTrue);
    expect(machine.isInState<One>(), isTrue);
    expect(machine.isInState<Two>(), isFalse);
    expect(machine.isInState<Second>(), isTrue);
    expect(machine.isInState<Three>(), isTrue);
    expect(machine.isInState<Four>(), isFalse);

    machine.send(OnToggle());
    expect(machine.isInState<Main>(), isTrue);
    expect(machine.isInState<First>(), isTrue);
    expect(machine.isInState<One>(), isFalse);
    expect(machine.isInState<Two>(), isTrue);
    expect(machine.isInState<Second>(), isTrue);
    expect(machine.isInState<Three>(), isFalse);
    expect(machine.isInState<Four>(), isTrue);
  });

  test(
    'should reset state back to initial state if transition to state '
    'machine again',
    () async {
      final machine = createMachine();

      machine.send(OnKickStart());
      expect(machine.isInState<Main>(), isTrue);
      expect(machine.isInState<First>(), isTrue);
      expect(machine.isInState<One>(), isTrue);
      expect(machine.isInState<Two>(), isFalse);
      expect(machine.isInState<Second>(), isTrue);
      expect(machine.isInState<Three>(), isTrue);
      expect(machine.isInState<Four>(), isFalse);

      machine.send(OnToggle());
      expect(machine.isInState<Main>(), isTrue);
      expect(machine.isInState<First>(), isTrue);
      expect(machine.isInState<One>(), isFalse);
      expect(machine.isInState<Two>(), isTrue);
      expect(machine.isInState<Second>(), isTrue);
      expect(machine.isInState<Three>(), isFalse);
      expect(machine.isInState<Four>(), isTrue);

      machine.send(OnTickFirst());
      expect(machine.isInState<Main>(), isTrue);
      // First goes back to initial state
      expect(machine.isInState<First>(), isTrue);
      expect(machine.isInState<One>(), isTrue);
      expect(machine.isInState<Two>(), isFalse);
      // Second should keep previous state
      expect(machine.isInState<Second>(), isTrue);
      expect(machine.isInState<Three>(), isFalse);
      expect(machine.isInState<Four>(), isTrue);
    },
  );
}
