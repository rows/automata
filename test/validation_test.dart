import 'package:automata/src/exceptions.dart';
import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:automata/src/validators/extensions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockSrcCallbackFunction extends Mock {
  Future<void> call(AutomataEvent e);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const DoneInvokeEvent<void>(
        id: 'fetchUser',
        data: null,
      ),
    );
  });

  group('initial state', () {
    test('should have a reachable initial state', () {
      expect(
        () => StateMachine.create(
          (g) => g
            ..initial<_Other>()
            ..state<_StateA>()
            ..state<_StateB>(
              builder: (b) => b..state<_Other>(),
            )
            ..state<_StateC>(),
        ),
        throwsA(isA<UnreachableInitialStateException>()),
      );
    });
  });

  group('onDone callback', () {
    group('when in a atomic state node', () {
      test('should throw exception', () {
        final machine = StateMachine.create(
          (g) => g
            ..initial<_StateA>()
            ..state<_StateA>()
            ..state<_StateB>(
              builder: (b) => b..onDone(actions: [(_) {}]),
            )
            ..state<_StateC>(),
        );

        expect(
          machine.validate,
          throwsA(isA<InvalidOnDoneCallbackException>()),
        );
      });
    });

    group('when in a compound state node', () {
      test('should throw exception if there is no terminal substate', () {
        final machine = StateMachine.create(
          (g) => g
            ..initial<_StateA>()
            ..state<_StateA>(
              builder: (b) => b
                ..state<_StateB>()
                ..state<_StateC>()
                ..onDone(actions: [(_) {}]),
            ),
        );

        expect(
          machine.validate,
          throwsA(isA<InvalidOnDoneCallbackException>()),
        );
      });

      test('should not throw exception if has a terminal substate', () {
        final machine = StateMachine.create(
          (g) => g
            ..initial<_StateA>()
            ..state<_StateA>(
              builder: (b) => b
                ..state<_StateB>(type: StateNodeType.terminal)
                ..state<_StateC>()
                ..onDone(actions: [(_) {}]),
            ),
        );

        expect(
          machine.validate,
          returnsNormally,
        );
      });
    });

    group('when in a parallel state node', () {
      test(
        'should throw exception if any child does not have a terminal substate',
        () {
          final machine = StateMachine.create(
            (g) => g
              ..state<_StateA>(
                type: StateNodeType.parallel,
                builder: (b) => b
                  ..state<_StateC>(
                    builder: (b) => b
                      ..state<_StateD>(
                        type: StateNodeType.terminal,
                      ),
                  )
                  ..state<_StateB>(
                    builder: (b) => b..state<_StateE>(),
                  )
                  ..onDone(actions: [(_) {}]),
              ),
          );

          expect(
            machine.validate,
            throwsA(isA<InvalidOnDoneCallbackException>()),
          );
        },
      );

      test(
        'should not throw exception if all children have terminal substates',
        () {
          final machine = StateMachine.create(
            (g) => g
              ..state<_StateA>(
                type: StateNodeType.parallel,
                builder: (b) => b
                  ..state<_StateC>(
                    builder: (b) => b
                      ..state<_StateD>(
                        type: StateNodeType.terminal,
                      ),
                  )
                  ..state<_StateB>(
                    builder: (b) => b
                      ..state<_StateE>(
                        type: StateNodeType.terminal,
                      ),
                  )
                  ..onDone(actions: [(_) {}]),
              ),
          );

          expect(
            machine.validate,
            returnsNormally,
          );
        },
      );
    });

    group('when in a terminal state node', () {
      test('should not throw exception', () {
        final machine = StateMachine.create(
          (g) => g
            ..initial<_StateA>()
            ..state<_StateA>(
              type: StateNodeType.terminal,
              builder: (b) => b..onDone(actions: [(_) {}]),
            ),
        );

        expect(
          machine.validate,
          returnsNormally,
        );
      });
    });
  });

  group('unreachable transitions', () {
    test(
      'should throw an error if two conditionaless transitions '
      'for the same event are defined',
      () {
        final machine = StateMachine.create(
          (g) => g
            ..initial<_StateA>()
            ..state<_StateA>(
              builder: (b) => b
                ..on<_EventA, _StateB>()
                ..on<_EventA, _StateB>(),
            )
            ..state<_StateB>(),
        );

        expect(
          machine.validate,
          throwsA(isA<UnreachableTransitionException>()),
        );
      },
    );
  });

  group('atomic states', () {
    test('should throw if theres no atomic/terminal state', () {
      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..state<_StateB>(type: StateNodeType.parallel)
              ..state<_StateC>(type: StateNodeType.compound),
          ),
      );

      expect(
        machine.validate,
        throwsA(isA<NoAtomicStateNodeException>()),
      );
    });

    test('should not throw if there is a atomic node', () {
      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..state<_StateB>(type: StateNodeType.atomic)
              ..state<_StateC>(type: StateNodeType.parallel),
          ),
      );

      expect(
        machine.validate,
        returnsNormally,
      );
    });

    test('should not throw if there is a terminal node', () {
      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..state<_StateB>(type: StateNodeType.terminal)
              ..state<_StateC>(type: StateNodeType.parallel),
          ),
      );

      expect(
        machine.validate,
        returnsNormally,
      );
    });
  });

  group('invoke definition', () {
    test('should throw if invoke node is terminal', () {
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => null);

      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            type: StateNodeType.terminal,
            builder: (b) => b
              ..invoke<void>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onDone<_StateB, void>()
                  ..onError<_StateC>(),
              ),
          )
          ..state<_StateB>()
          ..state<_StateC>(),
      );

      expect(
        machine.validate,
        throwsA(isA<InvalidInvokeDefinitionException>()),
      );
    });

    test('should throw if no onDone definition is found', () {
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => null);

      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..invoke<void>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onError<_StateB>(),
              ),
          )
          ..state<_StateB>()
          ..state<_StateC>(),
      );

      expect(
        machine.validate,
        throwsA(isA<InvalidInvokeDefinitionException>()),
      );
    });

    test('should throw if no onError definition is found', () {
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => null);

      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..invoke<void>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onDone<_StateB, void>(),
              ),
          )
          ..state<_StateB>()
          ..state<_StateC>(),
      );

      expect(
        machine.validate,
        throwsA(isA<InvalidInvokeDefinitionException>()),
      );
    });

    test('should not throw if both onDone and onError are defined', () {
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => null);

      final machine = StateMachine.create(
        (g) => g
          ..initial<_StateA>()
          ..state<_StateA>(
            builder: (b) => b
              ..invoke<void>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onDone<_StateB, void>()
                  ..onError<_StateC>(),
              ),
          )
          ..state<_StateB>()
          ..state<_StateC>(),
      );

      expect(
        machine.validate,
        returnsNormally,
      );
    });
  });
}

class _Other extends AutomataState {}

class _StateA extends AutomataState {}

class _StateB extends AutomataState {}

class _StateC extends AutomataState {}

class _StateD extends AutomataState {}

class _StateE extends AutomataState {}

class _EventA extends AutomataEvent {}
