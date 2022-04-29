import '../../automata.dart';
import '../state_node.dart';
import 'validators.dart';

/// Extension on [StateMachine] to perform validations.
///
/// See also:
/// - [ValidateAtomicStates]
extension StateMachineValidator on StateMachine {
  /// Kick start validation by invoking validate on the rootNode, which will
  /// then traverse the statechart invoking validate on all nodes.
  void validate() {
    final _validators = [
      ValidateAtomicStates(this),
    ];

    for (final validator in _validators) {
      validator();
    }

    return rootNode.validate();
  }
}

/// Extension on [StateNodeDefinition] to perform validations.
///
/// See also:
/// - [ValidateUnreachableTransitions]
/// - [ValidateInvalidOnDoneCallback]
extension StateNodeDefinitionValidator on StateNodeDefinition {
  void validate() {
    final _validators = [
      ValidateUnreachableTransitions(this),
      ValidateInvalidOnDoneCallback(this),
    ];

    for (final validator in _validators) {
      validator();
    }

    for (final node in childNodes.values) {
      node.validate();
    }
  }
}
