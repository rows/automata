import '../../automata.dart';
import '../exceptions.dart';
import '../state_node.dart';

/// Abstract class to be extended by any [StateMachine] or [StateNode]
/// validator classes.
abstract class Validator<T> {
  final T data;
  const Validator(this.data);

  void call();
}

/// Throws [NoAtomicStateNodeException] if no [StateNodeType.atomic] or
/// [StateNodeType.terminal] is defined.
class ValidateAtomicStates extends Validator<StateMachine> {
  const ValidateAtomicStates(StateMachine data) : super(data);

  bool _isAtomic(StateNodeDefinition node) {
    return node.stateNodeType == StateNodeType.atomic ||
        node.stateNodeType == StateNodeType.terminal;
  }

  bool _hasAnyAtomicNode(StateNodeDefinition node) {
    final isAtomic = _isAtomic(node);
    if (isAtomic) {
      return true;
    }

    for (final child in node.childNodes.values) {
      return _hasAnyAtomicNode(child);
    }

    return false;
  }

  @override
  void call() {
    final hasAnyAtomicNode = _hasAnyAtomicNode(data.rootNode);
    if (!hasAnyAtomicNode) {
      throw NoAtomicStateNodeException();
    }
  }
}

/// Throws [UnreachableTransitionException] when a node defines
/// two transitions without conditions to the same [Event]. Only the first
/// one will ever be matched and therefore its the only valid.
class ValidateUnreachableTransitions extends Validator<StateNodeDefinition> {
  const ValidateUnreachableTransitions(StateNodeDefinition data) : super(data);

  @override
  void call() {
    final events = <Type>{};
    data.eventTransitionsMap.forEach((event, transitions) {
      for (final transition in transitions) {
        if (transition.condition != null) {
          continue;
        }

        if (events.contains(event)) {
          throw UnreachableTransitionException(event);
        }

        events.add(event);
      }
    });
  }
}

/// Throws a [InvalidOnDoneCallbackException] if the current node has a
/// onDone callback but that callback doesn't meet the criteria to ever
/// get called.
///
/// A [StateNodeType.atomic] can never be a [StateNodeType.terminal].
///
/// A [StateNodeType.compound] should have at least one
/// [StateNodeType.terminal] child node.
///
/// All chidren in a [StateNodeType.parallel] node should have at least one
/// [StateNodeType.terminal] child node.
class ValidateInvalidOnDoneCallback extends Validator<StateNodeDefinition> {
  const ValidateInvalidOnDoneCallback(StateNodeDefinition data) : super(data);

  bool _hasTerminalSubState(StateNodeDefinition node) {
    return node.childNodes.values.any(
      (element) => element.stateNodeType == StateNodeType.terminal,
    );
  }

  @override
  void call() {
    if (data.onDoneCallback == null) {
      return;
    }

    if (data.stateNodeType == StateNodeType.atomic) {
      throw InvalidOnDoneCallbackException(
        state: data.stateType,
        stateNodeType: StateNodeType.atomic,
      );
    }

    if (data.stateNodeType == StateNodeType.compound) {
      if (!_hasTerminalSubState(data)) {
        throw InvalidOnDoneCallbackException(
          state: data.stateType,
          stateNodeType: StateNodeType.compound,
        );
      }
    }

    if (data.stateNodeType == StateNodeType.parallel) {
      final allChildrenHaveATerminalSubState = data.childNodes.values.every(
        _hasTerminalSubState,
      );

      if (!allChildrenHaveATerminalSubState) {
        throw InvalidOnDoneCallbackException(
          state: data.stateType,
          stateNodeType: StateNodeType.parallel,
        );
      }
    }
  }
}
