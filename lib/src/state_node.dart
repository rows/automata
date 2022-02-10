import 'package:collection/collection.dart';

import 'transition_definition.dart';
import 'types.dart';

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

  /// Path of [StateNodeDefinition] from the rootNode up until this node.
  /// It does not include the current node.
  late final List<StateNodeDefinition> path;

  /// The parent [StateNodeDefinition].
  StateNodeDefinition? parentNode;

  /// List of [StateNodeDefinition].
  Map<Type, StateNodeDefinition> childNodes = {};

  /// Maps of [Event]s to [TransitionDefinition] available for this
  /// [StateNodeDefinition].
  final Map<Type, List<TransitionDefinition>> _eventTransitionsMap = {};

  /// Action invoked on entry this [StateNodeDefinition].
  OnEntryAction? _onEntryAction;

  /// Action invoked on exit this [StateNodeDefinition].
  OnExitAction? _onExitAction;

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

  StateNodeDefinition({
    this.parentNode,
    StateNodeType? stateNodeType,
  })  : stateType = S,
        _stateNodeType = stateNodeType,
        path = parentNode == null ? [] : [...parentNode.path, parentNode];

  /// A state is a leaf state if it has no child states.
  bool get isLeaf => childNodes.isEmpty;

  /// Getter to retrieve the root node, ie. the first node in this node's
  /// [path].
  StateNodeDefinition get rootNode => path.isEmpty ? this : path.first;

  /// Compute the initialStateValue.
  late final initialStateNodes = (() {
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
      late StateNodeDefinition node;
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
    return <StateNodeDefinition>[];
  })();

  /// Sets initial State.
  @override
  void initial<I extends State>({String? label}) {
    _initialState = I;
  }

  /// Attach a [StateNodeDefinition].
  @override
  void state<I extends State>({StateBuilder? builder, StateNodeType? type}) {
    final newStateNode = StateNodeDefinition<I>(
      parentNode: this,
      stateNodeType: type,
    );

    childNodes[I] = newStateNode;
    builder?.call(newStateNode);
  }

  /// Attach a [TransitionDefinition] to allow to transition from this
  /// this [StateNode] to a given [StateNode].
  @override
  void on<E extends Event, TargetState extends State>({
    GuardCondition<E>? condition,
    List<Action<E>>? actions,
  }) {
    final onTransition = TransitionDefinition<S, E, TargetState>(
      fromStateNode: this,
      targetState: TargetState,
      condition: condition,
      actions: actions,
    );

    _eventTransitionsMap[E] = _eventTransitionsMap[E] ?? [];
    _eventTransitionsMap[E]!.add(onTransition);
  }

  /// Sets callback that will be called right after machine entrys this State.
  @override
  void onEntry(OnEntryAction onEntry, {String? label}) {
    _onEntryAction = onEntry;
  }

  /// Sets callback that will be called right before machine exits this State.
  @override
  void onExit(OnExitAction onExit, {String? label}) {
    _onExitAction = onExit;
  }

  /// Invoke this node's [OnEntryAction].
  void callEntry<E extends Event>(E event) {
    _onEntryAction?.call(event);
  }

  /// Invoke this node's [OnExitAction].
  void callExit<E extends Event>(E event) {
    _onExitAction?.call(event);
  }

  // Get all candidates in the path of the current node.
  List<TransitionDefinition> getCandidates<E>() {
    return _eventTransitionsMap[E] ?? [];
  }

  /// Return all the [TransitionDefinition] for the given node and it's parents.
  ///
  /// Only one [TransitionDefinition] should be returned for each node, ie.
  /// if we have a single node with multiple transition definitions for the
  /// same event, we should only return the first one that returns true from
  /// the [GuardCondition].
  ///
  List<TransitionDefinition> getTransitions<E extends Event>(E event) {
    final transitions = <TransitionDefinition>[];

    for (final node in [this, ...path.reversed]) {
      final candidates = node.getCandidates<E>();

      final transition = candidates.firstWhereOrNull((item) {
        final dynamic candidate = item;
        if ((candidate.condition as dynamic) != null &&
            !candidate.condition!(event)) {
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

  @override
  String toString() {
    if (path.isEmpty) {
      return stateType.toString();
    }

    return '${path.join(' > ')} > $stateType';
  }
}
