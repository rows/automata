import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  test(
    'should emit the "done" events when a compound enters final state, and '
    'when all sub-states of a parallel machine enter final state',
    () async {
      final actions = _MockStateMachineActions();
      final finalMachine = _createMachine(actions);
      finalMachine.send(_OnTimer());
      expect(finalMachine.isInState(_Yellow), isTrue);

      finalMachine.send(_OnTimer());
      expect(finalMachine.isInState(_Red), isTrue);
      expect(finalMachine.isInState(_Crosswalk1), isTrue);
      expect(finalMachine.isInState(_Crosswalk2), isTrue);

      expect(finalMachine.matchesStatePath([_Crosswalk1, _Walk]), isTrue);
      expect(finalMachine.matchesStatePath([_Crosswalk2, _Walk]), isTrue);

      finalMachine.send(_OnPedWait());

      expect(finalMachine.matchesStatePath([_Crosswalk1, _Wait]), isTrue);
      expect(finalMachine.matchesStatePath([_Crosswalk2, _Wait]), isTrue);

      finalMachine.send(_OnPedStop());

      expect(finalMachine.matchesStatePath([_Crosswalk1, _Stop]), isTrue);
      expect(finalMachine.matchesStatePath([_Crosswalk2, _Stop]), isTrue);
      verify(actions.stopCrosswalk1).called(1);

      finalMachine.send(_OnPedStop());

      expect(finalMachine.matchesStatePath([_Crosswalk1, _Stop]), isTrue);
      expect(finalMachine.matchesStatePath([_Crosswalk2, _Stop2]), isTrue);

      verify(actions.stopCrosswalk2).called(1);
      verify(actions.prepareGreenLight).called(1);
      verifyNever(actions.shouldNeverOccur);
    },
  );
}

class _StateMachineActions {
  void stopCrosswalk1() {}
  void stopCrosswalk2() {}
  void prepareGreenLight() {}
  void shouldNeverOccur() {}
}

class _MockStateMachineActions extends Mock implements _StateMachineActions {}

class _Green extends AutomataState {}

class _Yellow extends AutomataState {}

class _Red extends AutomataState {}

class _Crosswalk1 extends AutomataState {}

class _Walk extends AutomataState {}

class _Wait extends AutomataState {}

class _Stop extends AutomataState {}

class _Stop2 extends AutomataState {}

class _Crosswalk2 extends AutomataState {}

class _OnTimer extends AutomataEvent {}

class _OnPedWait extends AutomataEvent {}

class _OnPedStop extends AutomataEvent {}

StateMachine _createMachine(_StateMachineActions actions) {
  return StateMachine.create(
    (g) => g
      ..initial<_Green>()
      ..state<_Green>(
        builder: (b) => b..on<_OnTimer, _Yellow>(),
      )
      ..state<_Yellow>(
        builder: (b) => b..on<_OnTimer, _Red>(),
      )
      ..state<_Red>(
        type: StateNodeType.parallel,
        builder: (b) => b
          ..state<_Crosswalk1>(
            builder: (b) => b
              ..initial<_Walk>()
              ..state<_Walk>(
                builder: (b) => b..on<_OnPedWait, _Wait>(),
              )
              ..state<_Wait>(
                builder: (b) => b..on<_OnPedStop, _Stop>(),
              )
              ..state<_Stop>(
                type: StateNodeType.terminal,
              )
              ..onDone(
                actions: [(_) => actions.stopCrosswalk1()],
              ),
          )
          ..state<_Crosswalk2>(
            builder: (b) => b
              ..initial<_Walk>()
              ..state<_Walk>(
                builder: (b) => b..on<_OnPedWait, _Wait>(),
              )
              ..state<_Wait>(
                builder: (b) => b..on<_OnPedStop, _Stop>(),
              )
              ..state<_Stop>(
                builder: (b) => b..on<_OnPedStop, _Stop2>(),
              )
              ..state<_Stop2>(
                type: StateNodeType.terminal,
              )
              ..onDone(
                actions: [(_) => actions.stopCrosswalk2()],
              ),
          )
          ..onDone(
            actions: [(_) => actions.prepareGreenLight()],
          ),
      )
      // this action should never occur because final states are not direct
      // children of machine
      ..onDone(
        actions: [(_) => actions.shouldNeverOccur()],
      ),
  );
}
