import 'package:automata/automata.dart';
import 'package:automata/src/state_node.dart';
import 'package:automata/src/transition_definition.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'utils/watcher.dart';

void main() {
  group('least common compound ancestor', () {
    //        ┌───┐
    //     ┌──┤ 1 ├──┐
    //     │  └───┘  │
    //  ┌──▼─┐     ┌─▼──┐
    //  │ 11 │   ┌─┤ 12 ├─┐
    //  └────┘   │ └────┘ │
    //           │        │
    //        ┌──▼─┐    ┌─▼──┐
    //        │ 21 │  ┌─┤ 22 ├─┐
    //        └────┘  │ └────┘ │
    //                │        │
    //             ┌──▼─┐    ┌─▼──┐
    //             │ 31 │  ┌─┤ 32 ├─┐
    //             └────┘  │ └────┘ │
    //                     │        │
    //                  ┌──▼─┐    ┌─▼──┐
    //                  │ 41 │    │ 42 │
    //                  └────┘    └────┘
    test(
      'should be able to compute the lcca for different transtion scenarios',
      () {
        final rootNode = StateNodeDefinition<RootState>();
        final node1 = StateNodeDefinition<State1>(parentNode: rootNode);
        rootNode.childNodes = {State1: node1};

        final node11 = StateNodeDefinition<State11>(parentNode: node1);
        final node12 = StateNodeDefinition<State12>(parentNode: node1);
        node1.childNodes = {State11: node11, State12: node12};

        final node21 = StateNodeDefinition<State21>(parentNode: node12);
        final node22 = StateNodeDefinition<State22>(parentNode: node12);
        node12.childNodes = {State21: node21, State22: node22};

        final node31 = StateNodeDefinition<State31>(parentNode: node22);
        final node32 = StateNodeDefinition<State32>(parentNode: node22);
        node22.childNodes = {State31: node31, State32: node32};

        final node41 = StateNodeDefinition<State41>(parentNode: node32);
        final node42 = StateNodeDefinition<State42>(parentNode: node32);
        node32.childNodes = {State41: node41, State42: node42};

        expect(getLeastCommonCompoundAncestor(node21, node41), node12);
        expect(getLeastCommonCompoundAncestor(node41, node32), node22);
        expect(getLeastCommonCompoundAncestor(node41, node21), node12);
      },
    );
  });

// See example under 3.1.5 for the source of this test:
// https://www.w3.org/TR/scxml/#CoreIntroduction
  group('transition type', () {
    late Watcher watcher;

    setUpAll(() {
      registerFallbackValue(const OnEvent1());
      registerFallbackValue(State1);
    });

    setUp(() {
      watcher = MockWatcher();
    });

    StateMachine _createMachine<S extends AutomataState>({
      required TransitionType transitionType,
    }) {
      return StateMachine.create(
        (g) => g
          ..initial<State1>()
          ..state<State1>(
            builder: (b) => b
              ..initial<State11>()
              ..on<OnEvent1, State11>(type: transitionType)
              ..onEntry((context, event) {
                watcher.onEntry(State1, event);
              })
              ..onExit((context, event) {
                watcher.onExit(State1, event);
              })
              ..state<State11>(
                builder: (b) => b
                  ..onEntry((context, event) {
                    watcher.onEntry(State11, event);
                  })
                  ..onExit((context, event) {
                    watcher.onExit(State11, event);
                  }),
              ),
          ),
      );
    }

    test('should call appropriate onExit when its a internal transition', () {
      final machine = _createMachine(transitionType: TransitionType.internal);
      reset(watcher);

      const event = OnEvent1();
      machine.send(event);

      verify(() => watcher.onExit(State11, event)).called(1);
      verify(() => watcher.onEntry(State11, event)).called(1);

      verifyNever(() => watcher.onExit(State1, event));
      verifyNever(() => watcher.onEntry(State1, event));
    });

    test('should call appropriate onExit when its a external transition', () {
      final machine = _createMachine(transitionType: TransitionType.external);
      reset(watcher);

      const event = OnEvent1();
      machine.send(event);

      verify(() => watcher.onExit(State11, event)).called(1);
      verify(() => watcher.onEntry(State11, event)).called(1);

      verify(() => watcher.onExit(State1, event)).called(1);
      verify(() => watcher.onEntry(State1, event)).called(1);
    });
  });
}

@immutable
class OnEvent1 extends AutomataEvent {
  const OnEvent1();
}

class State1 extends AutomataState {}

class State2 extends AutomataState {}

class State11 extends AutomataState {}

class State12 extends AutomataState {}

class State21 extends AutomataState {}

class State22 extends AutomataState {}

class State31 extends AutomataState {}

class State32 extends AutomataState {}

class State41 extends AutomataState {}

class State42 extends AutomataState {}
