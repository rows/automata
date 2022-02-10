import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:test/test.dart';

void main() {
  test('should not be able to transition out of a final state', () {
    final machine = _createMachine();

    machine.send(OnLeaveHome());
    expect(machine.isInState<Walking>(), isTrue);

    machine.send(OnArriveHome());
    expect(machine.isInState<WalkComplete>(), isTrue);

    machine.send(OnLeaveHome());
    expect(machine.isInState<Walking>(), isFalse);
    expect(machine.isInState<WalkComplete>(), isTrue);
  });
}

StateMachine _createMachine() {
  return StateMachine.create(
    (g) => g
      ..initial<Waiting>()
      ..state<Waiting>(builder: (b) => b..on<OnLeaveHome, Walking>())
      ..state<Walking>(builder: (b) => b..on<OnArriveHome, WalkComplete>())
      ..state<WalkComplete>(
        type: StateNodeType.terminal,
        builder: (b) => b..on<OnLeaveHome, Walking>(),
      ),
  );
}

class Waiting extends State {}

class Walking extends State {}

class WalkComplete extends State {}

class OnLeaveHome extends Event {}

class OnArriveHome extends Event {}
