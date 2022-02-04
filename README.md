# State Machine & State Charts


## Features
* Synchronous
* Declarative and Type-based
* Supports nested states
* Supports co-regions
* Guard conditions
* onEnter / onExit
* onTransition
* Support initial states


```dart

final machine = StateMachine.create(
  (g) => g
    ..initialState(Solid())
    ..state<Solid>(
      (b) => b
        ..on<OnMelted, Liquid>(
          sideEffect: (e) => print('Melted'),
        ),
    )
    ..state<Liquid>(
      (b) => b
        ..onEnter((s, e) => print('Entering ${s.runtimeType} State'))
        ..onExit((s, e) => print('Exiting ${s.runtimeType} State'))
        ..on<OnFroze, Solid>(sideEffect: (e) => print('Frozen'))
        ..on<OnVaporized, Gas>(sideEffect: (e) => print('Vaporized')),
    )
    ..state<Gas>(
      (b) => b..on<OnCondensed, Liquid>(sideEffect: (e) => print('Condensed')),
    )
    ..onTransition(
      (t) => print(
        'Received Event ${t.event.runtimeType} in State ${t.fromState.runtimeType} transitioning to State ${t.toState.runtimeType}',
      ),
    ),
);
```