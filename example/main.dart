// ignore_for_file: avoid_print

import 'package:automata/automata.dart';

class Inactive extends State {}

class Active extends State {}

class OnToggle extends Event {}

void main() {
  final machine = StateMachine.create(
    (g) => g
      ..initial<Inactive>()
      ..state<Inactive>(
        builder: (g) => g
          ..onEntry((event) => print('> Entry Inactive'))
          ..onExit((event) => print('< Exit Inactive'))
          ..on<OnToggle, Active>(),
      )
      ..state<Active>(
        builder: (g) => g
          ..onEntry((event) => print('> Entry Active'))
          ..onExit((event) => print('< Exit Active'))
          ..on<OnToggle, Inactive>(),
      ),
    onTransition: (source, e, target) => print(
      'Transition:: Received Event $e in State $source transitioning to State $target',
    ),
  );

  machine.send(OnToggle());
  print('   # ${machine.value}');

  machine.send(OnToggle());
  print('   # ${machine.value}');
}
