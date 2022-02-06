import 'package:flutter/foundation.dart';
import 'package:state_machine/src/state_node.dart';

@immutable
abstract class State {}

@immutable
abstract class Event {}

abstract class RootState extends State {}

class InitialEvent extends Event {}

typedef GuardCondition<E extends Event> = bool Function(E event);

typedef Action<E extends Event> = void Function(E event);

/// The method signature for a [State]s [onEnter] method
typedef OnEnterAction = void Function(Event? event);

/// The method signature for a [State]s [onExit] method
typedef OnExitAction = void Function(Event? event);

typedef BuildState<S extends State> = void Function(StateNode<S>);

abstract class StateNode<S extends State> {
  void initial<I extends State>({String? label});

  void state<I extends State>({
    BuildState? builder,
    StateNodeType type = StateNodeType.atomic,
  });

  void on<E extends Event, TOSTATE extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  });

  /// Sets callback that will be called right after machine enters this State.
  void onEnter(OnEnterAction onEnter, {String? label});

  /// Sets callback that will be called right before machine exits this State.
  void onExit(OnExitAction onExit, {String? label});
}
