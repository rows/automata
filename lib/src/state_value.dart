import 'package:state_machine/src/state_node.dart';

class StateValue {
  final StateNodeDefinition stateNode;
  final List<StateNodeDefinition> nodes;

  StateValue({
    required this.stateNode,
    List<StateNodeDefinition>? nodes,
  }) : nodes = nodes ?? [];
}
