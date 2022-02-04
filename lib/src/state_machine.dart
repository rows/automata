import 'package:state_machine/src/types.dart';

import 'state_node.dart';

typedef BuildGraph = void Function(StateNode);

abstract class RootStateNode extends State {}

class InitialEvent extends Event {}

typedef OnTransitionFunction = void Function(Type from, Event e, Type to);

class StateMachine {
  late StateNodeDefinition currentStateNode;
  OnTransitionFunction? onTransition;

  StateMachine._(
    StateNodeDefinition rootNode, {
    this.onTransition,
  }) {
    rootNode.start();
    currentStateNode = rootNode.currentStateNode!;
    currentStateNode.enter(rootNode, InitialEvent());
  }

  /// Creates a statemachine using a builder pattern.
  factory StateMachine.create(
    BuildGraph buildGraph, {
    OnTransitionFunction? onTransition,
  }) {
    final rootNode = StateNodeDefinition<RootStateNode>();
    buildGraph(rootNode);

    final machine = StateMachine._(
      rootNode,
      onTransition: onTransition,
    );
    return machine;
  }

  void send<E extends Event>(E event) {
    final result = currentStateNode.send(event);
    if (result == null) {
      return;
    }

    final toState = result.stateNode;
    final fromState = currentStateNode;
    final transition = result.transition as dynamic;
    final transitionActions = transition.actions as List<dynamic>? ?? [];

    currentStateNode.exit(toState, event);
    currentStateNode = toState;

    for (final action in transitionActions) {
      action(event);
    }

    currentStateNode.enter(fromState, event);

    onTransition?.call(fromState.currentState, event, toState.currentState);
  }

  bool isInState<S>() {
    return currentStateNode.currentState == S;
  }
}
