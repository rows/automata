import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:test/test.dart';

class Solid extends AutomataState {}

class Liquid extends AutomataState {}

class Gas extends AutomataState {}

class OnMelted extends AutomataEvent {}

class OnVaporized extends AutomataEvent {}

class OnFroze extends AutomataEvent {}

class OnCondensed extends AutomataEvent {}

void main() {
  test('should have the proper initial state', () {
    final machine = _createMachine();
    expect(machine.isInState(Solid), isTrue);
    expect(machine.isInState(Liquid), isFalse);
  });

  test('should be able to transition to a given state', () {
    final machine = _createMachine();
    machine.send(OnMelted());

    expect(machine.isInState(Liquid), isTrue);
  });

  test('should call onEntry and onExit while transitioning', () {
    final calls = <String>[];

    final machine = StateMachine.create(
      (g) => g
        ..initial<Solid>()
        ..state<Solid>(
          builder: (b) => b
            ..on<OnMelted, Liquid>()
            ..onEntry((event) => calls.add('onEntrySolid'))
            ..onExit((event) {
              calls.add('onExitSolid');
            }),
        )
        ..state<Liquid>(
          builder: (b) => b
            ..on<OnFroze, Solid>()
            ..on<OnVaporized, Gas>()
            ..onEntry((event) => calls.add('onEntryLiquid'))
            ..onExit((event) => calls.add('onExitLiquid')),
        )
        ..state<Gas>(
          builder: (b) => b..on<OnCondensed, Liquid>(),
        ),
    );

    expect(calls, equals(['onEntrySolid']));
    machine.send(OnMelted());

    expect(calls, equals(['onEntrySolid', 'onExitSolid', 'onEntryLiquid']));
    expect(machine.isInState(Liquid), isTrue);
  });

  test('should only transition if the guard clause allows to', () {
    var enabled = false;
    final machine = StateMachine.create(
      (g) => g
        ..initial<Solid>()
        ..state<Solid>(
          builder: (b) => b
            ..on<OnMelted, Liquid>(
              condition: (event) => enabled,
            ),
        )
        ..state<Liquid>(),
    );

    expect(machine.isInState(Solid), isTrue);
    expect(machine.isInState(Liquid), isFalse);

    machine.send(OnMelted());
    expect(machine.isInState(Solid), isTrue);
    expect(machine.isInState(Liquid), isFalse);

    enabled = true;

    machine.send(OnMelted());
    expect(machine.isInState(Solid), isFalse);
    expect(machine.isInState(Liquid), isTrue);
  });

  test('should invoke onTransition on all transitions', () {
    final transitions = <AutomataEvent>[];
    final machine = StateMachine.create(
      (g) => g
        ..initial<Solid>()
        ..state<Solid>(
          builder: (b) => b..on<OnMelted, Liquid>(),
        )
        ..state<Liquid>(),
      onTransition: (event, state) => transitions.add(event),
    );

    final event = OnMelted();
    machine.send(event);

    expect(transitions, equals([event]));
  });

  test('should call actions on transition', () {
    final effects = <dynamic>[];
    final machine = StateMachine.create(
      (g) => g
        ..initial<Solid>()
        ..state<Solid>(
          builder: (b) => b
            ..on<OnMelted, Liquid>(
              actions: [
                (e) => effects.add('sideeffect_1'),
                (e) => effects.add('sideeffect_2'),
              ],
            ),
        )
        ..state<Liquid>(),
    );

    machine.send(OnMelted());

    expect(effects, equals(['sideeffect_1', 'sideeffect_2']));
  });
}

StateMachine _createMachine<S extends AutomataState>() {
  return StateMachine.create(
    (g) => g
      ..initial<Solid>()
      ..state<Solid>(
        builder: (b) => b..on<OnMelted, Liquid>(),
      )
      ..state<Liquid>(
        builder: (b) => b
          ..on<OnFroze, Solid>()
          ..on<OnVaporized, Gas>(),
      )
      ..state<Gas>(
        builder: (b) => b..on<OnCondensed, Liquid>(),
      ),
  );
}
