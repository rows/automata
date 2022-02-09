import 'package:automata/src/state_machine_value.dart';
import 'package:automata/src/transition_definition.dart';
import 'package:automata/src/types.dart';

import 'state_node.dart';

/// Finite State Machine.
///
/// Exposes a concise API to create and transition in a state machine and also
/// to query it's current values.
///
class StateMachine {
  /// Hold all the currently active [StateNodeDefinition].
  late StateMachineValue value;

  /// Root node of the [StateMachine].
  late StateNodeDefinition<RootState> rootNode;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(this.rootNode, {this.onTransition}) {
    value = StateMachineValue(rootNode);

    // Get root's initial nodes and call entry on them with [InitialEvent]
    final entryNodes = rootNode.getIntialStates();
    for (final node in entryNodes) {
      node.callEntry(InitialEvent());
      value.add(node);
    }
  }

  /// Creates a [StateMachine] using a builder pattern.
  factory StateMachine.create(
    void Function(StateNode) builder, {
    OnTransitionCallback? onTransition,
  }) {
    final rootNode = StateNodeDefinition<RootState>();
    builder(rootNode);

    return StateMachine._(rootNode, onTransition: onTransition);
  }

  /// Send an event to the state machine.
  ///
  /// The currently active [StateNodeDefinition] will pick up this event and
  /// execute any [TransitionDefinition] that matches it's [GuardCondition].
  ///
  /// For every executed transitions, the provided [OnTransitionCallback] is
  /// called.
  void send<E extends Event>(E event) {
    final nodes = value.activeLeafStates();
    final isInTerminalNode = nodes.any(
      (element) => element.stateNodeType == StateNodeType.terminal,
    );

    if (isInTerminalNode) {
      return;
    }

    final transitions = <TransitionDefinition>[];
    for (final node in nodes) {
      transitions.addAll(node.getTransitions(event));
    }

    for (final transition in transitions) {
      value = transition.trigger(value, event);
      onTransition?.call(
        transition.fromStateNode.stateType,
        event,
        transition.targetState,
      );
    }
  }

  /// Check if the state machine is currently in a given [State].
  bool isInState<S>() {
    return value.isInState<S>();
  }

  @override
  String toString() {
    return rootNode.toString();
  }
}
