import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:test/test.dart';

class Solid extends State {}

class Liquid extends State {}

class Gas extends State {}

class OnMelted extends Event {}

class OnVaporized extends Event {}

class OnFroze extends Event {}

class OnCondensed extends Event {}

void main() {
  test('should have the proper initial state', () {
    final machine = _createMachine();
    expect(machine.isInState<Solid>(), isTrue);
    expect(machine.isInState<Liquid>(), isFalse);
  });

  test('should be able to transition to a given state', () {
    final machine = _createMachine();
    machine.send(OnMelted());

    expect(machine.isInState<Liquid>(), isTrue);
  });

  test('should call onEntry and onExit while transitioning', () {
    var calls = <String>[];

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
    expect(machine.isInState<Liquid>(), isTrue);
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

    expect(machine.isInState<Solid>(), isTrue);
    expect(machine.isInState<Liquid>(), isFalse);

    machine.send(OnMelted());
    expect(machine.isInState<Solid>(), isTrue);
    expect(machine.isInState<Liquid>(), isFalse);

    enabled = true;

    machine.send(OnMelted());
    expect(machine.isInState<Solid>(), isFalse);
    expect(machine.isInState<Liquid>(), isTrue);
  });

  test('should invoke onTransition on all transitions', () {
    final transitions = [];
    final machine = StateMachine.create(
      (g) => g
        ..initial<Solid>()
        ..state<Solid>(
          builder: (b) => b..on<OnMelted, Liquid>(),
        )
        ..state<Liquid>(),
      onTransition: (source, event, to) => transitions.add([source, event, to]),
    );

    final event = OnMelted();
    machine.send(event);

    expect(transitions.first, equals([Solid, event, Liquid]));
  });

  test('should call actions on transition', () {
    final effects = [];
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

StateMachine _createMachine<S extends State>() {
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
