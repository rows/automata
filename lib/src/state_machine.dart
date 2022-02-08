import 'package:state_machine/src/transition_definition.dart';
import 'package:state_machine/src/types.dart';

import 'state_node.dart';

typedef OnTransitionCallback = void Function(Type from, Event e, Type to);

class StateMachineValue {
  final Set<StateNodeDefinition> _activeNodes = {};

  StateMachineValue(StateNodeDefinition node) {
    add(node);
  }

  bool isInState<S>() {
    for (final node in _activeNodes) {
      if (node.stateType == S) {
        return true;
      }

      if (node.path.any((node) => node.stateType == S)) {
        return true;
      }
    }
    return false;
  }

  /// returns a StateDefinition for all active states
  List<StateNodeDefinition> activeLeafStates() {
    return _activeNodes.toList();
  }

  void add(StateNodeDefinition node) {
    _activeNodes.add(node);
  }

  void remove(StateNodeDefinition node) {
    _activeNodes.remove(node);
  }
}

class StateMachine {
  late StateMachineValue value;

  /// Root node of the [StateMachine].
  late StateNodeDefinition<RootState> rootNode;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(this.rootNode, {this.onTransition}) {
    value = StateMachineValue(rootNode.initialStateNode!);
    rootNode.initialStateNode!.callEnter(InitialEvent());
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

  StateNodeDefinition? findLeaf(Type state, [StateNodeDefinition? node]) {
    final currentNode = node ?? rootNode;
    for (final key in currentNode.childNodes.keys) {
      final childNode = currentNode.childNodes[key];
      if (key == state) {
        return childNode;
      }

      findLeaf(state, childNode);
    }

    return null;
  }

  /// Walks up the tree looking for an ancestor that is common
  /// to the [fromAncestors] and [toAncestors] paths.
  ///
  /// If no common ancestor is found then null is returned;
  StateNodeDefinition findCommonAncestor(
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final toAncestorSet = to.path.toSet();

    for (final ancestor in from.path.reversed) {
      if (toAncestorSet.contains(ancestor)) {
        return ancestor;
      }
    }

    return rootNode;
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
        transition.toState,
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
