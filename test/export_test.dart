import 'package:automata/automata.dart';
import 'package:test/test.dart';

void main() {
  test('should output a string with a XState machine', () async {
    final machine = _createMachine();
    final result = await exportToXStateViz(machine, writeToFile: false);

    /// To be really sure that this is working properly, print the result
    /// and paste it into the stately's vizualizer: https://stately.ai/viz
    expect(result.isNotEmpty, isTrue);
  });
}

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
