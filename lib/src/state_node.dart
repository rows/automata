import 'package:state_machine/src/types.dart';

import '../state_machine.dart';
import 'transition_definition.dart';

class StateNodeDefinition<S extends State> implements StateNode {
  late final Type _initialState;
  late final Type currentState;
  StateNodeDefinition? currentStateNode;
  StateNodeDefinition? parentNode;
  List<StateNodeDefinition> nodes = [];
  final Map<Type, TransitionDefinition> _eventTransitionsMap = {};
  OnEnterFunction? _onEnterCallback;
  OnExitFunction? _onExitCallback;

  StateNodeDefinition({this.parentNode}) {
    currentState = S;
  }

  void start() {
    currentStateNode = nodes.firstWhere(
      (element) => element.currentState == _initialState,
    );
  }

  /// Sets initial State.
  @override
  void initialState<I extends State>({String? label}) {
    _initialState = I;
  }

  @override
  void state<I extends State>(BuildState buildState) {
    final newStateNode = StateNodeDefinition<I>(parentNode: this);
    nodes.add(newStateNode);
    buildState(newStateNode);
  }

  @override
  void on<E extends Event, TOSTATE extends State>({
    GuardConditionFunction<E>? condition,
    List<ActionFunction<E>>? actions,
    String? conditionLabel,
    String? sideEffectLabel,
  }) {
    final onTransition = OnTransitionDefinition<S, E, TOSTATE>(
      this,
      condition,
      TOSTATE,
      actions,
      conditionLabel: conditionLabel,
      sideEffectLabel: sideEffectLabel,
    );

    _eventTransitionsMap[E] = onTransition;
  }

  /// Sets callback that will be called right after machine enters this State.
  @override
  void onEnter(OnEnterFunction onEnter, {String? label}) {
    _onEnterCallback = onEnter;
  }

  /// Sets callback that will be called right before machine exits this State.
  @override
  void onExit(OnExitFunction onExit, {String? label}) {
    _onExitCallback = onExit;
  }

  void enter(StateNodeDefinition fromState, Event event) {
    _onEnterCallback?.call(fromState.currentState, event);
  }

  void exit(StateNodeDefinition toState, Event event) {
    _onExitCallback?.call(toState.currentState, event);
  }

  SendResult? send<E extends Event>(E event) {
    final parent = parentNode;
    final transition = _eventTransitionsMap[event.runtimeType];
    if (transition == null || parent == null) {
      return null;
    }

    if (transition is OnTransitionDefinition) {
      // TODO: weird type runtime errors, fsm2 seems to run into the same issue
      final dynamic t = transition;
      if ((t.condition as dynamic) != null && !t.condition!(event)) {
        return null;
      }

      final stateNode = parent.nodes.firstWhere(
        (element) => element.currentState == transition.toState,
      );

      return SendResult(stateNode: stateNode, transition: transition);
    }

    return null;
  }
}

class SendResult {
  final StateNodeDefinition stateNode;
  final OnTransitionDefinition transition;

  SendResult({required this.stateNode, required this.transition});
}
