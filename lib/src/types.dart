import 'package:flutter/foundation.dart';
import 'package:state_machine/src/state_node.dart';

@immutable
abstract class State {}

@immutable
abstract class Event {}

abstract class RootState extends State {}

/// [Event] called when the [StateMachine] is first created to ensure the
/// initial state is properly set.
class InitialEvent extends Event {}

///
abstract class StateNode<S extends State> {
  void initial<I extends State>({String? label});

  void state<I extends State>({
    StateBuilder? builder,
    StateNodeType type = StateNodeType.atomic,
  });

  void on<E extends Event, Target extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  });

  /// Sets callback that will be called right after machine entrys this State.
  void onEntry(OnEntryAction onEntry, {String? label});

  /// Sets callback that will be called right before machine exits this State.
  void onExit(OnExitAction onExit, {String? label});
}

///
typedef GuardCondition<E extends Event> = bool Function(E event);

typedef Action<E extends Event> = void Function(Event event);

/// The method signature for a [State]s [onEntry] method
typedef OnEntryAction = void Function(Event? event);

/// The method signature for a [State]s [onExit] method
typedef OnExitAction = void Function(Event? event);

typedef OnTransitionCallback = void Function(Type from, Event e, Type to);

typedef StateBuilder<S extends State> = void Function(StateNode<S>);
