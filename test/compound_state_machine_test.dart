import 'package:automata/automata.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'utils/watcher.dart';

void main() {
  late Watcher watcher;
  late Human human;

  setUp(() {
    watcher = MockWatcher();
    human = Human();
  });

  test('should set initial state to Alive and Young', () async {
    final machine = await _createMachine<Alive>(watcher, human);

    expect(machine.isInState(Alive), isTrue);
    expect(machine.isInState(Young), isTrue);
  });

  test(
    'should keep machine in same state if the matched transition is for '
    'the current state',
    () async {
      final machine = await _createMachine<Alive>(watcher, human);
      machine.send(OnBirthday());

      expect(machine.isInState(Alive), isTrue);
      expect(machine.isInState(Young), isTrue);
    },
  );

  test('should move to next state when condition is met', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    for (var i = 0; i < 18; i++) {
      machine.send(OnBirthday());
    }

    // Move the last send outside of the loop to ease debug.
    machine.send(OnBirthday());

    expect(machine.isInState(Alive), isTrue);
    expect(machine.isInState(Young), isFalse);
    expect(machine.isInState(MiddleAged), isTrue);
  });

  test('Test multiple transitions', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnBirthday());

    expect(machine.isInState(Young), isTrue);
    machine.send(OnDeath());

    expect(machine.isInState(Dead), isTrue);
    expect(machine.isInState(Purgatory), isTrue);
  });

  test('should transition to child state', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnDeath());

    expect(machine.isInState(Dead), isTrue);
    expect(machine.isInState(Purgatory), isTrue);
    expect(machine.isInState(Alive), isFalse);
    machine.send(const OnJudged(Judgement.morallyAmbiguous));

    expect(machine.isInState(Matrix), isTrue);
    expect(machine.isInState(Dead), isTrue);
    expect(machine.isInState(Purgatory), isTrue);

    /// We should be MiddleAged but Alive should not be a separate path.
    expect(machine.value.activeNodes.length, 1);
  });

  test('should transition in compound state.', () async {
    final machine = await _createMachine<Dead>(watcher, human);

    machine.send(const OnJudged(Judgement.good));

    /// should be in both states.
    expect(machine.isInState(InHeaven), isTrue);
    expect(machine.isInState(Dead), isTrue);
  });

  test('calls onExit/onEntry', () async {
    final machine = await _createMachine<Alive>(watcher, human);

    /// age until they are middle aged.
    final onBirthday = OnBirthday();
    for (var i = 0; i < 18; i++) {
      machine.send(onBirthday);
    }

    machine.send(onBirthday);

    verify(() => watcher.onExit(Young, onBirthday)).called(19);
    verify(() => watcher.onEntry(MiddleAged, onBirthday)).called(1);
    expect(machine.isInState(Alive), isTrue);
    expect(machine.isInState(Young), isFalse);
    expect(machine.isInState(MiddleAged), isTrue);
  });

  test('should call onExit/onEntry for compound state change', () async {
    final machine = await _createMachine<Alive>(watcher, human);

    final onDeath = OnDeath();
    machine.send(onDeath);

    verify(() => watcher.onExit(Alive, onDeath)).called(1);
    verify(() => watcher.onExit(Young, onDeath)).called(1);
    verify(() => watcher.onEntry(Dead, onDeath)).called(1);
    verify(() => watcher.onEntry(Purgatory, onDeath)).called(1);

    expect(machine.isInState(Dead), isTrue);
    expect(machine.isInState(Purgatory), isTrue);
  });
}

// https://xstate.js.org/viz/?gist=6db962fed919174cba71cde5731452e1
Future<StateMachine> _createMachine<S extends AutomataState>(
  Watcher watcher,
  Human human,
) async {
  final machine = StateMachine.create(
    (g) => g
      ..initial<S>()
      ..state<Alive>(
        builder: (b) => b
          ..initial<Young>()
          ..onEntry((e) => watcher.onEntry(Alive, e))
          ..onExit((e) => watcher.onExit(Alive, e))

          // Transitions
          ..on<OnBirthday, Young>(
            condition: (e) => human.age < 18,
            actions: [
              (e) async {
                human.age++;
                // print('Young $human');
              },
            ],
          )
          ..on<OnBirthday, MiddleAged>(
            condition: (e) => human.age < 50,
            actions: [
              (e) async {
                human.age++;
                // print('MiddleAged $human');
              },
            ],
          )
          ..on<OnBirthday, Old>(
            condition: (e) => human.age < 80,
            actions: [
              (e) async {
                human.age++;
                // print('Old $human');
              },
            ],
          )
          ..on<OnDeath, Purgatory>()

          // States
          ..state<Young>(
            builder: (b) => b..onExit((e) => watcher.onExit(Young, e)),
          )
          ..state<MiddleAged>(
            builder: (b) => b..onEntry((e) => watcher.onEntry(MiddleAged, e)),
          )
          ..state<Old>(),
      )
      ..state<Dead>(
        builder: (b) => b
          ..initial<Purgatory>()
          ..onEntry((e) => watcher.onEntry(Dead, e))
          ..state<Purgatory>(
            builder: (b) => b
              ..onEntry((e) => watcher.onEntry(Purgatory, e))
              ..on<OnJudged, Good>(
                condition: (e) => e.judgement == Judgement.good,
              )
              ..on<OnJudged, Bad>(
                condition: (e) => e.judgement == Judgement.bad,
              )
              ..on<OnJudged, Ugly>(
                condition: (e) => e.judgement == Judgement.ugly,
              )
              ..on<OnJudged, Matrix>(
                condition: (e) => e.judgement == Judgement.morallyAmbiguous,
              )
              ..state<Matrix>(),
          )
          ..state<InHeaven>(
            builder: (b) => b..state<Good>(),
          )
          ..state<InHell>(
            builder: (b) => b
              ..state<Grouped>(
                builder: (b) => b
                  ..state<Ugly>()
                  ..state<Bad>(),
              ),
          ),
      ),
  );
  return machine;
}

class Human {
  int age = 0;

  @override
  String toString() => 'Human $age';
}

class Alive implements AutomataState {}

class Dead implements AutomataState {}

class Young extends Alive {}

class MiddleAged implements AutomataState {}

class Old implements AutomataState {}

class Purgatory implements AutomataState {}

class Matrix implements AutomataState {}

class InHeaven implements AutomataState {}

class InHell implements AutomataState {}

class Grouped implements AutomataState {}

class Good implements AutomataState {}

class Bad implements AutomataState {}

class Ugly implements AutomataState {}

/// events

class OnBirthday implements AutomataEvent {}

class OnDeath implements AutomataEvent {}

enum Judgement { good, bad, ugly, morallyAmbiguous }

class OnJudged implements AutomataEvent {
  final Judgement judgement;

  const OnJudged(this.judgement);
}
