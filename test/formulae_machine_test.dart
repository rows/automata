import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:state_machine/src/state_machine.dart';
import 'package:state_machine/src/state_node.dart';
import 'package:state_machine/src/types.dart';

class Watcher {
  void onEnter(Event? e) {}
  void onExit(Event? e) {}
}

class _MockWatcher extends Mock implements Watcher {}

void main() {
  late Watcher watcher;

  setUp(() {
    watcher = _MockWatcher();
  });

  test('should set initial state to TypingText', () {
    final machine = _createMachine(watcher);

    expect(machine.isInState<TypingText>(), isTrue);
    expect(machine.isInState<TypingFormula>(), isFalse);
  });

  test(
    'should stay in TypingText if OnIsFormulaChange has isFormula as false',
    () {
      final machine = _createMachine(watcher);

      expect(machine.isInState<TypingText>(), isTrue);
      expect(machine.isInState<TypingFormula>(), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: false));

      expect(machine.isInState<TypingText>(), isTrue);
      expect(machine.isInState<TypingFormula>(), isFalse);
    },
  );

  test(
    'should move to TypingFormula if OnIsFormulaChange has isFormula as true',
    () {
      final machine = _createMachine(watcher);

      expect(machine.isInState<TypingText>(), isTrue);
      expect(machine.isInState<TypingFormula>(), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: true));

      expect(machine.isInState<TypingText>(), isFalse);
      expect(machine.isInState<TypingFormula>(), isTrue);
      expect(machine.isInState<Autocomplete>(), isTrue);
      expect(machine.isInState<AutocompleteUnavailable>(), isTrue);
      expect(machine.isInState<Point>(), isTrue);
      expect(machine.isInState<PointUnavailable>(), isTrue);
    },
  );

  test(
    'should keep autocomplete/point state when OnIsFormulaChange is fired as '
    'isFormula as true',
    () {
      final machine = _createMachine(watcher);

      machine.send(const OnIsFormulaChange(isFormula: true));
      expect(machine.isInState<TypingText>(), isFalse);
      expect(machine.isInState<TypingFormula>(), isTrue);
      expect(machine.isInState<Autocomplete>(), isTrue);
      expect(machine.isInState<AutocompleteUnavailable>(), isTrue);
      expect(machine.isInState<Point>(), isTrue);
      expect(machine.isInState<PointUnavailable>(), isTrue);

      machine.send(
        const OnCaretPositionChange(
          canTransitionToAutocompleteList: true,
          canTransitionToPointReference: true,
        ),
      );

      expect(machine.isInState<Autocomplete>(), isTrue);
      expect(machine.isInState<AutocompleteUnavailable>(), isFalse);
      expect(machine.isInState<AutocompleteList>(), isTrue);
      expect(machine.isInState<AutocompleteDetails>(), isFalse);
      expect(machine.isInState<PointReference>(), isTrue);
      expect(machine.isInState<PointReferenceDisabled>(), isTrue);
      expect(machine.isInState<PointSlot>(), isFalse);

      machine.send(const OnIsFormulaChange(isFormula: true));

      expect(machine.isInState<Autocomplete>(), isTrue);
      expect(machine.isInState<AutocompleteUnavailable>(), isFalse);
      expect(machine.isInState<AutocompleteList>(), isTrue);
      expect(machine.isInState<AutocompleteDetails>(), isFalse);
      expect(machine.isInState<PointReference>(), isTrue);
      expect(machine.isInState<PointReferenceDisabled>(), isTrue);
      expect(machine.isInState<PointSlot>(), isFalse);
    },
  );

  test('should move between autocomplete states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToAutocompleteList: true),
    );

    expect(machine.isInState<Autocomplete>(), isTrue);
    expect(machine.isInState<AutocompleteUnavailable>(), isFalse);
    expect(machine.isInState<AutocompleteList>(), isTrue);
    expect(machine.isInState<AutocompleteDetails>(), isFalse);

    machine.send(
      const OnCaretPositionChange(canTransitionToAutocompleteDetails: true),
    );

    expect(machine.isInState<Autocomplete>(), isTrue);
    expect(machine.isInState<AutocompleteUnavailable>(), isFalse);
    expect(machine.isInState<AutocompleteList>(), isFalse);
    expect(machine.isInState<AutocompleteDetails>(), isTrue);

    machine.send(const OnCaretPositionChange());

    expect(machine.isInState<Autocomplete>(), isTrue);
    expect(machine.isInState<AutocompleteUnavailable>(), isTrue);
    expect(machine.isInState<AutocompleteList>(), isFalse);
    expect(machine.isInState<AutocompleteDetails>(), isFalse);
  });

  test('should move between point reference states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToPointReference: true),
    );

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointReference>(), isTrue);
    expect(machine.isInState<PointReferenceEnabled>(), isFalse);
    expect(machine.isInState<PointReferenceDisabled>(), isTrue);

    machine.send(const OnTogglePoint());

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointReference>(), isTrue);
    expect(machine.isInState<PointReferenceEnabled>(), isTrue);
    expect(machine.isInState<PointReferenceDisabled>(), isFalse);

    machine.send(const OnTogglePoint());

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointReference>(), isTrue);
    expect(machine.isInState<PointReferenceEnabled>(), isFalse);
    expect(machine.isInState<PointReferenceDisabled>(), isTrue);
  });

  test('should move between point slot states', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToPointSlot: true),
    );

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointSlot>(), isTrue);
    expect(machine.isInState<PointSlotEnabled>(), isTrue);
    expect(machine.isInState<PointSlotDisabled>(), isFalse);

    machine.send(const OnTogglePoint());

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointSlot>(), isTrue);
    expect(machine.isInState<PointSlotEnabled>(), isFalse);
    expect(machine.isInState<PointSlotDisabled>(), isTrue);

    machine.send(const OnTogglePoint());

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointSlot>(), isTrue);
    expect(machine.isInState<PointSlotEnabled>(), isTrue);
    expect(machine.isInState<PointSlotDisabled>(), isFalse);
  });

  test('should be able to move back to TypingText', () {
    final machine = _createMachine(watcher);

    machine.send(const OnIsFormulaChange(isFormula: true));
    machine.send(
      const OnCaretPositionChange(canTransitionToPointReference: true),
    );

    expect(machine.isInState<Point>(), isTrue);
    expect(machine.isInState<PointReference>(), isTrue);
    expect(machine.isInState<PointReferenceDisabled>(), isTrue);

    machine.send(const OnIsFormulaChange(isFormula: false));

    expect(machine.isInState<TypingText>(), isTrue);
    expect(machine.isInState<TypingFormula>(), isFalse);
    expect(machine.isInState<Point>(), isFalse);
    expect(machine.isInState<PointReference>(), isFalse);
    expect(machine.isInState<PointReferenceDisabled>(), isFalse);
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
          ..on<OnIsFormulaChange, TypingFormula>(
            condition: (e) => e.isFormula,
          ),
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
              ..state<AutocompleteList>(builder: (b) => b)
              ..state<AutocompleteDetails>(builder: (b) => b)
              ..state<AutocompleteUnavailable>(builder: (b) => b),
          )

          // Point mode state-mahcine
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
