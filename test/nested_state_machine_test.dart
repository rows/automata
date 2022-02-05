import 'package:flutter_test/flutter_test.dart';
import 'package:state_machine/state_machine.dart';

class Watcher {
  void onEnter(Type? t, Event? e) {
    print('enter');
  }

  void onExit(Type? t, Event? e) {
    print('exit ');
  }

  void log(String? message) {
    print('log');
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

  // test('traverse tree', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   final states = <StateDefinition, StateDefinition>{};
  //   final transitions = <TransitionDefinition>[];
  //   await machine.traverseTree((sd, tds) {
  //     transitions.addAll(tds);
  //     states[sd] = sd;
  //   }, includeInherited: false);
  //   expect(states.length, equals(14));
  //   expect(transitions.length, equals(8));
  //   expect(machine.isInState<Alive>(), equals(true));
  // });

  // test('Test no op transition', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   machine.send(OnBirthday());

  //   expect(machine.isInState<Alive>(), equals(true));
  //   expect(machine.isInState<Young>(), equals(true));
  //   verifyInOrder([watcher.log('OnBirthday')]);
  // });

  // test('Test simple transition', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   for (var i = 0; i < 19; i++) {
  //     machine.send(OnBirthday());
  //   }

  //   expect(machine.isInState<Alive>(), equals(true));
  //   expect(machine.isInState<MiddleAged>(), equals(true));
  //   verifyInOrder([watcher.log('OnBirthday')]);
  // });

  // test('Test multiple transitions', () async {
  //   final machine = await _createMachine<Alive>(human);
  //   machine.send(OnBirthday());

  //   expect(machine.isInState<Young>(), equals(true));
  //   machine.send(OnDeath());

  //   expect(machine.isInState<Dead>(), equals(true));

  //   verifyInOrder([watcher.log('OnBirthday')]);
  // });

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
  //         ..state<Alive>((b) => b..state<Dead>((b) {})),
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

Future<StateMachine> _createMachine<S extends State>(
  Watcher watcher,
  Human human,
) async {
  final machine = StateMachine.create(
    (g) => g
      ..initialState<S>()
      ..state<Alive>((b) => b
        ..initialState<Young>()
        ..onEnter((s, e) async => watcher.onEnter(s, e))
        ..onExit((s, e) async => watcher.onExit(s, e))
        ..on<OnBirthday, Young>(
          condition: (e) => human.age < 18,
          actions: [(e) async => human.age++],
        )
        ..on<OnBirthday, MiddleAged>(
          condition: (e) => human.age < 50,
          actions: [(e) async => human.age++],
        )
        ..on<OnBirthday, Old>(
          condition: (e) => human.age < 80,
          actions: [(e) async => human.age++],
        )
        ..on<OnDeath, Purgatory>()
        ..state<Young>((b) => b..onExit((s, e) async => watcher.onExit(s, e)))
        ..state<MiddleAged>(
          (b) => b..onEnter((s, e) async => watcher.onEnter(s, e)),
        )
        ..state<Old>((b) => b))
      ..state<Dead>(
        (b) => b
          ..onEnter((s, e) async => watcher.onEnter(s, e))

          /// ..initialState<InHeaven>()
          ..state<Purgatory>((b) => b
            ..onEnter((s, e) async => watcher.onEnter(s, e))
            ..on<OnJudged, Buddhist>(
                condition: (e) => e.judgement == Judgement.good)
            ..on<OnJudged, Catholic>(
                condition: (e) => e.judgement == Judgement.bad)
            ..on<OnJudged, SalvationArmy>(
                condition: (e) => e.judgement == Judgement.ugly)
            ..on<OnJudged, Matrix>(
                condition: (e) => e.judgement == Judgement.morallyAmbiguous)
            ..state<Matrix>((_) {}))
          ..state<InHeaven>((b) => b..state<Buddhist>((b) => b))
          ..state<InHell>(
            (b) => b
              ..state<Christian>(
                (b) => b
                  ..state<SalvationArmy>((b) {})
                  ..state<Catholic>((b) => b),
              ),
          ),
      ),
  );
  return machine;
}

class Human {
  int age = 0;
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

class Christian implements State {}

class Buddhist implements State {}

class Catholic implements State {}

class SalvationArmy implements State {}

/// events

class OnBirthday implements Event {}

class OnDeath implements Event {}

enum Judgement { good, bad, ugly, morallyAmbiguous }

class OnJudged implements Event {
  Judgement judgement;

  OnJudged(this.judgement);
}
