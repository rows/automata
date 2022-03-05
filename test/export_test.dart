import 'package:automata/src/state_machine.dart';
import 'package:automata/src/types.dart';
import 'package:test/test.dart';

void main() {
  test('should set initial state', () {
    final machine = _createMachine();

    print(machine.export());
  });
}

class _Green extends State {}

class _Yellow extends State {}

class _Red extends State {}

class _Crosswalk1 extends State {}

class _Walk extends State {}

class _Wait extends State {}

class _Stop extends State {}

class _Stop2 extends State {}

class _Crosswalk2 extends State {}

class _OnTimer extends Event {}

class _OnPedWait extends Event {}

class _OnPedStop extends Event {}

StateMachine _createMachine() {
  return StateMachine.create(
    (g) => g
      ..initial<_Green>()
      ..state<_Green>(
        builder: (b) => b..on<_OnTimer, _Yellow>(),
      )
      ..state<_Yellow>(
        builder: (b) => b..on<_OnTimer, _Red>(),
      )
      ..state<_Red>(
        type: StateNodeType.parallel,
        builder: (b) => b
          ..state<_Crosswalk1>(
            builder: (b) => b
              ..initial<_Walk>()
              ..state<_Walk>(
                builder: (b) => b..on<_OnPedWait, _Wait>(),
              )
              ..state<_Wait>(
                builder: (b) => b..on<_OnPedStop, _Stop>(),
              )
              ..state<_Stop>(
                type: StateNodeType.terminal,
              ),
          )
          ..state<_Crosswalk2>(
            builder: (b) => b
              ..initial<_Walk>()
              ..state<_Walk>(
                builder: (b) => b..on<_OnPedWait, _Wait>(),
              )
              ..state<_Wait>(
                builder: (b) => b..on<_OnPedStop, _Stop>(),
              )
              ..state<_Stop>(
                builder: (b) => b..on<_OnPedStop, _Stop2>(),
              )
              ..state<_Stop2>(
                type: StateNodeType.terminal,
              ),
          ),
      ),
  );
}
