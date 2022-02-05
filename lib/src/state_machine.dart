import 'package:state_machine/src/state_value.dart';
import 'package:state_machine/src/types.dart';

import 'state_node.dart';

abstract class RootState extends State {}

class InitialEvent extends Event {}

typedef OnTransitionCallback = void Function(Type from, Event e, Type to);

class StateMachine {
  /// TODO: we either have a tree of [StateValue] or follow through the
  ///  the graph of [StateNodeDefinition] and check the
  /// [StateNodeDefinition.activeStateNode] of each node
  late StateValue value;

  /// TODO: currently we use this a the currently active state node, but this
  ///  won't work in nested states and coregions. we should make this a
  ///  rootNode.
  late StateNodeDefinition currentStateNode;

  /// The [OnTransitionCallback] will be called on every state transition the
  /// [StateMachine] performs.
  OnTransitionCallback? onTransition;

  StateMachine._(
    StateNodeDefinition rootNode, {
    this.onTransition,
  }) {
    rootNode.start();

    /// TODO: right now assumes a single active state node, fix for the
    ///  coregions.
    currentStateNode = rootNode.activeStateNode!.first;
    value = StateValue(stateNode: rootNode.activeStateNode!.first);
    currentStateNode.enter(rootNode, InitialEvent());
  }

  /// Creates a [StateMachine] using a builder pattern.
  factory StateMachine.create(
    void Function(StateNode) buildGraph, {
    OnTransitionCallback? onTransition,
  }) {
    final rootNode = StateNodeDefinition<RootState>();
    buildGraph(rootNode);

    return StateMachine._(rootNode, onTransition: onTransition);
  }

  void send<E extends Event>(E event) {
    final result = currentStateNode.send(event);
    if (result == null) {
      return;
    }

    final toState = result.stateNode;
    final fromState = currentStateNode;
    final transition = result.transition as dynamic;
    final transitionActions = transition.actions as List<dynamic>? ?? [];

    currentStateNode.exit(toState, event);
    currentStateNode = toState;

    for (final action in transitionActions) {
      action(event);
    }

    currentStateNode.enter(fromState, event);

    onTransition?.call(fromState.stateType, event, toState.stateType);
  }

  bool isInState<S>() {
    return currentStateNode.stateType == S;
  }
}
