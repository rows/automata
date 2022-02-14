import 'package:meta/meta.dart';

@immutable
abstract class State {}

@immutable
abstract class Event {}

abstract class RootState extends State {}

/// Pseudo [Event] used to trigger eventless transitions.
class NoEvent extends Event {}

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

///
abstract class StateNode<S extends State> {
  void initial<I extends State>({String? label});

  void state<I extends State>({StateBuilder? builder, StateNodeType? type});

  void on<E extends Event, Target extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  });

  void always<Target extends State>({
    GuardCondition<NoEvent>? condition,
    List<Action<NoEvent>>? actions,
  });

  /// Sets callback that will be called right after machine entrys this State.
  void onEntry(OnEntryAction onEntry);

  /// Sets callback that will be called right before machine exits this State.
  void onExit(OnExitAction onExit);

  void onDone<E extends Event>({required List<Action<E>> actions});
}

///
typedef GuardCondition<E extends Event> = bool Function(E event);

typedef Action<E extends Event> = void Function(E event);

/// The method signature for a [State]s [onEntry] method
typedef OnEntryAction = void Function(Event? event);

/// The method signature for a [State]s [onExit] method
typedef OnExitAction = void Function(Event? event);

typedef OnTransitionCallback = void Function(Type source, Event e, Type target);

typedef StateBuilder<S extends State> = void Function(StateNode<S>);
