import 'package:automata/src/state_node.dart';

/// Structure that olds the currently active [StateNodeDefinition] in a
/// [StateMachine].
///
/// Since we can have a parallel statemachines we can have multiple active nodes
/// at once.
class StateMachineValue {
  late final Set<StateNodeDefinition> _activeNodes;

  StateMachineValue(StateNodeDefinition node) : _activeNodes = {node};

  /// Check if the given [State] is in the path of any of the currrently
  /// active [StateNodeDefinition].
  bool isInState<S>() {
    for (final node in _activeNodes) {
      if (node.stateType == S) {
        return true;
      }

      if (node.fullPathStateType.contains(S)) {
        return true;
      }
    }
    return false;
  }

  bool matchesStatePath(List<Type> path) {
    final pathSet = path.toSet();
    for (final node in _activeNodes) {
      if (node.fullPathStateType.containsAll(pathSet)) {
        return true;
      }
    }

    return false;
  }

  /// Returns all the currently active [StateNodeDefinition].
  List<StateNodeDefinition> activeLeafStates() {
    return _activeNodes.toList();
  }

  /// Add a new active [StateNodeDefinition].
  ///
  /// On the process of adding a new active node, we also remove any now
  /// redudant node, ie.
  ///  - given an existing node of: `RootNode > A`
  ///  - when adding: `RootNode > A > B`
  /// It is safe to remove `RootNode > A`
  ///
  void add(StateNodeDefinition node) {
    final duppedNodes = node.path.where(
      (path) => _activeNodes.any((element) => element == path),
    );
    for (final duppedNode in duppedNodes) {
      remove(duppedNode);
    }

    _activeNodes.add(node);
  }

  /// Remove a active [StateNodeDefinition].
  ///
  /// When remove a node, we should also remove any other nodes which this
  /// node is part of the path, ie.
  ///  - given a state of `RootNode > A > B` and `RootNode > A > C`
  ///  - when trying to remove: `RootNode > A`
  /// We need to remove both `RootNode > A > B` and `RootNode > A > C`
  ///
  void remove(StateNodeDefinition node) {
    final toRemove = [node];
    for (final _activeNode in _activeNodes) {
      if (_activeNode.path.contains(node)) {
        toRemove.add(_activeNode);
      }
    }

    for (final toRemoveNode in toRemove) {
      _activeNodes.remove(toRemoveNode);
    }
  }

  @override
  String toString() {
    return _activeNodes.join('\n');
  }
}
