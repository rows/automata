import '../automata.dart';

/// [Exception] thrown when a [StateMachine] is defined without any
/// atomic state node.
class NoAtomicStateNodeException implements Exception {
  @override
  String toString() => 'No atomic nodes in this state machine';
}

/// [Exception] thrown when a node already has a transition for a given
/// event without condition.
class UnreachableTransitionException implements Exception {
  final Type event;

  const UnreachableTransitionException(this.event);

  @override
  String toString() => 'The transition with Event $event is not reachable.';
}

/// [Exception] thrown when a node already has a child node for the given
/// [State].
class DuplicateStateException implements Exception {
  final Type state;

  const DuplicateStateException(this.state);

  @override
  String toString() => 'The state $state is already in use. '
      "Every State must be unique among its sibilings.";
}

/// [Exception] thrown when onDone is placed in a state that doesnt have any
/// terminal child.
class InvalidOnDoneCallbackException implements Exception {
  final Type state;
  final StateNodeType stateNodeType;

  const InvalidOnDoneCallbackException({
    required this.state,
    required this.stateNodeType,
  });

  @override
  String toString() {
    switch (stateNodeType) {
      case StateNodeType.compound:
        return 'The onDone callback in the node with state $state'
            ' is invalid due to not having any child with terminal type.';
      case StateNodeType.parallel:
        return 'The onDone callback in the node with state $state'
            ' is invalid due to some of its children not having a'
            ' terminal sub state.';
      case StateNodeType.atomic:
        return 'The onDone callback in the node with state $state'
            ' is invalid due to this not being a atomic node.';
      default:
        return '';
    }
  }
}

/// [Exception] thrown when a node already has a child node for the given
/// [State].
class UnreachableInitialStateException implements Exception {
  final Type currentState;
  final Type initialState;

  const UnreachableInitialStateException({
    required this.currentState,
    required this.initialState,
  });

  @override
  String toString() =>
      'Initial state "$initialState" not found on "$currentState"';
}
