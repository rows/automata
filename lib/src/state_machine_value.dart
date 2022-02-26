import 'state_node.dart';

/// Structure that olds the currently active [StateNodeDefinition] in a
/// [StateMachine].
///
/// Since we can have a parallel statemachines we can have multiple active nodes
/// at once.
class StateMachineValue {
  late final Set<StateNodeDefinition> _activeNodes;

  StateMachineValue(StateNodeDefinition node) : _activeNodes = {node};

  /// Returns all the currently active [StateNodeDefinition].
  Iterable<StateNodeDefinition> get activeNodes => _activeNodes;

  /// Check if the given [State] is in the path of any of the currently
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

  /// Add a new active [StateNodeDefinition].
  ///
  /// On the process of adding a new active node, we also remove any now
  /// redundant node, ie.
  ///  - given an existing node of: `RootNode > A`
  ///  - when adding: `RootNode > A > B`
  /// It is safe to remove `RootNode > A`
  ///
  void add(StateNodeDefinition node) {
    final duppedNodes = node.path.where(
      (path) => _activeNodes.any((element) => element == path),
    );
    duppedNodes.forEach(remove);

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

    toRemove.forEach(_activeNodes.remove);
  }

  @override
  String toString() {
    return _activeNodes.join('\n');
  }
}
