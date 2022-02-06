import 'package:state_machine/src/types.dart';

import 'state_node.dart';

typedef OnTransitionCallback = void Function(Type from, Event e, Type to);

typedef TraverseCallback = void Function(StateNodeDefinition node);

class StateMachine {
  /// Root node of the [StateMachine].
  late StateNodeDefinition<RootState> rootNode;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(this.rootNode, {this.onTransition}) {
    rootNode.send(InitialEvent());
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

  /// Traverse the nodes in depth first search.
  void traverse({
    StateNodeDefinition? node,
    required TraverseCallback callback,
    bool onlyActiveNodes = false,
  }) {
    final currentNode = node ?? rootNode;
    callback(currentNode);

    final children = (onlyActiveNodes
            ? currentNode.activeStateNodes
            : currentNode.childNodes) ??
        [];

    for (final child in children) {
      traverse(
        node: child,
        callback: callback,
        onlyActiveNodes: onlyActiveNodes,
      );
    }
  }

  void send<E extends Event>(E event) {
    rootNode.send(event, onTransition: onTransition);
  }

  bool isInState<S>() {
    var found = false;
    traverse(
      onlyActiveNodes: true,
      callback: (node) {
        if (!found) {
          found = node.stateType == S;
        }
      },
    );

    return found;
  }
}
