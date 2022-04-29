import 'package:automata/automata.dart';
import 'package:test/test.dart';

void main() {
  test('should output a string with a XState machine', () async {
    final machine = _createMachine();

    /// To be really sure that this is working properly, print the result
    /// and paste it into the stately's vizualizer: https://stately.ai/viz
    final result = await exportToXStateViz(machine, writeToFile: false);

    final cleanupRegex = RegExp('\n| |\t');
    expect(
      result.replaceAll(cleanupRegex, ''),
      expectedSnapshot.replaceAll(cleanupRegex, ''),
    );
  });
}

const expectedSnapshot = '''
import { createMachine } from "xstate";

const machine = createMachine(
  {
  "id": "test_machine",
  "type": "compound",
  "initial": "TypingText",
  "states": {
    "TypingText": {
      "id": "{RootState, TypingText}",
      "type": "atomic",
      "on": {
        "OnIsFormulaChange": {
          "target": "#{RootState, TypingFormula}",
          "cond": "canTransition"
        }
      }
    },
    "TypingFormula": {
      "id": "{RootState, TypingFormula}",
      "type": "parallel",
      "states": {
        "Autocomplete": {
          "id": "{RootState, TypingFormula, Autocomplete}",
          "type": "compound",
          "initial": "AutocompleteUnavailable",
          "states": {
            "AutocompleteList": {
              "id": "{RootState, TypingFormula, Autocomplete, AutocompleteList}",
              "type": "atomic",
              "on": {
                "OnResetInteraction": {
                  "target": "#{RootState, TypingFormula, Autocomplete, AutocompleteUnavailable}"
                }
              },
              "always": [
                {
                  "target": "#{RootState, TypingFormula, Autocomplete, AutocompleteList}"
                }
              ]
            },
            "AutocompleteDetails": {
              "id": "{RootState, TypingFormula, Autocomplete, AutocompleteDetails}",
              "type": "atomic",
              "on": {
                "OnResetInteraction": {
                  "target": "#{RootState, TypingFormula, Autocomplete, AutocompleteUnavailable}"
                }
              },
              "always": [
                {
                  "target": "#{RootState, TypingFormula, Autocomplete, AutocompleteDetails}"
                }
              ]
            },
            "AutocompleteUnavailable": {
              "id": "{RootState, TypingFormula, Autocomplete, AutocompleteUnavailable}",
              "type": "atomic"
            }
          },
          "on": {
            "OnCaretPositionChange": {
              "target": "#{RootState, TypingFormula, Autocomplete, AutocompleteUnavailable}"
            }
          }
        },
        "Point": {
          "id": "{RootState, TypingFormula, Point}",
          "type": "compound",
          "initial": "PointUnavailable",
          "states": {
            "PointUnavailable": {
              "id": "{RootState, TypingFormula, Point, PointUnavailable}",
              "type": "atomic",
              "on": {
                "OnCaretPositionChange": {
                  "target": "#{RootState, TypingFormula, Point, PointSlot}",
                  "cond": "canTransition"
                }
              }
            },
            "PointSlot": {
              "id": "{RootState, TypingFormula, Point, PointSlot}",
              "type": "compound",
              "initial": "PointSlotEnabled",
              "states": {
                "PointSlotEnabled": {
                  "id": "{RootState, TypingFormula, Point, PointSlot, PointSlotEnabled}",
                  "type": "atomic",
                  "on": {
                    "OnResetInteraction": {
                      "target": "#{RootState, TypingFormula, Point, PointSlot, PointSlotDisabled}"
                    },
                    "OnTogglePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointSlot, PointSlotDisabled}"
                    },
                    "OnDisablePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointSlot, PointSlotDisabled}"
                    },
                    "OnCaretPositionChange": {
                      "target": "#{RootState, TypingFormula, Point, PointUnavailable}",
                      "cond": "canTransition"
                    }
                  }
                },
                "PointSlotDisabled": {
                  "id": "{RootState, TypingFormula, Point, PointSlot, PointSlotDisabled}",
                  "type": "atomic",
                  "on": {
                    "OnTogglePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointSlot, PointSlotEnabled}"
                    },
                    "OnCaretPositionChange": {
                      "target": "#{RootState, TypingFormula, Point, PointUnavailable}",
                      "cond": "canTransition"
                    }
                  }
                }
              }
            },
            "PointReference": {
              "id": "{RootState, TypingFormula, Point, PointReference}",
              "type": "compound",
              "initial": "PointReferenceDisabled",
              "states": {
                "PointReferenceEnabled": {
                  "id": "{RootState, TypingFormula, Point, PointReference, PointReferenceEnabled}",
                  "type": "atomic",
                  "on": {
                    "OnResetInteraction": {
                      "target": "#{RootState, TypingFormula, Point, PointReference, PointReferenceDisabled}"
                    },
                    "OnTogglePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointReference, PointReferenceDisabled}"
                    },
                    "OnDisablePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointReference, PointReferenceDisabled}"
                    },
                    "OnCaretPositionChange": {
                      "target": "#{RootState, TypingFormula, Point, PointUnavailable}",
                      "cond": "canTransition"
                    }
                  }
                },
                "PointReferenceDisabled": {
                  "id": "{RootState, TypingFormula, Point, PointReference, PointReferenceDisabled}",
                  "type": "atomic",
                  "on": {
                    "OnTogglePoint": {
                      "target": "#{RootState, TypingFormula, Point, PointReference, PointReferenceEnabled}"
                    },
                    "OnCaretPositionChange": {
                      "target": "#{RootState, TypingFormula, Point, PointUnavailable}",
                      "cond": "canTransition"
                    }
                  }
                }
              }
            }
          }
        }
      },
      "on": {
        "OnIsFormulaChange": {
          "target": "#{RootState, TypingText}",
          "cond": "canTransition"
        }
      }
    }
  }
},
  {
    guards: {
      canTransition: () => true,
    }
  }
);
''';

/// Creates a [StateMachine] to keep track of autocomplete and P&C states on
/// the currently formula being composed.
StateMachine _createMachine() {
  final machine = StateMachine.create(
    (g) => g
      ..initial<TypingText>()
      ..state<TypingText>(
        builder: (b) => b
          // When value changes it forks into the two parallel state machines
          ..on<OnIsFormulaChange, TypingFormula>(condition: (e) => e.isFormula),
      )

      /// TypingFormula is a pseudo-state, it forks into two parallel
      /// state machines, one to control the [Point] mode and other to control
      /// the [Autocomplete] state
      ..state<TypingFormula>(
        type: StateNodeType.parallel,
        builder: (b) => b
          ..on<OnIsFormulaChange, TypingText>(condition: (e) => !e.isFormula)

          // Autocomplete state machine
          ..state<Autocomplete>(
            builder: (b) => b
              ..initial<AutocompleteUnavailable>()

              // Autocomplete events
              ..on<OnCaretPositionChange, AutocompleteList>(
                condition: canTransitionToAutocompleteList,
              )
              ..on<OnCaretPositionChange, AutocompleteDetails>(
                condition: canTransitionToAutocompleteDetails,
              )
              ..on<OnCaretPositionChange, AutocompleteUnavailable>()

              // Autocomplete states
              ..state<AutocompleteList>(
                builder: (b) => b
                  ..on<OnResetInteraction, AutocompleteUnavailable>()
                  ..always<AutocompleteList>(actions: [(event) {}]),
              )
              ..state<AutocompleteDetails>(
                builder: (b) => b
                  ..on<OnResetInteraction, AutocompleteUnavailable>()
                  ..always<AutocompleteDetails>(actions: [(event) {}]),
              )
              ..state<AutocompleteUnavailable>(),
          )

          // Point mode state-machine
          ..state<Point>(
            builder: (b) => b
              ..initial<PointUnavailable>()

              // Point mode states
              ..state<PointUnavailable>(
                builder: (b) => b
                  ..on<OnCaretPositionChange, PointReference>(
                    condition: canTransitionToPointReference,
                  )
                  ..on<OnCaretPositionChange, PointSlot>(
                    condition: canTransitionToPointSlot,
                  ),
              )
              ..state<PointSlot>(
                builder: (b) => b
                  ..initial<PointSlotEnabled>()
                  ..state<PointSlotEnabled>(
                    builder: (b) => b
                      ..on<OnResetInteraction, PointSlotDisabled>()
                      ..on<OnTogglePoint, PointSlotDisabled>()
                      ..on<OnDisablePoint, PointSlotDisabled>()
                      ..on<OnCaretPositionChange, PointReferenceEnabled>(
                        condition: canTransitionToPointReference,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointSlot(e),
                      ),
                  )
                  ..state<PointSlotDisabled>(
                    builder: (b) => b
                      ..on<OnTogglePoint, PointSlotEnabled>()
                      ..on<OnCaretPositionChange, PointReference>(
                        condition: canTransitionToPointReference,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointSlot(e),
                      ),
                  ),
              )
              ..state<PointReference>(
                builder: (b) => b
                  ..initial<PointReferenceDisabled>()
                  ..state<PointReferenceEnabled>(
                    builder: (b) => b
                      ..on<OnResetInteraction, PointReferenceDisabled>()
                      ..on<OnTogglePoint, PointReferenceDisabled>()
                      ..on<OnDisablePoint, PointReferenceDisabled>()
                      ..on<OnCaretPositionChange, PointSlot>(
                        condition: canTransitionToPointSlot,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointReference(e),
                      ),
                  )
                  ..state<PointReferenceDisabled>(
                    builder: (b) => b
                      ..on<OnTogglePoint, PointReferenceEnabled>()
                      ..on<OnCaretPositionChange, PointSlot>(
                        condition: canTransitionToPointSlot,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointReference(e),
                      ),
                  ),
              ),
          ),
      ),
    id: 'test_machine',
  );

  return machine;
}

class TypingText implements State {}

class TypingFormula implements State {}

class Autocomplete implements State {}

class AutocompleteUnavailable implements State {}

class AutocompleteList implements State {}

class AutocompleteDetails implements State {}

class Point implements State {}

class PointUnavailable implements State {}

class PointSlot implements State {}

class PointSlotEnabled implements State {}

class PointSlotDisabled implements State {}

class PointReference implements State {}

class PointReferenceDisabled implements State {}

class PointReferenceEnabled implements State {}

class OnIsFormulaChange implements Event {
  final bool isFormula;
  const OnIsFormulaChange({required this.isFormula});
}

class OnTogglePoint implements Event {
  const OnTogglePoint();
}

class OnDisablePoint implements Event {}

class OnCaretPositionChange implements Event {
  final bool canTransitionToAutocompleteList;
  final bool canTransitionToAutocompleteDetails;
  final bool canTransitionToPointReference;
  final bool canTransitionToPointSlot;

  const OnCaretPositionChange({
    this.canTransitionToAutocompleteList = false,
    this.canTransitionToAutocompleteDetails = false,
    this.canTransitionToPointReference = false,
    this.canTransitionToPointSlot = false,
  });
}

class OnResetInteraction implements Event {
  const OnResetInteraction();
}

bool canTransitionToAutocompleteList(OnCaretPositionChange e) {
  return e.canTransitionToAutocompleteList;
}

bool canTransitionToAutocompleteDetails(OnCaretPositionChange e) {
  return e.canTransitionToAutocompleteDetails;
}

bool canTransitionToPointReference(OnCaretPositionChange e) {
  return e.canTransitionToPointReference;
}

bool canTransitionToPointSlot(OnCaretPositionChange e) {
  return e.canTransitionToPointSlot;
}
