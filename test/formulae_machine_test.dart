import 'package:state_machine/src/state_machine.dart';
import 'package:state_machine/src/types.dart';

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

class OnTogglePoint implements Event {}

class OnDisablePoint implements Event {}

class OnCaretPositionChange implements Event {}

bool canTransitionToAutocompleteList(OnCaretPositionChange e) {
  return true;
}

bool canTransitionToAutocompleteDetails(OnCaretPositionChange e) {
  return true;
}

bool canTransitionToPointReference(OnCaretPositionChange e) {
  return true;
}

bool canTransitionToPointSlot(OnCaretPositionChange e) {
  return true;
}

/// Creates a [StateMachine] to keep track of autocomplete and P&C states on
/// the currently formula being composed.
StateMachine createStateMachine() {
  final machine = StateMachine.create(
    (g) => g
      ..initialState<TypingText>()
      ..state<TypingText>(
        (b) => b
          // When value changes it forks into the two parallel state machines
          ..onFork<OnIsFormulaChange>(
            (b) => b
              // TODO: fix with initial state
              ..target<PointUnavailable>()
              // TODO: fix with initial state
              ..target<AutocompleteUnavailable>(),
            condition: (e) => e.isFormula,
          ),
      )

      /// TypingFormula is a pseudo-state, it forks into two parallel
      /// state machines, one to control the [Point] mode and other to control
      /// the [Autocomplete] state
      ..coregion<TypingFormula>(
        (b) => b
          ..on<OnIsFormulaChange, TypingText>(condition: (e) => !e.isFormula)

          // Autocomplete state machine
          ..state<Autocomplete>(
            (b) => b
              ..initialState<AutocompleteUnavailable>()

              // Autocomplete events
              ..on<OnCaretPositionChange, AutocompleteList>(
                condition: canTransitionToAutocompleteList,
              )
              ..on<OnCaretPositionChange, AutocompleteDetails>(
                condition: canTransitionToAutocompleteDetails,
              )
              ..on<OnCaretPositionChange, AutocompleteUnavailable>()

              // Autocomplete states
              ..state<AutocompleteList>((b) => b)
              ..state<AutocompleteDetails>((b) => b)
              ..state<AutocompleteUnavailable>((b) => b),
          )

          // Point mode state-mahcine
          ..state<Point>(
            (b) => b
              ..initialState<PointUnavailable>()

              // Point mode states
              ..state<PointUnavailable>(
                (b) => b
                  // TODO: fix with initial state
                  ..on<OnCaretPositionChange, PointReferenceDisabled>(
                    condition: canTransitionToPointReference,
                  )
                  // TODO: fix with initial state
                  ..on<OnCaretPositionChange, PointSlotEnabled>(
                    condition: canTransitionToPointSlot,
                  ),
              )
              ..state<PointSlot>(
                (b) => b
                  ..initialState<PointSlotEnabled>()
                  ..state<PointSlotEnabled>(
                    (b) => b
                      ..on<OnTogglePoint, PointSlotDisabled>()
                      ..on<OnDisablePoint, PointSlotDisabled>()
                      // TODO: fix with initial state
                      ..on<OnCaretPositionChange, PointReferenceEnabled>(
                        condition: canTransitionToPointReference,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointSlot(e),
                      ),
                  )
                  ..state<PointSlotDisabled>(
                    (b) => b
                      ..on<OnTogglePoint, PointSlotEnabled>()
                      // TODO: fix with initial state
                      ..on<OnCaretPositionChange, PointReferenceDisabled>(
                        condition: canTransitionToPointReference,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointSlot(e),
                      ),
                  ),
              )
              ..state<PointReference>(
                (b) => b
                  ..initialState<PointReferenceDisabled>()
                  ..state<PointReferenceEnabled>(
                    (b) => b
                      ..on<OnTogglePoint, PointReferenceDisabled>()
                      ..on<OnDisablePoint, PointReferenceDisabled>()
                      // TODO: fix with initial state
                      ..on<OnCaretPositionChange, PointSlotEnabled>(
                        condition: canTransitionToPointSlot,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointReference(e),
                      ),
                  )
                  ..state<PointReferenceDisabled>(
                    (b) => b
                      ..on<OnTogglePoint, PointReferenceEnabled>()
                      // TODO: fix with initial state
                      ..on<OnCaretPositionChange, PointSlotEnabled>(
                        condition: canTransitionToPointSlot,
                      )
                      ..on<OnCaretPositionChange, PointUnavailable>(
                        condition: (e) => !canTransitionToPointReference(e),
                      ),
                  ),
              ),
          ),
      ),
  );

  return machine;
}
