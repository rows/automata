import 'package:state_machine/src/types.dart';

class TransitionDefinition<E extends Event> {
  /// The state this transition is attached to.
  final StateNode<State> fromStateNode;

  final GuardCondition<E>? condition;
  final List<Action<E>>? actions;

  TransitionDefinition({
    required this.fromStateNode,
    required this.condition,
    required this.actions,
  });
}

class OnTransitionDefinition<S extends State, E extends Event,
    TOSTATE extends State> extends TransitionDefinition<E> {
  /// If this [OnTransitionDefinition] is trigger [toState] will be the new [State]
  Type toState;

  OnTransitionDefinition({
    required StateNode fromState,
    GuardCondition<E>? condition,
    required this.toState,
    List<Action<E>>? actions,
  }) : super(
          fromStateNode: fromState,
          condition: condition,
          actions: actions,
        );
}
