import 'package:automata/src/state_machine_value.dart';
import 'package:automata/src/state_node.dart';
import 'package:automata/src/transition_definition.dart';

import 'types.dart';

/// Defines a [InvokeDefinition] attached to a [StateNodeDefinition].
///
/// Used to invoke external async services and transition on success / failure
/// to the defined onDone and onError [TransitionDefinition]s.
class InvokeDefinition<S extends AutomataState, E extends AutomataEvent,
    Result> {
  /// Identifier of this definition.
  late final String _id;

  /// Source node to which this invoke is attached to.
  final StateNodeDefinition<S> sourceStateNode;

  /// Success transition.
  late final TransitionDefinition _onDoneTransition;

  /// Failure transition.
  late final TransitionDefinition _onErrorTransition;

  /// Invoke async callback.
  late final InvokeSrcCallback _callback;

  InvokeDefinition({required this.sourceStateNode});

  /// Set the [InvokeDefinition]'s identifier.
  void id(String value) {
    _id = value;
  }

  /// Set the [InvokeDefinition]'s src async callback.
  void src(InvokeSrcCallback callback) {
    _callback = callback;
  }

  /// Create the [InvokeDefinition]'s onDone [TransitionDefinition].
  void onDone<Target extends AutomataState, _Result>({
    List<Action<DoneInvokeEvent<_Result>>>? actions,
  }) {
    _onDoneTransition =
        TransitionDefinition<S, DoneInvokeEvent<_Result>, Target>(
      sourceStateNode: sourceStateNode,
      targetState: Target,
      actions: actions,
    );
  }

  /// Create the [InvokeDefinition]'s onError [TransitionDefinition].
  void onError<Target extends AutomataState>({
    List<Action<ErrorEvent>>? actions,
  }) {
    _onErrorTransition = TransitionDefinition<S, ErrorEvent, Target>(
      sourceStateNode: sourceStateNode,
      targetState: Target,
      actions: actions,
    );
  }

  /// Execute the async callback and trigger the onDone or onError
  /// [TransitionDefinition].
  void execute(
    AutomataContextState? context,
    StateMachineValue value,
    AutomataEvent e,
  ) async {
    try {
      final result = await _callback(e);

      _onDoneTransition.trigger(
        context,
        value,
        DoneInvokeEvent<Result>(id: _id, data: result),
      );
    } on Object catch (e) {
      _onErrorTransition.trigger(
        context,
        value,
        PlatformErrorEvent(exception: e),
      );
    }
  }
}
