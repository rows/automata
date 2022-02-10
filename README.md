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
- Support transitions with no event
  - If the 'event' attribute is missing, the transition is taken whenever the 'cond' evaluates to true.
- Wait for async actions (? TBC)
- Create validations for invalid statemachines (eg. parallel state machine with a single substate)
- Final states should raise a internal event OnDone and the user should be able to provide a onDoneCallback to listen for this.
  - check xstate: https://xstate.js.org/docs/guides/final.html#api

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
  onTransition: (source, event, target) => print('$source $event $target'),
);

machine.send(OnMelted());
```