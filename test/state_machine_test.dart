import 'package:flutter_test/flutter_test.dart';
import 'package:state_machine/src/state_machine.dart';
import 'package:state_machine/src/types.dart';

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
  });

  test('should be able to transition to a given state', () {
    final machine = _createMachine();
    machine.send(OnMelted());

    expect(machine.isInState<Liquid>(), isTrue);
  });

  test('should call onEnter and onExit while transitioning', () {
    var calls = <String>[];

    final machine = StateMachine.create(
      (g) => g
        ..initialState<Solid>()
        ..state<Solid>(
          (b) => b
            ..on<OnMelted, Liquid>()
            ..onEnter((fromState, event) {
              calls.add('onEnterSolid');
            })
            ..onExit((fromState, event) {
              calls.add('onExitSolid');
            }),
        )
        ..state<Liquid>(
          (b) => b
            ..on<OnFroze, Solid>()
            ..on<OnVaporized, Gas>()
            ..onEnter((fromState, event) {
              calls.add('onEnterLiquid');
            })
            ..onExit((fromState, event) {
              calls.add('onExitLiquid');
            }),
        )
        ..state<Gas>(
          (b) => b..on<OnCondensed, Liquid>(),
        ),
    );

    expect(calls, equals(['onEnterSolid']));
    machine.send(OnMelted());

    expect(calls, equals(['onEnterSolid', 'onExitSolid', 'onEnterLiquid']));
    expect(machine.isInState<Liquid>(), isTrue);
  });

  test('should only transition if the guard clause allows to', () {
    var enabled = false;
    final machine = StateMachine.create(
      (g) => g
        ..initialState<Solid>()
        ..state<Solid>(
          (b) => b
            ..on<OnMelted, Liquid>(
              condition: (event) => enabled,
            ),
        )
        ..state<Liquid>((b) => b),
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
        ..initialState<Solid>()
        ..state<Solid>(
          (b) => b..on<OnMelted, Liquid>(),
        )
        ..state<Liquid>((b) => b),
      onTransition: ((from, event, to) => transitions.add([from, event, to])),
    );

    final event = OnMelted();
    machine.send(event);

    expect(transitions.first, equals([Solid, event, Liquid]));
  });

  test('should call side effects', () {
    final effects = [];
    final machine = StateMachine.create(
      (g) => g
        ..initialState<Solid>()
        ..state<Solid>(
          (b) => b
            ..on<OnMelted, Liquid>(
              actions: [
                (e) => effects.add('sideeffect_1'),
                (e) => effects.add('sideeffect_2'),
              ],
            ),
        )
        ..state<Liquid>((b) => b),
    );

    machine.send(OnMelted());

    expect(effects, equals(['sideeffect_1', 'sideeffect_2']));
  });
}

StateMachine _createMachine<S extends State>() {
  return StateMachine.create(
    (g) => g
      ..initialState<Solid>()
      ..state<Solid>(
        (b) => b..on<OnMelted, Liquid>(),
      )
      ..state<Liquid>(
        (b) => b
          ..on<OnFroze, Solid>()
          ..on<OnVaporized, Gas>(),
      )
      ..state<Gas>(
        (b) => b..on<OnCondensed, Liquid>(),
      ),
  );
}
