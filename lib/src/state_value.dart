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

  /// Add a new active [StateNodeDefinition] and remove any previous active node
  /// that might be already covered in the new active node's path.
  void add(StateNodeDefinition node) {
    final duppedNodes = node.path.where(
      (path) => _activeNodes.any((element) => element == path),
    );
    for (final duppedNode in duppedNodes) {
      remove(duppedNode);
    }

    _activeNodes.add(node);
  }

  void remove(StateNodeDefinition node) {
    _activeNodes.remove(node);
  }
}
