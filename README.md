<p align="center">
  <a href="https://rows.com">
  <br />
  <img src="https://rows.com/media/logo.svg" alt="Rows" width="150"/>
  <br />
    <sub><strong>Spreadsheet with superpowers!</strong></sub>
  <br />
  <br />
  </a>
</p>

# Automata
A dart (incomplete) implementation of a finite state machine following [SCXML](https://www.w3.org/TR/scxml) specification.

The main highlights of automata are:
- Declarative and type-based
- Compound states (nested states)
- Parallel states
- Initial states
- Guard conditions
- Eventless transitions
- Actions
- onEntry / onExit
- onTransition

## Super quick start:

```
dart pub add automata

or

flutter pub add automata
```

```dart
import 'package:automata/automata.dart';

class Inactive extends State {}
class Active extends State {}
class OnToggle extends Event {}

final machine = StateMachine.create(
  (g) => g
    ..initial<Inactive>()
    ..state<Inactive>(
      builder: (g) => g..on<OnToggle, Active>()
    )
    ..state<Active>(
      builder: (g) => g..on<OnToggle, Inactive>()
    ),
  onTransition: (e, value) => print(
    '''
    ## Transition::
    Received Event: $e
    Value: $value
    ''',
  ),
);

machine.send(OnMelted());
```

## Credits
While developing this packages we were heavily inspired by [Tinder's StateMachine](https://github.com/Tinder/StateMachine), [Stately's XState](https://github.com/statelyai/xstate) and the [SCXML specification](https://www.w3.org/TR/scxml).
