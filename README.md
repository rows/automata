# State Machine & State Charts

## Features

- Synchronous
- Declarative and Type-based
- Supports nested states
- Supports co-regions
- Guard conditions
- onEnter / onExit
- onTransition
- Support initial states

```dart
final machine = StateMachine.create(
  (g) => g
    ..initialState<Solid>()
    ..state<Solid>(
      (b) => b
        ..on<OnMelted, Liquid>(
          actions: [
            (e) => print('sideeffect_1'),
            (e) => print('sideeffect_2'),
          ],
          condition: (event) => enabled,
        ),
    )
    ..state<Liquid>(
      (b) => b
        ..onEnter((s, e) => print('Entering ${s.runtimeType} State'))
        ..onExit((s, e) => print('Exiting ${s.runtimeType} State'))
        ..on<OnFroze, Solid>(actions: [(e) => print('Frozen')])
        ..on<OnVaporized, Gas>(actions: [(e) => print('Vaporized')]),
    )
    ..state<Gas>(
      (b) => b..on<OnCondensed, Liquid>(actions: [(e) => print('Condensed')]),
    ),
  onTransition: (from, event, to) => print('transitioning...'),
);
```
