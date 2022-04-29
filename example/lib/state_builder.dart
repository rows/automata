import 'package:automata/automata.dart';
import 'package:flutter/widgets.dart';

// TODO(canastro): in a follow-up PR I will either create a separate sub-package
//  for automata_flutter, or move this (and test) to the automata package.

/// Buildes a wiget for a [AutomataStateBuilderFactory]
typedef AutomataStateWidgetBuilder = Widget Function(
  BuildContext context,
);

/// Represents a type entry to [AutomataStateBuilder].
class AutomataStateBuilderFactory {
  final AutomataStateWidgetBuilder stateWidgetBuilder;

  AutomataStateBuilderFactory(this.stateWidgetBuilder);

  Widget call(BuildContext context) {
    return stateWidgetBuilder(context);
  }
}

/// A [StatelessWidget] that renders a specific widget subtree for each possible
/// values of the given [machine].
///
/// It is useful for rendering different widgets for a value that can assume
/// subtypes given different conditions.
///
/// Be aware that if your [StateMachine] might be in multiple states if it
/// has a [StateNodeType.parallel] node. In that case, this widget might not
/// suite your needs as it will render the first state that matches.
///
/// Usage example
/// ```dart
/// class _Idle extends AutomataState {}
/// class _Loading extends AutomataState {}
/// class _Failure extends AutomataState {}
/// class _Success extends AutomataState {}
///
/// final a = AutomataStateBuilder(
///   machine: stateMachine,
///   stateBuilders: {
///     _Failure: AutomataStateBuilderFactory((context) {
///       return ElevatedButton(
///         onPressed: () => _machineNotifier.send(_OnRetry()),
///         child: const Text('Retry'),
///       );
///     }),
///     _Success: AutomataStateBuilderFactory((context) {
///       return ListView(
///         children: _machineNotifier.value
///             .map(
///               (e) => Text(e.title),
///             )
///             .toList(),
///       );
///     }),
///   },
///   defaultBuilder: ((context) {
///     return const Text('Loading');
///   }),
/// );
/// ```
class AutomataStateBuilder extends StatelessWidget {
  final Map<Type, AutomataStateBuilderFactory> stateBuilders;
  final AutomataStateWidgetBuilder defaultBuilder;
  final StateMachine machine;

  const AutomataStateBuilder({
    Key? key,
    required this.machine,
    required this.stateBuilders,
    required this.defaultBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    for (final entry in stateBuilders.entries) {
      final state = entry.key;

      if (machine.isInState(state)) {
        return entry.value(context);
      }
    }

    return defaultBuilder(context);
  }
}
