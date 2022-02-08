import 'package:state_machine/src/state_node.dart';

import '../state_machine.dart';

class TransitionDefinition<E extends Event> {
  /// The state this transition is attached to.
  final StateNodeDefinition<State> fromStateNode;

  final GuardCondition<E>? condition;
  final List<Action<E>>? actions;

  TransitionDefinition({
    required this.fromStateNode,
    required this.condition,
    required this.actions,
  });
}

class OnTransitionDefinition<S extends State, E extends Event,
    TOSTATE extends State> extends TransitionDefinition<E> {
  /// If this [OnTransitionDefinition] is trigger [toState] will be the new [State]
  Type toState;

  OnTransitionDefinition({
    required StateNodeDefinition fromState,
    GuardCondition<E>? condition,
    required this.toState,
    List<Action<E>>? actions,
  }) : super(
          fromStateNode: fromState,
          condition: condition,
          actions: actions,
        );

  StateNodeDefinition? findLeaf(Type state, StateNodeDefinition node) {
    final currentNode = node;
    for (final key in currentNode.childNodes.keys) {
      final childNode = currentNode.childNodes[key];
      if (key == state) {
        return childNode;
      }

      if (childNode != null) {
        final res = findLeaf(state, childNode);
        if (res != null) {
          return res;
        }
      }
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
    final fromPath = [from, ...from.path.reversed];

    for (final ancestor in fromPath) {
      if (toAncestorSet.contains(ancestor)) {
        return ancestor;
      }
    }

    throw Exception('from and to nodes do not share a common rootnode');
  }

  List<StateNodeDefinition> _getExitNodes(
    StateMachineValue value,
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final nodes = from.path
        .where(
          (element) => !to.path.contains(element),
        )
        .toList();

    for (final node in value.activeLeafStates()) {
      if (node.path.contains(to)) {
        nodes.add(node);
      }
    }

    return [...nodes, from];
  }

  List<StateNodeDefinition> _getIntialEnterNodes(StateNodeDefinition node) {
    var result = <StateNodeDefinition>[];

    if (node.stateNodeType == StateNodeType.parallel) {
      for (final childNode in node.childNodes.values) {
        result.add(childNode);
        result.addAll(_getIntialEnterNodes(childNode));
      }
    } else if (node.initialStateNode != null) {
      result.add(node.initialStateNode!);
    }

    return result;
  }

  List<StateNodeDefinition> _getEnterNodes(
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final nodes = to.path.where(
      (element) => !from.path.contains(element),
    );

    return [...nodes, to, ..._getIntialEnterNodes(to)];
  }

  StateMachineValue trigger(StateMachineValue value, E e) {
    final fromLeaf = fromStateNode;
    final toLeaf = findLeaf(toState, fromLeaf.rootNode);

    if (toLeaf == null) {
      throw Exception('destination leaf node not found');
    }

    // find common ancestor between these nodes
    final ancestor = findCommonAncestor(fromLeaf, toLeaf);

    // trigger all on exits based on common ancestor
    final exitNodes = _getExitNodes(value, fromLeaf, toLeaf);
    for (final node in exitNodes) {
      node.callExit(e);
    }

    // trigger all actions
    if (actions != null && actions!.isNotEmpty) {
      for (final action in actions!) {
        action(e);
      }
    }

    // trigger all on enters based on common ancestor
    final enterNodes = _getEnterNodes(fromLeaf, toLeaf);
    for (final node in enterNodes) {
      node.callEnter(e);
    }

    // TODO: update state of mind
    for (final node in exitNodes.toSet()) {
      value.remove(node);
    }

    for (final node in enterNodes.toSet()) {
      value.add(node);
    }

    return value;
  }
}
