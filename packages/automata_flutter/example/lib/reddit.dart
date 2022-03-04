import 'package:automata/automata.dart';
import 'package:automata_flutter/automata_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class _RedditContext extends AutomataContextState {
  final List<_RedditEntry> results;

  _RedditContext({required this.results});

  _RedditContext copyWith({List<_RedditEntry>? results}) {
    return _RedditContext(results: results ?? this.results);
  }
}

class _RedditEntry {
  final String title;

  const _RedditEntry({required this.title});
}

Future<List<_RedditEntry>> _fetchReddit() async {
  var response = await Dio().get('https://www.reddit.com/r/flutter.json');

  final children = response.data['data']['children'] as List<Object?>;

  return children.map<_RedditEntry>((item) {
    final entry = item as Map<String, dynamic>;
    return _RedditEntry(title: entry['data']['title'] as String);
  }).toList();
}

class RedditExample extends StatefulWidget {
  const RedditExample({Key? key}) : super(key: key);

  @override
  State<RedditExample> createState() => _RedditExampleState();
}

class _RedditExampleState extends State<RedditExample> {
  var results = <_RedditEntry>[];

  late final _machine = StateMachineNotifier.create(
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
              ..src((_) => _fetchReddit())
              ..onDone<_Success, List<_RedditEntry>>(
                actions: [
                  (event, assign) {
                    assign((context) {
                      return (context as _RedditContext)
                          .copyWith(results: event.data);
                    });
                    // setState(() {
                    //   results = event.data;
                    // });
                  }
                ],
              )
              ..onError<_Failure>(
                actions: [(event, _) {}],
              ),
          ),
      )
      ..state<_Success>(type: StateNodeType.terminal)
      ..state<_Failure>(
        builder: (b) => b..on<_OnRetry, _Loading>(),
      ),
    context: _RedditContext(results: []),
  );

  @override
  void initState() {
    super.initState();
    _machine.send(_OnFetch());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _machine,
        builder: (context, _) {
          if (_machine.isInState<_Loading>() || _machine.isInState<_Idle>()) {
            return const Text('Loading');
          }

          if (_machine.isInState<_Failure>()) {
            return ElevatedButton(
              onPressed: () => _machine.send(_OnRetry()),
              child: const Text('Retry'),
            );
          }

          return ListView(
            children: results.map((e) => Text(e.title)).toList(),
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
