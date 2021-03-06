import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'utils/watcher.dart';

void main() {
  late Watcher watcher;

  setUp(() {
    watcher = MockWatcher();
  });

  test('should set initial state to TypingText', () {
    final machine = _createMachine(watcher);

    expect(machine.isInState(TypingText), isTrue);
    expect(machine.isInState(TypingFormula), isFalse);
  });

  test(
    'should stay in TypingText if OnIsFormulaChange has isFormula as false',
    () {
      final machine = _createMachine(watcher);

      expect(machine.isInState(TypingText), isTrue);
      expect(machine.isInState(TypingFormula), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: false));

      expect(machine.isInState(TypingText), isTrue);
      expect(machine.isInState(TypingFormula), isFalse);
    },
  );

  test(
    'should move to TypingFormula if OnIsFormulaChange has isFormula as true',
    () {
      final machine = _createMachine(watcher);

      expect(machine.isInState(TypingText), isTrue);
      expect(machine.isInState(TypingFormula), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: true));

      expect(machine.isInState(TypingText), isFalse);
      expect(machine.isInState(TypingFormula), isTrue);
      expect(machine.isInState(Autocomplete), isTrue);
      expect(machine.isInState(AutocompleteUnavailable), isTrue);
      expect(machine.isInState(Point), isTrue);
      expect(machine.isInState(PointUnavailable), isTrue);
    },
  );

  test(
    'should keep autocomplete/point state when OnIsFormulaChange is fired as '
    'isFormula as true',
    () {
      final machine = _createMachine(watcher);

      machine.send(const OnIsFormulaChange(isFormula: true));
      expect(machine.isInState(TypingText), isFalse);
      expect(machine.isInState(TypingFormula), isTrue);
      expect(machine.isInState(Autocomplete), isTrue);
      expect(machine.isInState(AutocompleteUnavailable), isTrue);
      expect(machine.isInState(Point), isTrue);
      expect(machine.isInState(PointUnavailable), isTrue);

      machine.send(
        const OnCaretPositionChange(
          canTransitionToAutocompleteList: true,
          canTransitionToPointReference: true,
        ),
      );

      expect(machine.isInState(Autocomplete), isTrue);
      expect(machine.isInState(AutocompleteUnavailable), isFalse);
      expect(machine.isInState(AutocompleteList), isTrue);
      expect(machine.isInState(AutocompleteDetails), isFalse);
      expect(machine.isInState(PointReference), isTrue);
      expect(machine.isInState(PointReferenceDisabled), isTrue);
      expect(machine.isInState(PointSlot), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: true));

      expect(machine.isInState(Autocomplete), isTrue);
      expect(machine.isInState(AutocompleteUnavailable), isFalse);
      expect(machine.isInState(AutocompleteList), isTrue);
      expect(machine.isInState(AutocompleteDetails), isFalse);
      expect(machine.isInState(PointReference), isTrue);
      expect(machine.isInState(PointReferenceDisabled), isTrue);
      expect(machine.isInState(PointSlot), isFalse);
    },
  );

  test('should move between autocomplete states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToAutocompleteList: true),
    );

    expect(machine.isInState(Autocomplete), isTrue);
    expect(machine.isInState(AutocompleteUnavailable), isFalse);
    expect(machine.isInState(AutocompleteList), isTrue);
    expect(machine.isInState(AutocompleteDetails), isFalse);

    machine.send(
      const OnCaretPositionChange(canTransitionToAutocompleteDetails: true),
    );

    expect(machine.isInState(Autocomplete), isTrue);
    expect(machine.isInState(AutocompleteUnavailable), isFalse);
    expect(machine.isInState(AutocompleteList), isFalse);
    expect(machine.isInState(AutocompleteDetails), isTrue);

    machine.send(const OnCaretPositionChange());

    expect(machine.isInState(Autocomplete), isTrue);
    expect(machine.isInState(AutocompleteUnavailable), isTrue);
    expect(machine.isInState(AutocompleteList), isFalse);
    expect(machine.isInState(AutocompleteDetails), isFalse);
  });

  test('should move between point reference states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToPointReference: true),
    );

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointReference), isTrue);
    expect(machine.isInState(PointReferenceEnabled), isFalse);
    expect(machine.isInState(PointReferenceDisabled), isTrue);

    machine.send(const OnTogglePoint());

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointReference), isTrue);
    expect(machine.isInState(PointReferenceEnabled), isTrue);
    expect(machine.isInState(PointReferenceDisabled), isFalse);

    machine.send(const OnTogglePoint());

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointReference), isTrue);
    expect(machine.isInState(PointReferenceEnabled), isFalse);
    expect(machine.isInState(PointReferenceDisabled), isTrue);
  });

  test('should move between point slot states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToPointSlot: true),
    );

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointSlot), isTrue);
    expect(machine.isInState(PointSlotEnabled), isTrue);
    expect(machine.isInState(PointSlotDisabled), isFalse);

    machine.send(const OnTogglePoint());

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointSlot), isTrue);
    expect(machine.isInState(PointSlotEnabled), isFalse);
    expect(machine.isInState(PointSlotDisabled), isTrue);

    machine.send(const OnTogglePoint());

    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(PointSlot), isTrue);
    expect(machine.isInState(PointSlotEnabled), isTrue);
    expect(machine.isInState(PointSlotDisabled), isFalse);
  });

  test('should be able to move back to TypingText', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToAutocompleteList: true),
    );

    expect(machine.isInState(TypingText), isFalse);
    expect(machine.isInState(TypingFormula), isTrue);
    expect(machine.isInState(Point), isTrue);
    expect(machine.isInState(Autocomplete), isTrue);
    expect(machine.isInState(AutocompleteList), isTrue);
    reset(watcher);

    const event = OnIsFormulaChange(isFormula: false);
    machine.send(event);

    expect(machine.isInState(TypingText), isTrue);
    expect(machine.isInState(TypingFormula), isFalse);
    expect(machine.isInState(Point), isFalse);
    expect(machine.isInState(Autocomplete), isFalse);
    expect(machine.isInState(AutocompleteList), isFalse);
    expect(machine.isInState(AutocompleteUnavailable), isFalse);

    verify(() => watcher.onExit(Autocomplete, event)).called(1);
  });
}

/// Creates a [StateMachine] to keep track of autocomplete and P&C states on
/// the currently formula being composed.
StateMachine _createMachine(Watcher watcher) {
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
              ..onExit((event) => watcher.onExit(Autocomplete, event))

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
                  ..always<AutocompleteList>(
                    actions: [
                      (event) => watcher.onAlways(AutocompleteList, event),
                    ],
                  ),
              )
              ..state<AutocompleteDetails>(
                builder: (b) => b
                  ..on<OnResetInteraction, AutocompleteUnavailable>()
                  ..always<AutocompleteDetails>(
                    actions: [
                      (event) => watcher.onAlways(AutocompleteDetails, event),
                    ],
                  ),
              )
              ..state<AutocompleteUnavailable>(
                builder: (b) => b
                  ..onEntry(
                    (event) => watcher.onEntry(AutocompleteUnavailable, event),
                  ),
              ),
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
  );

  return machine;
}

class TypingText implements AutomataState {}

class TypingFormula implements AutomataState {}

class Autocomplete implements AutomataState {}

class AutocompleteUnavailable implements AutomataState {}

class AutocompleteList implements AutomataState {}

class AutocompleteDetails implements AutomataState {}

class Point implements AutomataState {}

class PointUnavailable implements AutomataState {}

class PointSlot implements AutomataState {}

class PointSlotEnabled implements AutomataState {}

class PointSlotDisabled implements AutomataState {}

class PointReference implements AutomataState {}

class PointReferenceDisabled implements AutomataState {}

class PointReferenceEnabled implements AutomataState {}

class OnIsFormulaChange implements AutomataEvent {
  final bool isFormula;
  const OnIsFormulaChange({required this.isFormula});
}

class OnTogglePoint implements AutomataEvent {
  const OnTogglePoint();
}

class OnDisablePoint implements AutomataEvent {}

class OnCaretPositionChange implements AutomataEvent {
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

class OnResetInteraction implements AutomataEvent {
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
