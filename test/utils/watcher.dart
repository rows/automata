import 'package:automata/src/types.dart';
import 'package:mocktail/mocktail.dart';

class Watcher {
  void onEntry(Type state, AutomataEvent? e) {}
  void onExit(Type state, AutomataEvent? e) {}
  void onAlways(Type state, AutomataEvent? e) {}
}

class MockWatcher extends Mock implements Watcher {}
