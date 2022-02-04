import 'package:state_machine/src/types.dart';

class TransitionDefinition<E extends Event> {
  /// The state this transition is attached to.
  final StateNode<State> fromStateNode;

  final GuardConditionFunction<E>? condition;
  final List<ActionFunction<E>>? actions;
  final String? conditionLabel;
  final String? sideEffectLabel;

  TransitionDefinition({
    required this.fromStateNode,
    required this.condition,
    required this.actions,
    required this.conditionLabel,
    required this.sideEffectLabel,
  });
}

class OnTransitionDefinition<S extends State, E extends Event,
    TOSTATE extends State> extends TransitionDefinition<E> {
  /// If this [OnTransitionDefinition] is trigger [toState] will be the new [State]
  Type toState;

  OnTransitionDefinition(
    StateNode stateNode,
    GuardConditionFunction<E>? condition,
    this.toState,
    List<ActionFunction<E>>? actions, {
    String? conditionLabel,
    String? sideEffectLabel,
  }) : super(
          fromStateNode: stateNode,
          condition: condition,
          actions: actions,
          conditionLabel: conditionLabel,
          sideEffectLabel: sideEffectLabel,
        );
}
