import '../state_machine.dart';
import 'transition_definition.dart';

enum StateNodeType { atomic, parallel, terminal }

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
  List<StateNodeDefinition>? _activeStateNodes;

  List<StateNodeDefinition>? get activeStateNodes => _activeStateNodes;

  void setActiveStateNodes({
    List<StateNodeDefinition>? nodes,
    required Event event,
  }) {
    final previousNodes = _activeStateNodes ?? [];
    for (final node in previousNodes) {
      node._onExitAction?.call(event);
    }

    _activeStateNodes = nodes;

    final nextNodes = nodes ?? [];
    for (final node in nextNodes) {
      if (node.stateNodeType == StateNodeType.parallel) {
        node._activeStateNodes = node.childNodes;
        for (final childNode in node.childNodes) {
          childNode.transition(InitialEvent());
        }
      } else {
        node.transition(InitialEvent());
      }

      node._onEnterAction?.call(event);
    }
  }

  /// The parent [StateNodeDefinition].
  StateNodeDefinition? parentNode;

  /// List of [StateNodeDefinition].
  List<StateNodeDefinition> childNodes = [];

  /// Maps of [Event]s to [TransitionDefinition] available for this
  /// [StateNodeDefinition].
  final Map<Type, List<TransitionDefinition>> _eventTransitionsMap = {};

  /// Action invoked on enter this [StateNodeDefinition].
  OnEnterAction? _onEnterAction;

  /// Action invoked on exit this [StateNodeDefinition].
  OnExitAction? _onExitAction;

  /// Define the [StateNodeType] of this [StateNode].
  final StateNodeType stateNodeType;

  StateNodeDefinition({
    this.parentNode,
    this.stateNodeType = StateNodeType.atomic,
  }) : stateType = S;

  /// A state is a leaf state if it has no child states.
  bool get isLeaf => childNodes.isEmpty;

  StateNodeDefinition? findStateDefinition(
    Type state,
  ) {
    if (stateType == state) {
      return this;
    }

    for (final child in childNodes) {
      final node = child.findStateDefinition(state);
      if (node != null) {
        return node;
      }
    }

    return null;
  }

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

    childNodes.add(newStateNode);
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

  StateNodeDefinition? _getInitialStateNode() {
    if (_initialState == null) {
      return null;
    }

    if (stateNodeType == StateNodeType.parallel) {
      throw UnimplementedError();
    }

    final stateNode = childNodes.firstWhere(
      (element) => element.stateType == _initialState,
    );

    return stateNode;
  }

  /// Execute an event on this [StateNode] if any present [condition] is
  /// evaluated as true and a valid destination [StateNode] is found.
  void transition<E extends Event>(
    E event, {
    OnTransitionCallback? onTransition,
  }) {
    if (E == InitialEvent) {
      final stateNode = _getInitialStateNode();
      if (stateNode == null) {
        return;
      }

      // TODO: check if we are setting all initial states as active??
      stateNode.transition(event, onTransition: onTransition);
      setActiveStateNodes(nodes: [stateNode], event: event);

      return;
    }

    final parent = parentNode;
    final transitions = _eventTransitionsMap[event.runtimeType];
    if (transitions != null && transitions.isNotEmpty && parent != null) {
      for (final transition in transitions) {
        try {
          if (transition is OnTransitionDefinition) {
            // TODO: weird type runtime errors, fsm2 seems to run into the same issue
            final dynamic t = transition;
            if ((t.condition as dynamic) != null && !t.condition!(event)) {
              continue;
            }

            final actions = t.actions ?? [];
            for (final action in actions) {
              action(event);
            }

            if (stateNodeType == StateNodeType.parallel) {
              final stateNode = childNodes.firstWhere(
                (element) => element.stateType == transition.toState,
              );

              final newNodes = [
                stateNode,
                ...activeStateNodes?.where((node) => node != stateNode) ??
                    <StateNodeDefinition<State>>[],
              ];

              setActiveStateNodes(nodes: newNodes, event: event);
              onTransition?.call(stateType, event, stateNode.stateType);
            } else {
              final startNode = parentNode ?? this;
              final endNode = startNode.findStateDefinition(
                transition.toState,
              );

              var node = endNode;
              while (node != startNode && node != null) {
                // if (node.parentNode!.childNodes.contains(stateNode)) {
                node.parentNode!.setActiveStateNodes(
                  nodes: [node],
                  event: event,
                );
                onTransition?.call(stateType, event, node.stateType);
                // }
                node = node.parentNode;
              }

              print(node);
            }
          } else {
            throw UnimplementedError();
          }
        } on Object {}
        break;
      }
      return;
    }

    if (activeStateNodes == null || activeStateNodes?.isEmpty == true) {
      return;
    }

    for (final node in activeStateNodes!) {
      node.transition(event, onTransition: onTransition);
    }
  }
}
