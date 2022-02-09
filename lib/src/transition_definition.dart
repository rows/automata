import 'package:automata/src/state_machine_value.dart';
import 'package:automata/src/state_node.dart';

import 'types.dart';

/// Defines a transition to be attached to a [StateNodeDefinition].
///
/// For a given [Event] the [StateMachine] should transition from [S] to
/// [TargetState].
///
/// A [TransitionDefinition] can produce side-effects via [actions] and be
/// subjected to a [condition] before being approved to change the state
/// machine's state
///
class TransitionDefinition<S extends State, E extends Event,
    TargetState extends State> {
  /// If this [TransitionDefinition] is trigger [targetState] will be the new [State]
  Type targetState;

  /// The state this transition is attached to.
  final StateNodeDefinition<State> fromStateNode;

  /// Optional condition that can be define to allow/deny the transition.
  final GuardCondition<E>? condition;

  /// List of side effect functions to be called on successful transition.
  final List<Action<E>>? actions;

  TransitionDefinition({
    required this.fromStateNode,
    required this.targetState,
    this.condition,
    this.actions,
  });

  /// Given a [Type] and a [StateNodeDefinition] recursively find the node
  /// that contains that [Type].
  StateNodeDefinition? _findLeaf(Type state, StateNodeDefinition node) {
    final currentNode = node;
    for (final key in currentNode.childNodes.keys) {
      final childNode = currentNode.childNodes[key];
      if (key == state) {
        return childNode;
      }

      if (childNode != null) {
        final res = _findLeaf(state, childNode);
        if (res != null) {
          return res;
        }
      }
    }

    return null;
  }

  /// Given the current [StateMachineValue] and the [StateNodeDefinition] nodes
  /// that we want to transition between, output all the nodes that we should be
  /// exiting from in this transition.
  Set<StateNodeDefinition> _getExitNodes(
    StateMachineValue value,
    StateNodeDefinition from,
    StateNodeDefinition target,
  ) {
    final nodes = <StateNodeDefinition>{};

    nodes.addAll(
      value.activeLeafStates().where((element) => element.path.contains(from)),
    );

    nodes.addAll(
      from.path.where((element) => !target.path.contains(element)),
    );

    for (final node in value.activeLeafStates()) {
      if (node.path.contains(target)) {
        nodes.add(node);
      }
    }

    nodes.add(from);

    return nodes;
  }

  /// Given the current [StateMachineValue] and the [StateNodeDefinition] nodes
  /// that we want to transition between, output all the nodes that we should be
  /// entering into in this transition.
  Set<StateNodeDefinition> _getEntryNodes(
    StateMachineValue value,
    StateNodeDefinition from,
    StateNodeDefinition target,
  ) {
    final nodes = <StateNodeDefinition>{};

    // Get all nodes in the to path that are not yet part of the value.
    final activeNodes = value.activeLeafStates();
    nodes.addAll(
      target.path.where(
        (element) => !activeNodes.any((activeNode) =>
            element == activeNode || activeNode.path.contains(element)),
      ),
    );

    final items = target.path.where((element) => !from.path.contains(element));
    for (final node in items) {
      // TODO: im not yet sure about this yet.
      //  check parallel_statemachine_test for the test wich calls OnTickFirst.
      if (target.parentNode?.stateNodeType == StateNodeType.parallel) {
        nodes.addAll(node.getIntialStates());
      }
    }

    nodes.add(target);
    nodes.addAll(target.getIntialStates());

    return nodes;
  }

  /// Trigger this transition for the given event.
  StateMachineValue trigger(StateMachineValue value, E e) {
    final fromLeaf = fromStateNode;
    final targetLeaf = _findLeaf(targetState, fromLeaf.rootNode);

    if (targetLeaf == null) {
      throw Exception('destination leaf node not found');
    }

    final exitNodes = _getExitNodes(value, fromLeaf, targetLeaf);
    final entryNodes = _getEntryNodes(value, fromLeaf, targetLeaf);

    // trigger all on exits
    for (final node in exitNodes) {
      final isEntrying = entryNodes.any(
        (entryNode) => entryNode == node || entryNode.path.contains(node),
      );

      if (!isEntrying) {
        node.callExit(e);
      }
    }

    // trigger all actions
    if (actions != null && actions!.isNotEmpty) {
      for (final action in actions!) {
        action(e);
      }
    }

    // trigger all on entrys based on common ancestor
    for (final node in entryNodes) {
      if (!value.activeLeafStates().contains(node)) {
        node.callEntry(e);
      }
    }

    // update state of mind
    for (final node in exitNodes.toSet()) {
      value.remove(node);
    }

    for (final node in entryNodes.toSet()) {
      value.add(node);
    }

    return value;
  }
}
