# Automata

## Features
- Synchronous
- Declarative and type-based
- Nested states
- Parallel states
- Guard conditions
- onEntry / onExit
- onTransition

## To do:
- Add example
- Drop flutter deps
- Final state nodes
- Wait for async actions (? TBC)
- Create validations for invalid statemachines (eg. parallel state machine with a single substate)

## Usage:
```dart
final machine = StateMachine.create(
  (g) => g
    ..initial<Start>()
    ..state<Start>(builder: (g) => g..on<OnKickStart, Main>())
    ..state<Main>(
      type: StateNodeType.parallel,
      builder: (g) => g
        ..on<OnTickFirst, First>()
        ..on<OnTickSecond, Second>()
        ..state<First>(
          builder: (g) => g
            ..initial<One>()
            ..state<One>(builder: (g) => g..on<OnToggle, Two>())
            ..state<Two>(builder: (g) => g..on<OnToggle, One>()),
        )
        ..state<Second>(
          builder: (g) => g
            ..initial<Three>()
            ..state<Three>(builder: (g) => g..on<OnToggle, Four>())
            ..state<Four>(builder: (g) => g..on<OnToggle, Three>()),
        ),
    ),
  onTransition: (from, event, to) => print('$from $event $to'),
);

machine.send(OnMelted());
```