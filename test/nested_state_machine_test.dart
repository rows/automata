import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late Watcher watcher;
  late Human human;

  setUp(() {
    watcher = Watcher();
    human = Human();
  });

  test('initial State should be Alive and Young', () async {
    final machine = await _createMachine<Alive>(watcher, human);

    expect(machine.isInState<Alive>(), equals(true));
    expect(machine.isInState<Young>(), equals(true));
  });

  test(
    'should keep machine in same state if the matched transition is for '
    'the current state',
    () async {
      final machine = await _createMachine<Alive>(watcher, human);
      machine.send(OnBirthday());

      expect(machine.isInState<Alive>(), equals(true));
      expect(machine.isInState<Young>(), equals(true));
      // verifyInOrder([watcher.log('OnBirthday')]);
    },
  );

  test('should move to next state when condition is met', () async {
    // final machine = await _createMachine<Alive>(watcher, human);
    // for (var i = 0; i < 19; i++) {
    //   machine.send(OnBirthday());
    // }

    human.age = 18;
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnBirthday());

    expect(machine.isInState<Alive>(), equals(true));
    expect(machine.isInState<MiddleAged>(), equals(true));
    // verifyInOrder([watcher.log('OnBirthday')]);
  });

  test('Test multiple transitions', () async {
    final machine = await _createMachine<Alive>(watcher, human);
    machine.send(OnBirthday());

    expect(machine.isInState<Young>(), equals(true));
    machine.send(OnDeath());

    expect(machine.isInState<Dead>(), equals(true));
    expect(machine.isInState<Purgatory>(), equals(true));

    // verifyInOrder([watcher.log('OnBirthday')]);
  });

  // test('Invalid transition', () async {
  //   final watcher = MockWatcher();
  //   final machine = await _createMachine<Dead>(human);
  //   try {
  //     machine.send(OnBirthday());

  //     fail('InvalidTransitionException not thrown');
  //   } catch (e) {
  //     expect(e, isA<InvalidTransitionException>());
  //   }
  // });

  // test('Transition to child state', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   machine.send(OnDeath());

  //   expect(machine.isInState<Purgatory>(), equals(true));
  //   machine.send(OnJudged(Judgement.morallyAmbiguous));

  //   expect(machine.isInState<Matrix>(), equals(true));
  //   expect(machine.isInState<Dead>(), equals(true));
  //   expect(machine.isInState<Purgatory>(), equals(true));

  //   /// We should be MiddleAged but Alive should not be a separate path.
  //   expect(machine.stateOfMind.activeLeafStates().length, 1);
  // });

  // test('Unreachable State.', () async {
  //   final machine = StateMachine.create(
  //       (g) => g
  //         ..initialState<Alive>()
  //         ..state<Alive>(builder: (b) => b..state<Dead>(builder: (b) {})),
  //       production: true);

  //   expect(machine.analyse(), equals(false));
  // });

  // test('Transition in nested state.', () async {
  //   final watcher = MockWatcher();
  //   final machine = await _createMachine<Dead>(human);

  //   machine.send(OnJudged(Judgement.good));

  //   /// should be in both states.
  //   expect(machine.isInState<InHeaven>(), equals(true));
  //   expect(machine.isInState<Dead>(), equals(true));
  // });

  // test('calls onExit/onEnter', () async {
  //   final watcher = MockWatcher();
  //   final machine = await _createMachine<Alive>(human);

  //   /// age this boy until they are middle aged.
  //   final onBirthday = OnBirthday();
  //   for (var i = 0; i < 19; i++) {
  //     machine.send(onBirthday);
  //   }

  //   verify(await watcher.onExit(Young, onBirthday));
  //   verify(await watcher.onEnter(MiddleAged, onBirthday));
  // });

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
            ..onEnter((e) async => watcher.onEnter(e))
            ..onExit((e) async => watcher.onExit(e))

            // Transitions
            ..on<OnBirthday, Young>(
              condition: (e) => human.age < 18,
              actions: [
                (e) async {
                  human.age++;
                  // print(human);
                },
              ],
            )
            ..on<OnBirthday, MiddleAged>(
              condition: (e) => human.age < 50,
              actions: [
                (e) async {
                  human.age++;
                  // print(human);
                },
              ],
            )
            ..on<OnBirthday, Old>(
              condition: (e) => human.age < 80,
              actions: [(e) async => human.age++],
            )
            ..on<OnDeath, Purgatory>()

            // States
            ..state<Young>(
              builder: (b) => b..onExit((e) async => watcher.onExit(e)),
            )
            ..state<MiddleAged>(
              builder: (b) => b..onEnter((e) async => watcher.onEnter(e)),
            )
            ..state<Old>())
      ..state<Dead>(
        builder: (b) => b
          ..onEnter((e) async => watcher.onEnter(e))

          /// ..initialState<InHeaven>()
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
              ..on<OnJudged, Purgatory>(
                condition: (e) => e.judgement == Judgement.morallyAmbiguous,
              ),
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
  Judgement judgement;

  OnJudged(this.judgement);
}
