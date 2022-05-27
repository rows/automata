import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class _MockSrcCallbackFunction extends Mock {
  Future<_TestMockResult> call(AutomataEvent e);
}

class _MockOnDoneCallbackFunction extends Mock {
  void call(DoneInvokeEvent<_TestMockResult> e);
}

class _MockOnErrorCallbackFunction extends Mock {
  void call(ErrorEvent e);
}

class _MockEvent extends AutomataEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_MockEvent());
    registerFallbackValue(
      const DoneInvokeEvent<_TestMockResult>(
        id: 'fetchUser',
        data: _TestMockResult(value: 'placeholder'),
      ),
    );
  });

  group('with single onDone/onError transitions', () {
    StateMachine _createMachine<S extends AutomataState>({
      required InvokeSrcCallback<_TestMockResult> invokeSrcCallback,
      required _MockOnDoneCallbackFunction onDoneCallback,
      required _MockOnErrorCallbackFunction onErrorCallback,
    }) {
      return StateMachine.create(
        (g) => g
          ..initial<_Idle>()
          ..state<_Idle>(
            builder: (b) => b..on<_OnFetch, _Loading>(),
          )
          ..state<_Loading>(
            builder: (b) => b
              ..invoke<_TestMockResult>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onDone<_Success, _TestMockResult>(actions: [onDoneCallback])
                  ..onError<_Failure>(actions: [onErrorCallback]),
              ),
          )
          ..state<_Success>(type: StateNodeType.terminal)
          ..state<_Failure>(
            builder: (b) => b..on<_OnRetry, _Loading>(),
          ),
      );
    }

    test('should be able to resolve successfully', () async {
      const result = _TestMockResult(value: 'Something');
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => result);

      final onDoneCallback = _MockOnDoneCallbackFunction();
      final onErrorCallback = _MockOnErrorCallbackFunction();
      final machine = _createMachine(
        invokeSrcCallback: invokeSrcCallback,
        onDoneCallback: onDoneCallback,
        onErrorCallback: onErrorCallback,
      );
      machine.send(_OnFetch());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_Success), isTrue);

      verify(
        () => onDoneCallback(
          const DoneInvokeEvent(id: 'fetchUser', data: result),
        ),
      ).called(1);
    });

    test('should be able to move to error state', () async {
      final exception = Exception('Something went wrong');
      final invokeSrcCallback = _MockSrcCallbackFunction();

      when(() => invokeSrcCallback(any())).thenAnswer((_) async {
        throw exception;
      });

      final onDoneCallback = _MockOnDoneCallbackFunction();
      final onErrorCallback = _MockOnErrorCallbackFunction();
      final machine = _createMachine(
        invokeSrcCallback: invokeSrcCallback,
        onDoneCallback: onDoneCallback,
        onErrorCallback: onErrorCallback,
      );
      machine.send(_OnFetch());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_Failure), isTrue);

      verify(
        () => onErrorCallback(PlatformErrorEvent(exception: exception)),
      ).called(1);
    });

    test('should be able to retry', () async {
      final exception = Exception('Something went wrong');
      final invokeSrcCallback = _MockSrcCallbackFunction();

      when(() => invokeSrcCallback(any())).thenAnswer((_) async {
        throw exception;
      });

      final onDoneCallback = _MockOnDoneCallbackFunction();
      final onErrorCallback = _MockOnErrorCallbackFunction();
      final machine = _createMachine(
        invokeSrcCallback: invokeSrcCallback,
        onDoneCallback: onDoneCallback,
        onErrorCallback: onErrorCallback,
      );
      machine.send(_OnFetch());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_Failure), isTrue);
      verify(
        () => onErrorCallback(PlatformErrorEvent(exception: exception)),
      ).called(1);

      const result = _TestMockResult(value: 'Something');
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => result);

      machine.send(_OnRetry());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_Success), isTrue);

      verify(
        () => onDoneCallback(
          const DoneInvokeEvent(id: 'fetchUser', data: result),
        ),
      ).called(1);
    });
  });

  group('with multiple conditional transitions', () {
    StateMachine _createMachine<S extends AutomataState>({
      required InvokeSrcCallback<_TestMockResult> invokeSrcCallback,
      _MockOnDoneCallbackFunction? onDoneCallbackA,
      _MockOnDoneCallbackFunction? onDoneCallbackB,
      _MockOnErrorCallbackFunction? onErrorCallback,
    }) {
      return StateMachine.create(
        (g) => g
          ..initial<_Idle>()
          ..state<_Idle>(
            builder: (b) => b..on<_OnFetch, _Loading>(),
          )
          ..state<_Loading>(
            builder: (b) => b
              ..invoke<_TestMockResult>(
                builder: (b) => b
                  ..id('fetchUser')
                  ..src(invokeSrcCallback)
                  ..onDone<_Success, _TestMockResult>(
                    condition: ((event) => event.data.value == 'UseA'),
                    actions: [
                      onDoneCallbackA ?? _MockOnDoneCallbackFunction(),
                    ],
                  )
                  ..onDone<_SuccessB, _TestMockResult>(
                    condition: ((event) => event.data.value == 'UseB'),
                    actions: [
                      onDoneCallbackB ?? _MockOnDoneCallbackFunction(),
                    ],
                  )
                  ..onError<_Failure>(
                    actions: [
                      onErrorCallback ?? _MockOnErrorCallbackFunction(),
                    ],
                  ),
              ),
          )
          ..state<_Success>(type: StateNodeType.terminal)
          ..state<_SuccessB>(type: StateNodeType.terminal)
          ..state<_Failure>(
            builder: (b) => b..on<_OnRetry, _Loading>(),
          ),
      );
    }

    setUpAll(() {
      registerFallbackValue(_MockEvent());
      registerFallbackValue(
        const DoneInvokeEvent<_TestMockResult>(
          id: 'fetchUser',
          data: _TestMockResult(value: 'placeholder'),
        ),
      );
    });

    test('should transition to the first onDone', () async {
      const result = _TestMockResult(value: 'UseA');
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => result);

      final onDoneCallbackA = _MockOnDoneCallbackFunction();
      final onDoneCallbackB = _MockOnDoneCallbackFunction();

      final machine = _createMachine(
        invokeSrcCallback: invokeSrcCallback,
        onDoneCallbackA: onDoneCallbackA,
        onDoneCallbackB: onDoneCallbackB,
      );

      machine.send(_OnFetch());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_Success), isTrue);

      verify(
        () => onDoneCallbackA(
          const DoneInvokeEvent(id: 'fetchUser', data: result),
        ),
      ).called(1);
    });

    test('should transition to the second onDone', () async {
      const result = _TestMockResult(value: 'UseB');
      final invokeSrcCallback = _MockSrcCallbackFunction();
      when(() => invokeSrcCallback(any())).thenAnswer((_) async => result);

      final onDoneCallbackA = _MockOnDoneCallbackFunction();
      final onDoneCallbackB = _MockOnDoneCallbackFunction();

      final machine = _createMachine(
        invokeSrcCallback: invokeSrcCallback,
        onDoneCallbackA: onDoneCallbackA,
        onDoneCallbackB: onDoneCallbackB,
      );

      machine.send(_OnFetch());
      expect(machine.isInState(_Loading), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(machine.isInState(_SuccessB), isTrue);

      verify(
        () => onDoneCallbackB(
          const DoneInvokeEvent(id: 'fetchUser', data: result),
        ),
      ).called(1);
    });
  });
}

class _Idle extends AutomataState {}

class _Loading extends AutomataState {}

class _Failure extends AutomataState {}

class _Success extends AutomataState {}

class _SuccessB extends AutomataState {}

class _OnFetch extends AutomataEvent {}

class _OnRetry extends AutomataEvent {}

class _TestMockResult {
  final String value;

  const _TestMockResult({required this.value});
}
