import 'package:state_machine/src/state_value.dart';
import 'package:state_machine/src/transition_definition.dart';
import 'package:state_machine/src/types.dart';

import 'state_node.dart';

typedef OnTransitionCallback = void Function(Type from, Event e, Type to);

class StateMachine {
  late StateMachineValue value;

  /// Root node of the [StateMachine].
  late StateNodeDefinition<RootState> rootNode;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(this.rootNode, {this.onTransition}) {
    value = StateMachineValue(rootNode);

    final enterNodes = rootNode.getIntialEnterNodes();
    for (final node in enterNodes) {
      node.callEnter(InitialEvent());
      value.add(node);
    }
  }

  /// Creates a [StateMachine] using a builder pattern.
  factory StateMachine.create(
    void Function(StateNode) buildGraph, {
    OnTransitionCallback? onTransition,
  }) {
    final rootNode = StateNodeDefinition<RootState>();
    buildGraph(rootNode);

    return StateMachine._(rootNode, onTransition: onTransition);
  }

  void send<E extends Event>(E event) {
    final nodes = value.activeLeafStates();
    final transitions = <OnTransitionDefinition>[];
    for (final node in nodes) {
      transitions.addAll(node.transition(event, onTransition: onTransition));
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

  bool isInState<S>() {
    return value.isInState<S>();
  }

  @override
  String toString() {
    return rootNode.toString();
  }
}
