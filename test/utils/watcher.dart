import 'package:automata/src/types.dart';
import 'package:mocktail/mocktail.dart';

class Watcher {
  void onEntry(Type state, Event? e) {}
  void onExit(Type state, Event? e) {}
}

class MockWatcher extends Mock implements Watcher {}
