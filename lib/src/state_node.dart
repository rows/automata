import 'package:state_machine/src/types.dart';

import '../state_machine.dart';
import 'transition_definition.dart';

/// Internal definition of a [StateNode].
///
/// It includes some methods that should not be called outside of the scope
/// of this library.
class StateNodeDefinition<S extends State> implements StateNode {
  /// Current node's initial state.
  /// Should be null in case of a leaf node.
  Type? _initialState;

  /// [State] associated with this [StateNodeDefinition].
  late final Type stateType;

  /// Keep track of child's active [StateNodeDefinition].
  ///
  /// TODO: this should be a list, as when you are in a coregion you should
  ///  have multiple active states at the same time.
  List<StateNodeDefinition>? activeStateNode;

  /// The parent [StateNodeDefinition].
  StateNodeDefinition? parentNode;

  /// List of [StateNodeDefinition].
  List<StateNodeDefinition> childNodes = [];

  /// Maps of [Event]s to [TransitionDefinition] available for this
  /// [StateNodeDefinition].
  final Map<Type, TransitionDefinition> _eventTransitionsMap = {};

  /// Action invoked on enter this [StateNodeDefinition].
  OnEnterAction? _onEnterAction;

  /// Action invoked on exit this [StateNodeDefinition].
  OnExitAction? _onExitAction;

  /// Set to true if this [StateNodeDefinition] is a orthogonal region, here
  /// referred as concurrent region.
  final bool isCoregion;

  StateNodeDefinition({
    this.parentNode,
    this.isCoregion = false,
  }) : stateType = S;

  /// A state is a leaf state if it has no child states.
  bool get isLeaf => childNodes.isEmpty;

  void start() {
    if (!isCoregion) {
      final active = childNodes.firstWhere(
        (element) => element.stateType == _initialState,
      );

      activeStateNode = [active];
      if (active._initialState != null) {
        active.start();
      }
    } else {
      // TODO: implement coregion initial state
    }
  }

  /// Sets initial State.
  @override
  void initialState<I extends State>({String? label}) {
    _initialState = I;
  }

  /// Attach a [StateNodeDefinition].
  @override
  void state<I extends State>(BuildState buildState) {
    final newStateNode = StateNodeDefinition<I>(parentNode: this);
    childNodes.add(newStateNode);
    buildState(newStateNode);
  }

  /// Attach a [StateNodeDefinition] marked as concurrent region.
  @override
  void coregion<I extends State>(BuildState buildState) {
    final newStateNode = StateNodeDefinition<I>(
      parentNode: this,
      isCoregion: true,
    );

    childNodes.add(newStateNode);
    buildState(newStateNode);
  }

  /// Attach a [OnTransitionDefinition] to allow to transition from this
  /// this [StateNode] to a given [StateNode].
  @override
  void on<E extends Event, TOSTATE extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  }) {
    final onTransition = OnTransitionDefinition<S, E, TOSTATE>(
      fromState: this,
      toState: TOSTATE,
      condition: condition,
      actions: actions,
    );

    _eventTransitionsMap[E] = onTransition;
  }

  /// Sets callback that will be called right after machine enters this State.
  @override
  void onEnter(OnEnterAction onEnter, {String? label}) {
    _onEnterAction = onEnter;
  }

  /// Sets callback that will be called right before machine exits this State.
  @override
  void onExit(OnExitAction onExit, {String? label}) {
    _onExitAction = onExit;
  }

  /// Execute the onEnter action for this [StateNode].
  void enter(StateNodeDefinition fromState, Event event) {
    _onEnterAction?.call(fromState.stateType, event);
  }

  /// Execute the onExit action for this [StateNode].
  void exit(StateNodeDefinition toState, Event event) {
    _onExitAction?.call(toState.stateType, event);
  }

  /// Execute an event on this [StateNode] if any present [condition] is
  /// evaluated as true and a valid destination [StateNode] is found.
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

      final stateNode = parent.childNodes.firstWhere(
        (element) => element.stateType == transition.toState,
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
