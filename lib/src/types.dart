import 'package:flutter/foundation.dart';

@immutable
abstract class State {}

@immutable
abstract class Event {}

typedef GuardConditionFunction<E extends Event> = bool Function(E event);

typedef ActionFunction<E extends Event> = void Function(E event);

/// The method signature for a [State]s [onEnter] method
typedef OnEnterFunction = void Function(Type fromState, Event? event);

/// The method signature for a [State]s [onExit] method
typedef OnExitFunction = void Function(Type toState, Event? event);

typedef BuildState<S extends State> = void Function(StateNode<S>);

abstract class StateNode<S extends State> {
  void initialState<I extends State>({String? label});

  void state<I extends State>(BuildState buildState);

  void on<E extends Event, TOSTATE extends State>({
    GuardConditionFunction<E>? condition,
    List<ActionFunction<E>>? actions,
    String? conditionLabel,
    String? sideEffectLabel,
  });

  /// Sets callback that will be called right after machine enters this State.
  void onEnter(OnEnterFunction onEnter, {String? label});

  /// Sets callback that will be called right before machine exits this State.
  void onExit(OnExitFunction onExit, {String? label});
}
