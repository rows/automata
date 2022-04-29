import 'package:automata/automata.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'state_builder.dart';

class _RedditEntry {
  final String title;

  const _RedditEntry({required this.title});
}

Future<List<_RedditEntry>> _fetchReddit({required bool shouldFail}) async {
  if (shouldFail) {
    throw Exception('something went wrong');
  }

  final response =
      await Dio().get<dynamic>('https://www.reddit.com/r/flutter.json');

  final children = response.data['data']['children'] as List<Object?>;

  return children.map<_RedditEntry>((item) {
    final entry = item! as Map<String, dynamic>;
    return _RedditEntry(title: entry['data']['title'] as String);
  }).toList();
}

class StateMachineNotifier extends ChangeNotifier {
  List<_RedditEntry> value = <_RedditEntry>[];

  // For testing purposes lets make the fetch fail on first attempt.
  bool hasFetchedOnce = false;

  late final machine = StateMachine.create(
    (g) => g
      ..initial<_Idle>()
      ..state<_Idle>(
        builder: (b) => b..on<_OnFetch, _Loading>(),
      )
      ..state<_Loading>(
        builder: (b) => b
          ..invoke<List<_RedditEntry>>(
            builder: (b) => b
              ..id('fetchTopics')
              ..src((_) => _fetchReddit(shouldFail: !hasFetchedOnce))
              ..onDone<_Success, List<_RedditEntry>>(
                actions: [
                  (event) {
                    value = event.data;
                    hasFetchedOnce = true;
                    notifyListeners();
                  }
                ],
              )
              ..onError<_Failure>(
                actions: [
                  (event) {
                    hasFetchedOnce = true;
                    notifyListeners();
                  }
                ],
              ),
          ),
      )
      ..state<_Success>(type: StateNodeType.terminal)
      ..state<_Failure>(
        builder: (b) => b..on<_OnRetry, _Loading>(),
      ),
    onTransition: (e, value) => notifyListeners(),
  );

  void send<E extends AutomataEvent>(E event) => machine.send(event);
}

class RedditExample extends StatefulWidget {
  const RedditExample({Key? key}) : super(key: key);

  @override
  State<RedditExample> createState() => _RedditExampleState();
}

class _RedditExampleState extends State<RedditExample> {
  late final _machineNotifier = StateMachineNotifier();

  @override
  void initState() {
    super.initState();
    _machineNotifier.send(_OnFetch());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _machineNotifier,
        builder: (context, _) {
          return AutomataStateBuilder(
            machine: _machineNotifier.machine,
            stateBuilders: {
              _Failure: AutomataStateBuilderFactory((context) {
                return ElevatedButton(
                  onPressed: () => _machineNotifier.send(_OnRetry()),
                  child: const Text('Retry'),
                );
              }),
              _Success: AutomataStateBuilderFactory((context) {
                return ListView(
                  children: _machineNotifier.value
                      .map(
                        (e) => Text(e.title),
                      )
                      .toList(),
                );
              }),
            },
            defaultBuilder: (context) {
              return const Text('Loading');
            },
          );
        },
      ),
    );
  }
}

class _Idle extends AutomataState {}

class _Loading extends AutomataState {}

class _Failure extends AutomataState {}

class _Success extends AutomataState {}

class _OnFetch extends AutomataEvent {}

class _OnRetry extends AutomataEvent {}
