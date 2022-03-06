import 'dart:async';

import 'state_machine_value.dart';
import 'state_node.dart';
import 'transition_definition.dart';
import 'types.dart';

/// Finite State Machine.
///
/// Exposes a concise API to create and transition in a state machine and also
/// to query it's current values.
///
class StateMachine {
  /// Machine identifier.
  String? id;

  /// Hold all the currently active [StateNodeDefinition].
  late StateMachineValue value;

  /// Root node of the [StateMachine].
  late StateNodeDefinition<RootState> rootNode;

  /// Returns [Stream] of [StateMachineValue].
  final StreamController<StateMachineValue> _controller =
      StreamController.broadcast();

  Stream<StateMachineValue> get stream => _controller.stream;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(this.rootNode, {this.id, this.onTransition}) {
    value = StateMachineValue(rootNode);

    // Get root's initial nodes and call entry on them with [InitialEvent]
    final entryNodes = rootNode.initialStateNodes;
    for (final node in entryNodes) {
      node.callEntryAction(InitialEvent());
      value.add(node);
    }

    // In order to support "eventless transitions" a NullEvent is sent after
    // the initial event is set.
    send(const NullEvent());
  }

  /// Dipose [StreamController].
  void dispose() {
    _controller.close();
  }

  /// Creates a [StateMachine] using a builder pattern.
  factory StateMachine.create(
    void Function(StateNode) builder, {
    String? id,
    OnTransitionCallback? onTransition,
  }) {
    final rootNode = StateNodeDefinition<RootState>();
    builder(rootNode);

    return StateMachine._(rootNode, id: id, onTransition: onTransition);
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
  void send<E extends Event>(E event) {
    final nodes = value.activeNodes;

    final transitions = <TransitionDefinition>{};
    for (final node in nodes) {
      transitions.addAll(node.getTransitions(event));
    }

    if (transitions.isEmpty) {
      return;
    }

    for (final transition in transitions) {
      value = transition.trigger(value, event);
      onTransition?.call(event, value);

      _controller.add(value);
    }

    if (E != NullEvent) {
      send(const NullEvent());
    }
  }

  /// Check if the state machine is currently in a given [State].
  bool isInState<S>() {
    return value.isInState<S>();
  }

  bool matchesStatePath(List<Type> path) {
    return value.matchesStatePath(path);
  }

  @override
  String toString() {
    return rootNode.toString();
  }
}
