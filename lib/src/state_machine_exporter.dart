import 'dart:convert';

import 'package:automata/automata.dart';
import 'package:automata/src/state_node.dart';
import 'package:automata/src/transition_definition.dart';

String export(StateMachine machine) {
  const encoder = JsonEncoder.withIndent('  ');
  final result = '''
      ${encoder.convert(machine.rootNode.toJSON())}, 
      {
        guards: {
          canTransition: () => true,
        }
      }
    ''';

  return result;
}

extension on TransitionDefinition {
  Map<String, dynamic> toJSON() {
    var json = <String, dynamic>{
      'target': '#${targetStateNode.fullPathStateType.toString()}',
    };

    final dynamic condition = (this as dynamic).condition;
    if (condition != null) {
      json['cond'] = 'canTransition';
    }

    return json;
  }
}

extension on StateNodeDefinition {
  Map<String, dynamic> toJSON() {
    const mapType = {
      StateNodeType.terminal: 'final',
      StateNodeType.atomic: 'atomic',
      StateNodeType.compound: 'compound',
      StateNodeType.parallel: 'parallel',
    };

    var json = <String, dynamic>{
      'id': fullPathStateType.toString(),
      'type': mapType[stateNodeType],
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
      var on = {};
      var always = {};
      for (var transitions in eventTransitionsMap.values) {
        for (var transition in transitions) {
          if (transition.event == NullEvent) {
            always[transition.event.toString()] = transition.toJSON();
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
