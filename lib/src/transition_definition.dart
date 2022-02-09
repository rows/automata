import 'package:state_machine/src/state_node.dart';
import 'package:state_machine/src/state_value.dart';

import '../state_machine.dart';

class OnTransitionDefinition<S extends State, E extends Event,
    TOSTATE extends State> {
  /// If this [OnTransitionDefinition] is trigger [targetState] will be the new [State]
  Type targetState;

  /// The state this transition is attached to.
  final StateNodeDefinition<State> fromStateNode;

  final GuardCondition<E>? condition;
  final List<Action<E>>? actions;

  OnTransitionDefinition({
    required this.fromStateNode,
    required this.targetState,
    this.condition,
    this.actions,
  });

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

  List<StateNodeDefinition> _getEnterNodes(
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final nodes = to.path.where(
      (element) => !from.path.contains(element),
    );

    return [...nodes, to, ...to.getIntialEnterNodes()];
  }

  StateMachineValue trigger(StateMachineValue value, E e) {
    final fromLeaf = fromStateNode;
    final toLeaf = findLeaf(targetState, fromLeaf.rootNode);

    if (toLeaf == null) {
      throw Exception('destination leaf node not found');
    }

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
