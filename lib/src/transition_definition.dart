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
  final StateNodeDefinition<State> sourceStateNode;

  /// Optional condition that can be define to allow/deny the transition.
  final GuardCondition<E>? condition;

  /// List of side effect functions to be called on successful transition.
  final List<Action<E>>? actions;

  TransitionDefinition({
    required this.sourceStateNode,
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
    StateNodeDefinition source,
    StateNodeDefinition target,
  ) {
    final nodes = <StateNodeDefinition>{};

    nodes.addAll(
      value
          .activeLeafStates()
          .where((element) => element.path.contains(source)),
    );

    nodes.addAll(
      source.path.where((element) => !target.path.contains(element)),
    );

    for (final node in value.activeLeafStates()) {
      if (node.path.contains(target)) {
        nodes.add(node);
      }
    }

    nodes.add(source);

    return nodes;
  }

  /// Given the current [StateMachineValue] and the [StateNodeDefinition] nodes
  /// that we want to transition between, output all the nodes that we should be
  /// entering into in this transition.
  Set<StateNodeDefinition> _getEntryNodes(
    StateMachineValue value,
    StateNodeDefinition source,
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

    final items = target.path.where(
      (element) => !source.path.contains(element),
    );
    for (final node in items) {
      // TODO: im not yet sure about this yet.
      //  check parallel_statemachine_test for the test wich calls OnTickFirst.
      if (target.parentNode?.stateNodeType == StateNodeType.parallel) {
        nodes.addAll(node.initialStateNodes);
      }
    }

    nodes.add(target);
    nodes.addAll(target.initialStateNodes);

    return nodes;
  }

  /// Trigger this transition for the given event.
  StateMachineValue trigger(StateMachineValue value, E e) {
    final sourceLeaf = sourceStateNode;

    // First look for the target leaf within the compound root and only
    // afterwards fallback to search from root.
    StateNodeDefinition? targetLeaf;
    if (sourceLeaf.parentNode?.stateNodeType == StateNodeType.compound) {
      targetLeaf = _findLeaf(targetState, sourceLeaf.parentNode!);
    }

    targetLeaf ??= _findLeaf(targetState, sourceLeaf.rootNode);

    if (targetLeaf == null) {
      throw Exception('destination leaf node not found');
    }

    final exitNodes = _getExitNodes(value, sourceLeaf, targetLeaf);
    final entryNodes = _getEntryNodes(value, sourceLeaf, targetLeaf);

    // trigger all on exits
    for (final node in exitNodes) {
      final isEntrying = entryNodes.any(
        (entryNode) => entryNode == node || entryNode.path.contains(node),
      );

      if (!isEntrying) {
        node.callExitAction(e);
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
        node.callEntryAction(e);
      }
    }

    // update state of mind
    for (final node in exitNodes) {
      value.remove(node);
    }

    for (final node in entryNodes) {
      value.add(node);
    }

    // Call onDone for all parent node in which children have reached a
    // terminal (final) state
    for (final node in entryNodes) {
      final parentNode = node.parentNode;
      if (node.stateNodeType != StateNodeType.terminal || parentNode == null) {
        continue;
      }

      // If the final node is within a compound or the root node, call onAction
      // on the parent.
      if (parentNode.stateNodeType == StateNodeType.compound ||
          parentNode == node.rootNode) {
        parentNode.callDoneActions(e);
      }

      if (parentNode.stateNodeType != StateNodeType.compound) {
        continue;
      }

      // If the final node is within a parallel state machine, if all sub-states
      // are final, then call onDone on the parallel machine.
      final parallelParentMachine = parentNode.parentNode;
      if (parallelParentMachine?.stateNodeType == StateNodeType.parallel) {
        var allParallelNodesInFinalState = true;
        for (final activeNode in value.activeLeafStates()) {
          if (activeNode.path.contains(parallelParentMachine) &&
              activeNode.stateNodeType != StateNodeType.terminal) {
            allParallelNodesInFinalState = false;
            break;
          }
        }

        if (allParallelNodesInFinalState) {
          parallelParentMachine?.callDoneActions(e);
        }
      }
    }

    return value;
  }
}
