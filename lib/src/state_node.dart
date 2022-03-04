import 'package:automata/src/invoke_definition.dart';
import 'package:collection/collection.dart';

import 'state_machine_value.dart';
import 'transition_definition.dart';
import 'types.dart';

/// TODO: Can StateNodes have a `data` property that is passed into the
///  condition of the onDone? according to XState, it does. Check reference.
class OnDone<E extends AutomataEvent> {
  final List<Action<E>>? actions;

  OnDone({required this.actions});
}

/// Internal definition of a [StateNode].
///
/// It includes some methods that should not be called outside of the scope
/// of this library.
class StateNodeDefinition<S extends AutomataState> implements StateNode {
  /// Current node's initial state.
  /// Should be null in case of a leaf node.
  Type? _initialState;

  /// [AutomataState] associated with this [StateNodeDefinition].
  late final Type stateType;

  /// Path of [StateNodeDefinition] from the rootNode up until this node.
  /// It does not include the current node.
  late final List<StateNodeDefinition<AutomataState>> path;
  late final Set<Type> fullPathStateType = (() {
    return {
      ...path.map((e) => e.stateType).toSet(),
      stateType,
    };
  })();

  /// The parent [StateNodeDefinition].
  StateNodeDefinition<AutomataState>? parentNode;

  /// List of [StateNodeDefinition].
  Map<Type, StateNodeDefinition<AutomataState>> childNodes = {};

  /// Maps of [AutomataEvent]s to [TransitionDefinition] available for this
  /// [StateNodeDefinition].
  final Map<Type, List<TransitionDefinition>> _eventTransitionsMap = {};

  InvokeDefinition? _invoke;

  /// Action invoked on entry this [StateNodeDefinition].
  OnEntryAction? _onEntryAction;

  /// Action invoked on exit this [StateNodeDefinition].
  OnExitAction? _onExitAction;

  OnDone? _onDone;

  /// User defined [StateNodeType].
  final StateNodeType? _stateNodeType;

  /// Lazily compute the actual [StateNodeType] based on a user defined value
  /// or computed based on this state's structure.
  late final stateNodeType = (() {
    if (_stateNodeType != null) {
      return _stateNodeType;
    }

    if (childNodes.isNotEmpty) {
      return StateNodeType.compound;
    }

    return StateNodeType.atomic;
  })();

  /// Compute the initialStateValue.
  late final List<StateNodeDefinition<AutomataState>> initialStateNodes = (() {
    // Reference:
    //  "when the state machine enters the parent <parallel> state, it also
    //  enters each child state"
    if (stateNodeType == StateNodeType.parallel) {
      final result = childNodes.values.toList();
      for (final childNode in childNodes.values) {
        result.addAll(childNode.initialStateNodes);
      }
      return result;
    }

    // Reference:
    //  "If neither the <initial> child or the 'initial' element is specified,
    //  the default initial state is the first child state in document order."
    if (stateNodeType == StateNodeType.compound) {
      late StateNodeDefinition<AutomataState> node;
      if (_initialState != null) {
        final initial = _initialState;

        if (!childNodes.containsKey(initial)) {
          throw Exception('Initial state "$initial" not found on "$stateType"');
        }
        node = childNodes[initial]!;
      } else {
        node = childNodes.values.first;
      }

      final result = [node];
      result.addAll(node.initialStateNodes);
      return result;
    }

    // If atomic or terminal there is no initial node.
    return <StateNodeDefinition<AutomataState>>[];
  })();

  StateNodeDefinition({
    this.parentNode,
    StateNodeType? stateNodeType,
  })  : stateType = S,
        _stateNodeType = stateNodeType,
        path = parentNode == null ? [] : [...parentNode.path, parentNode];

  /// Getter to retrieve the root node, ie. the first node in this node's
  /// [path].
  StateNodeDefinition<AutomataState> get rootNode =>
      path.isEmpty ? this : path.first;

  /// Defines the initial [AutomataState].
  /// Used in [StateNode] of type [StateNodeType.compound].
  @override
  void initial<I extends AutomataState>() {
    _initialState = I;
  }

  /// Attach a [StateNode] of a given [AutomataState].
  ///
  /// Optionally it can define a [StateNodeType], if no specific type is
  /// provided then one its inferred.
  @override
  void state<I extends AutomataState>({
    StateBuilder? builder,
    StateNodeType? type,
  }) {
    final newStateNode = StateNodeDefinition<I>(
      parentNode: this,
      stateNodeType: type,
    );

    childNodes[I] = newStateNode;
    builder?.call(newStateNode);
  }

  /// Attach a [TransitionDefinition] to allow to transition from this
  /// this [StateNode] to a given [StateNode] for a specific [AutomataEvent].
  @override
  void on<E extends AutomataEvent, TargetState extends AutomataState>({
    List<Action<E>>? actions,
    TransitionType? type,
    GuardCondition<E>? condition,
  }) {
    final onTransition = TransitionDefinition<S, E, TargetState>(
      sourceStateNode: this,
      targetState: TargetState,
      condition: condition,
      actions: actions,
      type: type,
    );

    _eventTransitionsMap[E] ??= <TransitionDefinition>[];
    _eventTransitionsMap[E]!.add(onTransition);
  }

  /// Attach a Eventless [TransitionDefinition] to allow to transition from this
  /// [StateNode] to a given [StateNode] for any [AutomataEvent] as long as the
  /// conditions are met.
  @override
  void always<TargetState extends AutomataState>({
    GuardCondition<NullEvent>? condition,
    List<Action<NullEvent>>? actions,
  }) {
    final onTransition = TransitionDefinition<S, NullEvent, TargetState>(
      sourceStateNode: this,
      targetState: TargetState,
      condition: condition,
      actions: actions,
    );

    _eventTransitionsMap[NullEvent] = _eventTransitionsMap[NullEvent] ?? [];
    _eventTransitionsMap[NullEvent]!.add(onTransition);
  }

  /// Sets callback that will be called right after machine entrys this State.
  @override
  void onEntry(OnEntryAction onEntry) {
    _onEntryAction = onEntry;
  }

  /// Sets callback that will be called right before machine exits this State.
  @override
  void onExit(OnExitAction onExit) {
    _onExitAction = onExit;
  }

  /// Sets callback that will bne called when:
  /// - for a [StateNodeType.compound] - a child final substate is activated.
  /// - for a [StateNodeType.parallel] - all sub-states are in final states.
  ///
  /// TODO:
  ///  when we have validations:
  ///  1. a onDone can only be placed on a compound state wich has a descendant
  ///  final node.
  ///  2. a onDone can only be placed on a parallel state which every child
  ///  has a descendant final node.
  @override
  void onDone<E extends AutomataEvent>({required List<Action<E>> actions}) {
    _onDone = OnDone<E>(actions: actions);
  }

  /// Invoke this node's [OnEntryAction].
  void callEntryAction<E extends AutomataEvent>(
    AutomataContextState? context,
    StateMachineValue value,
    E event,
  ) {
    _onEntryAction?.call(context, event);
    if (_invoke != null) {
      _invoke?.execute(context, value, event);
    }
  }

  /// Invoke this node's [OnExitAction].
  void callExitAction<E extends AutomataEvent>(
    AutomataContextState? context,
    E event,
  ) {
    _onExitAction?.call(context, event);
  }

  void callDoneActions<E extends AutomataEvent>(
    AutomataContextState? context,
    E event,
  ) {
    final actions = _onDone?.actions ?? [];
    for (final action in actions) {
      action.call(event, (context) => context);
    }
  }

  // Get all candidates in the path of the current node.
  List<TransitionDefinition> getCandidates<E>() {
    if (stateNodeType == StateNodeType.terminal) {
      return [];
    }

    return _eventTransitionsMap[E] ?? [];
  }

  /// Return all the [TransitionDefinition] for the given node and it's parents.
  ///
  /// Only one [TransitionDefinition] should be returned for each node, ie.
  /// if we have a single node with multiple transition definitions for the
  /// same event, we should only return the first one that returns true from
  /// the [GuardCondition].
  ///
  ///  A transition T is enabled by named event E in atomic state S if
  ///   a) T's source state is S or an ancestor of S,and
  ///   b) T matches E's name (see 3.12.1 Event Descriptors) and
  ///   c) T lacks a 'cond' attribute or its 'cond' attribute evaluates to
  ///     "true".
  ///
  /// See also:
  ///  - [SCXML: Selecting Transitions](https://www.w3.org/TR/scxml/#SelectingTransitions)
  List<TransitionDefinition> getTransitions<E extends AutomataEvent>(E event) {
    final transitions = <TransitionDefinition>[];

    for (final node in [this, ...path.reversed]) {
      final candidates = node.getCandidates<E>();

      final transition = candidates.firstWhereOrNull((item) {
        // ignore: avoid_dynamic_calls
        final dynamic condition = (item as dynamic).condition;

        // ignore: avoid_dynamic_calls
        if (condition != null && condition(event) == false) {
          return false;
        }

        return true;
      });

      if (transition != null) {
        transitions.add(transition);
      }
    }

    return transitions;
  }

  /// Attach a [InvokeDefinition] to this node.
  @override
  void invoke<Result>({InvokeBuilder? builder}) {
    _invoke = InvokeDefinition<S, AutomataEvent, Result>(
      sourceStateNode: this,
    );

    builder?.call(_invoke!);
  }

  @override
  String toString() {
    if (path.isEmpty) {
      return stateType.toString();
    }

    return '${path.last} > $stateType';
  }
}
