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

  Set<StateNodeDefinition> _getExitNodes(
    StateMachineValue value,
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final nodes = <StateNodeDefinition>{};

    nodes.addAll(
      value.activeLeafStates().where((element) => element.path.contains(from)),
    );

    nodes.addAll(
      from.path.where((element) => !to.path.contains(element)),
    );

    for (final node in value.activeLeafStates()) {
      if (node.path.contains(to)) {
        nodes.add(node);
      }
    }

    nodes.add(from);

    return nodes;
  }

  Set<StateNodeDefinition> _getEnterNodes(
    StateMachineValue value,
    StateNodeDefinition from,
    StateNodeDefinition to,
  ) {
    final nodes = <StateNodeDefinition>{};

    // Get all nodes in the to path that are not yet part of the value.
    final activeNodes = value.activeLeafStates();
    nodes.addAll(
      to.path.where(
        (element) => !activeNodes.any((activeNode) =>
            element == activeNode || activeNode.path.contains(element)),
      ),
    );

    final items = to.path.where((element) => !from.path.contains(element));
    for (final node in items) {
      // TODO: im not yet sure about this yet.
      //  check parallel_statemachine_test for the test wich calls OnTickFirst.
      if (to.parentNode?.stateNodeType == StateNodeType.parallel) {
        nodes.addAll(node.getIntialEnterNodes());
      }
    }

    nodes.add(to);
    nodes.addAll(to.getIntialEnterNodes());

    return nodes;
  }

  StateMachineValue trigger(StateMachineValue value, E e) {
    final fromLeaf = fromStateNode;
    final toLeaf = findLeaf(targetState, fromLeaf.rootNode);

    if (toLeaf == null) {
      throw Exception('destination leaf node not found');
    }

    final exitNodes = _getExitNodes(value, fromLeaf, toLeaf);
    final enterNodes = _getEnterNodes(value, fromLeaf, toLeaf);

    // trigger all on exits
    for (final node in exitNodes) {
      final isEntering = enterNodes.any(
        (enterNode) => enterNode == node || enterNode.path.contains(node),
      );

      if (!isEntering) {
        node.callExit(e);
      }
    }

    // trigger all actions
    if (actions != null && actions!.isNotEmpty) {
      for (final action in actions!) {
        action(e);
      }
    }

    // trigger all on enters based on common ancestor
    for (final node in enterNodes) {
      if (!value.activeLeafStates().contains(node)) {
        node.callEnter(e);
      }
    }

    // update state of mind
    for (final node in exitNodes.toSet()) {
      value.remove(node);
    }

    for (final node in enterNodes.toSet()) {
      value.add(node);
    }

    return value;
  }
}
