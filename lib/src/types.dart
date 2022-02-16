import 'package:meta/meta.dart';

import 'state_machine_value.dart';

/// Base class for all States that you pass to the state machine.
///
/// All your [State] classes MUST extend this [State] class.
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
abstract class State {
  const State();
}

/// Base class for all Events that you pass to the state machine.
///
/// All your [Event] class MUST extends the [Event] class
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
abstract class Event {
  const Event();
}

/// Pseudo [State] used as root of our state machine.
abstract class RootState extends State {}

/// Pseudo [Event] used to trigger eventless transitions.
@immutable
class NullEvent extends Event {
  const NullEvent();
}

/// [Event] called when the [StateMachine] is first created to ensure the
/// initial state is properly set.
class InitialEvent extends Event {}

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

/// Represents a Node for a particular [State] in our [StateMachine].
abstract class StateNode<S extends State> {
  /// Defines the initial [State].
  /// Used in [StateNode] of type [StateNodeType.compound].
  void initial<I extends State>();

  /// Attach a [StateNode] of a given [State].
  ///
  /// Optionally it can define a [StateNodeType], if no specific type is
  /// provided then one its inferred.
  void state<I extends State>({StateBuilder? builder, StateNodeType? type});

  /// Attach a [TransitionDefinition] to allow to transition from this
  /// this [StateNode] to a given [StateNode] for a specific [Event].
  void on<E extends Event, Target extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  });

  /// Attach a Eventless [TransitionDefinition] to allow to transition from this
  /// [StateNode] to a given [StateNode] for any [Event] as long as the
  /// conditions are met.
  void always<Target extends State>({
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
  void onDone<E extends Event>({required List<Action<E>> actions});
}

/// A function used to allow / deny execution of a transition.
typedef GuardCondition<E extends Event> = bool Function(E event);

/// A function called when a transition is applied.
typedef Action<E extends Event> = void Function(E event);

/// A function called when a [State] is entered.
typedef OnEntryAction = void Function(Event? event);

/// A function called when a [State] is left.
typedef OnExitAction = void Function(Event? event);

/// A function called on every transition.
typedef OnTransitionCallback = void Function(Event e, StateMachineValue value);

/// A function used to compose [StateNode]s into our state machine.
typedef StateBuilder<S extends State> = void Function(StateNode<S>);
