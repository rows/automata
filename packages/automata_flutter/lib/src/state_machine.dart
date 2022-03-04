import 'package:automata/automata.dart';
import 'package:flutter/material.dart';

class StateMachineNotifier extends ChangeNotifier {
  late final StateMachine machine;

  StateMachineNotifier(
    void Function(StateNode) builder, {
    OnTransitionCallback? onTransition,
    AutomataContextState? context,
  }) {
    machine = StateMachine.create(
      builder,
      onTransition: ((e, value) {
        onTransition?.call(e, value);
        notifyListeners();
      }),
      context: context,
    );
  }

  factory StateMachineNotifier.create(
    void Function(StateNode) builder, {
    OnTransitionCallback? onTransition,
    AutomataContextState? context,
  }) {
    return StateMachineNotifier(
      builder,
      onTransition: onTransition,
      context: context,
    );
  }

  /// Send an event to the state machine.
  ///
  /// The currently active [StateNodeDefinition] will pick up this event and
  /// execute any [TransitionDefinition] that matches it's [GuardCondition].
  ///
  /// For every executed transitions, the provided [OnTransitionCallback] is
  /// called.
  ///
  /// In order to support "eventless transitions" a NullEvent is sent when a
  /// transition is performed.
  void send<E extends AutomataEvent>(E event) => machine.send<E>(event);

  /// Check if the state machine is currently in a given [AutomataState].
  bool isInState<S>() => machine.isInState<S>();

  /// Check if the state machine has any value that matches the given path.
  bool matchesStatePath(List<Type> path) => machine.matchesStatePath(path);

  @override
  String toString() {
    return machine.toString();
  }
}
