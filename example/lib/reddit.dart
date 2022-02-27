import 'package:automata/automata.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
  var _results = <_RedditEntry>[];

  late final _machine = StateMachine.create(
    (g) => g
      ..initial<_Idle>()
      ..state<_Idle>(
        builder: (b) => b..on<_OnFetch, _Loading>(),
      )
      ..state<_Loading>(
        builder: (b) => b
          ..onEntry((event) {
            setState(() {});
          })
          ..invoke<List<_RedditEntry>>(
            builder: (b) => b
              ..id('fetchTopics')
              ..src((_) => _fetchReddit())
              ..onDone<_Success, List<_RedditEntry>>(
                actions: [
                  (event) {
                    setState(() => _results = event.data);
                  }
                ],
              )
              ..onError<_Failure>(
                actions: [(event) {}],
              ),
          ),
      )
      ..state<_Success>(
        type: StateNodeType.terminal,
        builder: (b) => b
          ..onEntry((event) {
            setState(() {});
          }),
      )
      ..state<_Failure>(
        builder: (b) => b
          ..onEntry((event) {
            setState(() {});
          })
          ..on<_OnRetry, _Loading>(),
      ),
  );

  @override
  void initState() {
    super.initState();
    _machine.send(_OnFetch());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Builder(builder: (context) {
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
          children: _results.map((e) => Text(e.title)).toList(),
        );
      }),
    );
  }
}

class _Idle extends AutomataState {}

class _Loading extends AutomataState {}

class _Failure extends AutomataState {}

class _Success extends AutomataState {}

class _OnFetch extends AutomataEvent {}

class _OnRetry extends AutomataEvent {}
