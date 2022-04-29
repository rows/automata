import 'package:meta/meta.dart';

import 'invoke_definition.dart';
import 'state_machine_value.dart';
import 'transition_definition.dart';

/// Base class for all States that you pass to the state machine.
///
/// All your [AutomataState] classes MUST extend this [AutomataState] class.
///
/// ```dart
/// class Playing extends State {}
///
///  final machine = StateMachine.create((g) => g
///       ..state<Playing>(builder: (b) => b
///
///       ...
/// )
/// ```
@immutable
abstract class AutomataState {
  const AutomataState();
}

/// Base class for all Events that you pass to the state machine.
///
/// All your [AutomataEvent] class MUST extends the [AutomataEvent] class
///
/// ```dart
/// class OnAwardPoints extends Event {
///   final int points;
///
///   OnAwardPoints({required this.points});
/// }
///
/// machine.send(OnAwardPoints(points: 50));
///
/// ...
///
/// ..on<OnAwardPoints, Playing>(
///   actions: [(OnAwardPoints e) => scoreboard.point += e.points],
/// )
/// ```
@immutable
abstract class AutomataEvent {
  const AutomataEvent();
}

/// Pseudo [AutomataState] used as root of our state machine.
abstract class RootState extends AutomataState {}

/// Pseudo [AutomataEvent] used to trigger eventless transitions.
@immutable
class NullEvent extends AutomataEvent {
  const NullEvent();
}

/// [AutomataEvent] called when the [StateMachine] is first created to ensure
/// the initial state is properly set.
class InitialEvent extends AutomataEvent {}

/// Possible node types.
///
/// Note: final is a reserved keyword, therefore we use "terminal" as a
/// replacement
enum StateNodeType {
  /// A leaf node
  atomic,

  /// A state node with child states
  compound,

  /// A state that is composed by multiple states that are active at the
  /// same time, ie. in parallel.
  parallel,

  /// A terminal state node, once the state machine enters this state it
  /// cannot change state anymore.
  terminal,
}

/// Represents a Node for a particular [AutomataState] in our [StateMachine].
abstract class StateNode<S extends AutomataState> {
  /// Defines the initial [AutomataState].
  /// Used in [StateNode] of type [StateNodeType.compound].
  void initial<I extends AutomataState>();

  /// Attach a [StateNode] of a given [AutomataState].
  ///
  /// Optionally it can define a [StateNodeType], if no specific type is
  /// provided then one its inferred.
  void state<I extends AutomataState>({
    StateBuilder? builder,
    StateNodeType? type,
  });

  /// Attach a [TransitionDefinition] to allow to transition from this
  /// this [StateNode] to a given [StateNode] for a specific [AutomataEvent].
  void on<E extends AutomataEvent, Target extends AutomataState>({
    TransitionType type,
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  });

  /// Attach a Eventless [TransitionDefinition] to allow to transition from this
  /// [StateNode] to a given [StateNode] for any [AutomataEvent] as long as the
  /// conditions are met.
  void always<Target extends AutomataState>({
    GuardCondition<NullEvent>? condition,
    List<Action<NullEvent>>? actions,
  });

  /// Sets callback that will be called right after machine entrys this State.
  void onEntry(OnEntryAction onEntry);

  /// Sets callback that will be called right before machine exits this State.
  void onExit(OnExitAction onExit);

  /// Sets callback that will bne called when:
  /// - for a [StateNodeType.compound] - a child final substate is activated.
  /// - for a [StateNodeType.parallel] - all sub-states are in final states.
  void onDone<E extends AutomataEvent>({required List<Action<E>> actions});

  void invoke<Result>({InvokeBuilder? builder});
}

/// A function used to allow / deny execution of a transition.
typedef GuardCondition<E extends AutomataEvent> = bool Function(E event);

/// A function called when a transition is applied.
typedef Action<E extends AutomataEvent> = void Function(E event);

/// A function called when a [AutomataState] is entered.
typedef OnEntryAction = void Function(AutomataEvent? event);

/// A function called when a [AutomataState] is left.
typedef OnExitAction = void Function(AutomataEvent? event);

/// A function called on every transition.
typedef OnTransitionCallback = void Function(
  AutomataEvent e,
  StateMachineValue value,
);

/// A function used to compose [StateNode]s into our state machine.
typedef StateBuilder<S extends AutomataState> = void Function(StateNode<S>);

/// A function used to compose a [InvokeDefinition].
typedef InvokeBuilder = void Function(InvokeDefinition);

/// The asynchronous function to be called by a [StateNode] that contains a
/// [InvokeDefinition].
typedef InvokeSrcCallback<Result> = Future<Result> Function(AutomataEvent e);

/// [AutomataEvent] triggered an a [InvokeSrcCallback] is executed successfully.
class DoneInvokeEvent<Result> extends AutomataEvent {
  /// Identifier of the [InvokeDefinition] which triggered this [AutomataEvent].
  final String id;

  /// Data returned from a successful call to [InvokeDefinition.src] callback.
  final Result data;

  const DoneInvokeEvent({required this.id, required this.data});

  @override
  int get hashCode => id.hashCode ^ data.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoneInvokeEvent<Result> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          data == other.data;
}

/// Abstract [AutomataEvent] that serves as base class for every error triggerd
/// by the state machine.
abstract class ErrorEvent extends AutomataEvent {
  final Object exception;

  const ErrorEvent({required this.exception});

  @override
  int get hashCode => exception.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorEvent &&
          runtimeType == other.runtimeType &&
          exception == other.exception;
}

/// Platform error event.
class PlatformErrorEvent extends ErrorEvent {
  const PlatformErrorEvent({required Object exception})
      : super(exception: exception);
}
