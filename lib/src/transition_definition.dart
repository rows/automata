import 'state_machine_value.dart';
import 'state_node.dart';
import 'types.dart';

enum TransitionType { internal, external }

/// Given a two [StateNodeDefinition] calculate the Least Common Coupound
/// Ancestor (LCCA), ie the compound [StateNodeDefinition] that contains both
/// nodes.
///
/// See also:
/// - [SCXML: LCCA](https://www.w3.org/TR/scxml/#LCCA)
StateNodeDefinition getLeastCommonCompoundAncestor(
  StateNodeDefinition node1,
  StateNodeDefinition node2,
) {
  if (node1 == node2) {
    return node1;
  }

  late final List<StateNodeDefinition> fromPath;
  late final StateNodeDefinition targetNode;
  if (node1.path.length > node2.path.length) {
    fromPath = [...node1.path, node1];
    targetNode = node2;
  } else {
    fromPath = [...node2.path, node2];
    targetNode = node1;
  }

  for (var index = 0; index != fromPath.length; index += 1) {
    final node = fromPath[index];

    if (node.parentNode?.stateNodeType != StateNodeType.compound) {
      continue;
    }

    if (index >= targetNode.path.length || node != targetNode.path[index]) {
      return fromPath[index - 1];
    }
  }
  return fromPath.first;
}

/// Defines a transition to be attached to a [StateNodeDefinition].
///
/// For a given [AutomataEvent] the [StateMachine] should transition from [S] to
/// [TargetState].
///
/// A [TransitionDefinition] can produce side-effects via [actions] and be
/// subjected to a [condition] before being approved to change the state
/// machine's state
///
/// See also:
/// - [SCXML: Transition](https://www.w3.org/TR/scxml/#transition)
/// - [SCXML: Selecting Transitions](https://www.w3.org/TR/scxml/#SelectingTransitions)
class TransitionDefinition<S extends AutomataState, E extends AutomataEvent,
    TargetState extends AutomataState> {
  /// Defines the [TransitionType].
  final TransitionType type;

  /// If this [TransitionDefinition] is trigger [targetState] will be the new
  /// [AutomataState]
  Type targetState;

  /// The state this transition is attached to.
  final StateNodeDefinition<AutomataState> sourceStateNode;

  /// Optional condition that can be define to allow/deny the transition.
  final GuardCondition<E>? condition;

  /// List of side effect functions to be called on successful transition.
  final List<Action<E>>? actions;

  /// Exposes the [Event] that triggers this transition.
  Type get event => E;

  // First look for the target leaf within the compound root and only
  // afterwards fallback to search from root.
  late final StateNodeDefinition targetStateNode = (() {
    StateNodeDefinition? targetLeaf;
    if (sourceStateNode.parentNode?.stateNodeType == StateNodeType.compound) {
      targetLeaf = _findLeaf(targetState, sourceStateNode.parentNode!);
    }

    targetLeaf ??= _findLeaf(targetState, sourceStateNode.rootNode);

    if (targetLeaf == null) {
      throw Exception('destination leaf node not found');
    }

    return targetLeaf;
  })();

  TransitionDefinition({
    required this.sourceStateNode,
    required this.targetState,
    TransitionType? type,
    this.condition,
    this.actions,
  }) : type = type ?? TransitionType.external;

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
    final lcca = getLeastCommonCompoundAncestor(source, target);

    for (final node in value.activeNodes) {
      nodes.addAll(
        node.path.where((element) => element.path.contains(lcca)),
      );

      if (node.path.contains(lcca)) {
        nodes.add(node);
      }
    }

    if (type == TransitionType.internal) {
      nodes.remove(source);
    }

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

    final lcca = getLeastCommonCompoundAncestor(source, target);

    nodes.addAll(
      target.path.where(
        (element) {
          // Do not include source if its a internal transition
          if (type == TransitionType.internal && element == source) {
            return false;
          }

          return !lcca.path.contains(element);
        },
      ),
    );

    nodes.add(target);
    nodes.addAll(target.initialStateNodes);

    return nodes;
  }

  /// Trigger this transition for the given event.
  StateMachineValue trigger(StateMachineValue value, E e) {
    var sourceLeaf = sourceStateNode;
    final targetLeaf = targetStateNode;

    // If transitioning within a parallel state machine, adjust the source node
    // to be within the parallel machine
    if (sourceLeaf.stateNodeType == StateNodeType.parallel &&
        targetLeaf.path.contains(sourceLeaf)) {
      sourceLeaf = [...targetLeaf.path, targetLeaf].firstWhere((node) {
        return !sourceStateNode.path.contains(node) && sourceStateNode != node;
      });
    }

    final exitNodes = _getExitNodes(value, sourceLeaf, targetLeaf);
    final entryNodes = _getEntryNodes(value, sourceLeaf, targetLeaf);

    // trigger all on exits
    for (final node in exitNodes) {
      node.callExitAction(e);
    }

    // trigger all actions
    if (actions != null && actions!.isNotEmpty) {
      for (final action in actions!) {
        action(e);
      }
    }

    // update state of mind
    exitNodes.forEach(value.remove);
    entryNodes.forEach(value.add);

    // trigger all on entrys based on common ancestor
    for (final node in entryNodes) {
      node.callEntryAction(value, e);
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
        for (final activeNode in value.activeNodes) {
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
