import 'package:state_machine/src/state_node.dart';

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

  /// Add a new active [StateNodeDefinition].
  ///
  /// On the process of adding a new active node, we also remove any now
  /// redudant node, ie.
  ///  * given an existing node of: `RootNode > A`
  ///  * when adding: `RootNode > A > B`
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
  ///  * given a state of `RootNode > A > B` and `RootNode > A > C`
  ///  * when trying to remove: `RootNode > A`
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
}