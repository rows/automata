import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:state_machine/state_machine.dart';

class Watcher {
  void onEnter(Event? e) {
    // print('enter');
  }

  void onExit(Event? e) {
    // print('exit ');
  }

  void log(String? message) {
    // print('log');
  }
}

class _MockWatcher extends Mock implements Watcher {}

void main() {
  late Watcher watcher;
  late Human human;

  setUp(() {
    watcher = Watcher();
    human = Human();
  });

  test('should set initial state to Alive and Young', () async {
    final machine = await _createMachine<Alive>(watcher, human);

    expect(machine.isInState<Alive>(), isTrue);
    expect(machine.isInState<Young>(), isTrue);
  });

  test(
    'should keep machine in same state if the matched transition is for '
    'the current state',
    () async {
      final machine = await _createMachine<Alive>(watcher, human);
      machine.send(OnBirthday());

      expect(machine.isInState<Alive>(), isTrue);
      expect(machine.isInState<Young>(), isTrue);
      // verifyInOrder([watcher.log('OnBirthday')]);
    },
  );

  test('should move to next state when condition is met', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    for (var i = 0; i < 18; i++) {
      machine.send(OnBirthday());
    }

    // Move the last send outside of the loop to ease debug.
    machine.send(OnBirthday());

    expect(machine.isInState<Alive>(), isTrue);
    expect(machine.isInState<Young>(), isFalse);
    expect(machine.isInState<MiddleAged>(), isTrue);
    // verifyInOrder([watcher.log('OnBirthday')]);
  });

  test('Test multiple transitions', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnBirthday());

    expect(machine.isInState<Young>(), isTrue);
    machine.send(OnDeath());

    expect(machine.isInState<Dead>(), isTrue);
    expect(machine.isInState<Purgatory>(), isTrue);

    // verifyInOrder([watcher.log('OnBirthday')]);
  });

  test('should transition to child state', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnDeath());

    expect(machine.isInState<Dead>(), isTrue);
    expect(machine.isInState<Purgatory>(), isTrue);
    expect(machine.isInState<Alive>(), isFalse);
    machine.send(const OnJudged(Judgement.morallyAmbiguous));

    expect(machine.isInState<Matrix>(), isTrue);
    expect(machine.isInState<Dead>(), isTrue);
    expect(machine.isInState<Purgatory>(), isTrue);

    /// We should be MiddleAged but Alive should not be a separate path.
    // expect(machine.stateOfMind.activeLeafStates().length, 1);
  });

  // test('Unreachable State.', () async {
  //   final machine = StateMachine.create(
  //       (g) => g
  //         ..initialState<Alive>()
  //         ..state<Alive>(builder: (b) => b..state<Dead>(builder: (b) {})),
  //       production: true);

  //   expect(machine.analyse(), isFalse);
  // });

  test('should transition in nested state.', () async {
    final machine = await _createMachine<Dead>(watcher, human);

    machine.send(const OnJudged(Judgement.good));

    /// should be in both states.
    expect(machine.isInState<InHeaven>(), isTrue);
    expect(machine.isInState<Dead>(), isTrue);
  });

  test('calls onExit/onEnter', () async {
    final watcher = _MockWatcher();
    final machine = await _createMachine<Alive>(watcher, human);

    /// age until they are middle aged.
    final onBirthday = OnBirthday();
    for (var i = 0; i < 18; i++) {
      machine.send(onBirthday);
    }

    machine.send(onBirthday);

    verify(() => watcher.onExit(onBirthday)).called(1);
    verify(() => watcher.onEnter(onBirthday)).called(1);
    expect(machine.isInState<Alive>(), isTrue);
    expect(machine.isInState<Young>(), isFalse);
    expect(machine.isInState<MiddleAged>(), isTrue);
  });

  // test('Test onExit/onEnter for nested state change', () async {
  //   final watcher = MockWatcher();
  //   final machine = await _createMachine<Alive>(human);

  //   /// age this boy until they are middle aged.
  //   final onDeath = OnDeath();
  //   machine.send(onDeath);

  //   verify(await watcher.onExit(Young, onDeath));
  //   verify(await watcher.onExit(Alive, onDeath));
  //   verify(await watcher.onEnter(Dead, onDeath));
  //   verify(await watcher.onEnter(Purgatory, onDeath));
  // });

  // test('Export', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   machine.analyse();
  //   machine.export('test/smcat/nested_test.smcat');

  //   final lines = read('test/smcat/nested_test.smcat')
  //       .toList()
  //       .reduce((value, line) => value += '\n$line');

  //   expect(lines, equals(_graph));
  // });
}

// https://xstate.js.org/viz/?gist=6db962fed919174cba71cde5731452e1
Future<StateMachine> _createMachine<S extends State>(
  Watcher watcher,
  Human human,
) async {
  final machine = StateMachine.create(
    (g) => g
      ..initial<S>()
      ..state<Alive>(
          builder: (b) => b
            ..initial<Young>()
            ..onEnter((e) async {
              // print('entering alive...');
              watcher.onEnter(e);
            })
            ..onExit((e) async => watcher.onExit(e))

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
              builder: (b) => b..onExit((e) async => watcher.onExit(e)),
            )
            ..state<MiddleAged>(
              builder: (b) => b
                ..onEnter((e) async {
                  // print('entering MiddleAged...');
                  watcher.onEnter(e);
                }),
            )
            ..state<Old>())
      ..state<Dead>(
        builder: (b) => b
          ..initial<Purgatory>()
          ..onEnter((e) async {
            // print('entering Dead...');
            watcher.onEnter(e);
          })
          ..state<Purgatory>(
            builder: (b) => b
              ..onEnter((e) async => watcher.onEnter(e))
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

class Alive implements State {}

class Dead implements State {}

class Young extends Alive {}

class MiddleAged implements State {}

class Old implements State {}

class Purgatory implements State {}

class Matrix implements State {}

class InHeaven implements State {}

class InHell implements State {}

class Grouped implements State {}

class Good implements State {}

class Bad implements State {}

class Ugly implements State {}

/// events

class OnBirthday implements Event {}

class OnDeath implements Event {}

enum Judgement { good, bad, ugly, morallyAmbiguous }

class OnJudged implements Event {
  final Judgement judgement;

  const OnJudged(this.judgement);
}
