# Automata

## Features
- Synchronous
- Declarative and type-based
- Compound states (nested states)
- Parallel states
- Guard conditions
- onEntry / onExit
- onTransition

## To do:
- Expose stream for changes.
- Support transitions with no event
  - If the 'event' attribute is missing, the transition is taken whenever the 'cond' evaluates to true.
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