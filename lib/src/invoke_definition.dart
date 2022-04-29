import 'state_machine_value.dart';
import 'state_node.dart';
import 'transition_definition.dart';
import 'types.dart';

/// Defines a [InvokeDefinition] attached to a [StateNodeDefinition].
///
/// Used to invoke external async services and transition on success / failure
/// to the defined onDone and onError [TransitionDefinition]s.
class InvokeDefinition<S extends AutomataState, E extends AutomataEvent,
    Result> {
  /// Identifier of this definition.
  ///
  /// See also:
  /// - [InvokeDefinition.id]
  late final String _id;

  /// Source node to which this invoke is attached to.
  final StateNodeDefinition sourceStateNode;

  /// Success transition.
  ///
  /// See also:
  /// - [InvokeDefinition.onDone]
  late final TransitionDefinition _onDoneTransition;

  /// Failure transition.
  ///
  /// See also:
  /// - [InvokeDefinition.onError]
  late final TransitionDefinition _onErrorTransition;

  /// Invoke's async callback.
  ///
  /// See also:
  /// - [InvokeDefinition.src]
  late final InvokeSrcCallback<Result> _callback;

  InvokeDefinition({required this.sourceStateNode});

  /// Set the [InvokeDefinition]'s identifier.
  ///
  /// This identifier will be returned within the result of the invocation.
  void id(String value) {
    _id = value;
  }

  /// Set the [InvokeDefinition]'s src async callback.
  ///
  /// When the containing [StateNode] is entered, the given callback will be
  /// invoked. Depending on how the [Future] resolves, it will call the
  /// configured [onDone] or [onError] callbacks.
  void src(InvokeSrcCallback<Result> callback) {
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
  void execute(StateMachineValue value, AutomataEvent e) async {
    try {
      final result = await _callback(e);

      _onDoneTransition.trigger(
        value,
        DoneInvokeEvent<Result>(id: _id, data: result),
      );
    } on Object catch (e) {
      _onErrorTransition.trigger(
        value,
        PlatformErrorEvent(exception: e),
      );
    }
  }
}
