import 'dart:convert';
import 'dart:io';

import '../automata.dart';
import 'state_node.dart';
import 'transition_definition.dart';

const _kHardcodedConditionFunctionName = 'canTransition';

/// Maps automata's [StateNodeType] to XState's node types.
const _kNodeTypeToString = {
  StateNodeType.terminal: 'final',
  StateNodeType.atomic: 'atomic',
  StateNodeType.compound: 'compound',
  StateNodeType.parallel: 'parallel',
};

/// Generates a json representation of the given [StateMachine] to be used
/// in [Stately's XState Viz](https://stately.ai/viz).
///
/// It returns a [String] and it creates a [File] so that you can copy to the
/// visualizer.
Future<String> exportToXStateViz(
  StateMachine machine, {
  bool writeToFile = true,
}) async {
  const encoder = JsonEncoder.withIndent('  ');
  final result = '''
import { createMachine } from "xstate";

const machine = createMachine(
  ${encoder.convert(machine.rootNode.toJSON(machine.id))},
  {
    guards: {
      $_kHardcodedConditionFunctionName: () => true,
    }
  }
);
    ''';

  if (writeToFile) {
    final id = machine.id ?? 'automata_machine';
    await File('$id.js').writeAsString(result);
  }

  return result;
}

/// Extension on [TransitionDefinition] to add a [toJSON] method, which will
/// allow us to generate a JSON representation of the machine to be used in
/// [Stately's XState Viz](https://stately.ai/viz).
///
/// If a transition contains a condition, we add a hardcoded reference to a
/// condition function which can be later on tweaked by the user.
extension on TransitionDefinition {
  Map<String, dynamic> toJSON() {
    final json = <String, dynamic>{
      'target': '#${targetStateNode.fullPathStateType.toString()}',
    };

    // ignore: avoid_dynamic_calls
    final dynamic condition = (this as dynamic).condition;
    if (condition != null) {
      json['cond'] = _kHardcodedConditionFunctionName;
    }

    return json;
  }
}

/// Extension on [StateNodeDefinition] to add a [toJSON] method, which will
/// allow us to generate a JSON representation of the machine to be used in
/// [Stately's XState Viz](https://stately.ai/viz).
extension on StateNodeDefinition {
  Map<String, dynamic> toJSON([String? machineId]) {
    final id =
        stateType == RootState ? machineId : fullPathStateType.toString();

    final json = <String, dynamic>{
      'id': id,
      'type': _kNodeTypeToString[stateNodeType],
    };

    if (initialStateNodes.length == 1) {
      json['initial'] = initialStateNodes.first.stateType.toString();
    }

    if (childNodes.isNotEmpty) {
      json['states'] = childNodes.values.fold<Map<String, dynamic>>(
        <String, dynamic>{},
        (acc, value) {
          acc[value.stateType.toString()] = value.toJSON();
          return acc;
        },
      );
    }

    if (eventTransitionsMap.isNotEmpty) {
      final on = <String, dynamic>{};
      final always = <Map<String, dynamic>>[];
      for (final transitions in eventTransitionsMap.values) {
        for (final transition in transitions) {
          if (transition.event == NullEvent) {
            always.add(transition.toJSON());
          } else {
            on[transition.event.toString()] = transition.toJSON();
          }
        }
      }

      if (on.isNotEmpty) {
        json['on'] = on;
      }

      if (always.isNotEmpty) {
        json['always'] = always;
      }
    }

    return json;
  }
}
