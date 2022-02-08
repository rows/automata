import '../state_machine.dart';
import 'transition_definition.dart';

enum StateNodeType { atomic, parallel, terminal }

typedef StatePath = List<StateNodeDefinition>;

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

  late final StatePath path;

  /// The parent [StateNodeDefinition].
  StateNodeDefinition? parentNode;

  /// List of [StateNodeDefinition].
  Map<Type, StateNodeDefinition> childNodes = {};

  /// Maps of [Event]s to [TransitionDefinition] available for this
  /// [StateNodeDefinition].
  final Map<Type, List<OnTransitionDefinition>> _eventTransitionsMap = {};

  /// Action invoked on enter this [StateNodeDefinition].
  OnEnterAction? _onEnterAction;

  /// Action invoked on exit this [StateNodeDefinition].
  OnExitAction? _onExitAction;

  /// Define the [StateNodeType] of this [StateNode].
  final StateNodeType stateNodeType;

  StateNodeDefinition({
    this.parentNode,
    this.stateNodeType = StateNodeType.atomic,
  })  : stateType = S,
        path = parentNode == null ? [] : [...parentNode.path, parentNode];

  /// A state is a leaf state if it has no child states.
  bool get isLeaf => childNodes.isEmpty;

  StateNodeDefinition get rootNode => path.isEmpty ? this : path.first;

  /// Compute the initialStateValue.
  late final initialStateNode = (() {
    if (stateNodeType == StateNodeType.parallel) {
      throw UnimplementedError();
    }

    if (_initialState != null) {
      final initial = _initialState!;

      if (!childNodes.containsKey(initial)) {
        throw Exception('Initial state "$initial" not found on "$stateType"');
      }

      return childNodes[initial]!;
    }

    return null;
  })();

  /// Sets initial State.
  @override
  void initial<I extends State>({String? label}) {
    _initialState = I;
  }

  /// Attach a [StateNodeDefinition].
  @override
  void state<I extends State>({
    BuildState? builder,
    StateNodeType type = StateNodeType.atomic,
  }) {
    final newStateNode = StateNodeDefinition<I>(
      parentNode: this,
      stateNodeType: type,
    );

    childNodes[I] = newStateNode;
    builder?.call(newStateNode);
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

    _eventTransitionsMap[E] = _eventTransitionsMap[E] ?? [];
    _eventTransitionsMap[E]!.add(onTransition);
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

  void callEnter<E extends Event>(E event) {
    _onEnterAction?.call(event);
  }

  void callExit<E extends Event>(E event) {
    _onExitAction?.call(event);
  }

  List<OnTransitionDefinition> getCandidates<E>() {
    // we might want to implement transient transitions and wildcards
    return _eventTransitionsMap[E] ?? [];
  }

  List<OnTransitionDefinition> transition<E extends Event>(
    E event, {
    OnTransitionCallback? onTransition,
  }) {
    final candidates = getCandidates<E>();

    return candidates.where((item) {
      final dynamic candidate = item;
      if ((candidate.condition as dynamic) != null &&
          !candidate.condition!(event)) {
        return false;
      }

      return true;
    }).toList();
  }

  List<StateNodeDefinition> getIntialEnterNodes() {
    var result = <StateNodeDefinition>[];

    if (stateNodeType == StateNodeType.parallel) {
      for (final childNode in childNodes.values) {
        result.add(childNode);
        result.addAll(childNode.getIntialEnterNodes());
      }
    } else if (initialStateNode != null) {
      result.add(initialStateNode!);
      result.addAll(initialStateNode!.getIntialEnterNodes());
    }

    return result;
  }

  @override
  String toString() {
    if (path.isEmpty) {
      return stateType.toString();
    }

    return '${path.join(' > ')} > $stateType';
  }
}
