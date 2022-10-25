import 'package:example/counter/counter.dart';
import 'package:example/progress/progress.dart';
import 'package:example/text/text.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key, required this.environment});

  final String environment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppView(environment: environment),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key, required this.environment});

  final String environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Environment: $environment')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(CounterPage.route()),
            child: const Text('Counter'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(TextPage.route()),
            child: const Text('Text'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(ProgressPage.route()),
            child: const Text('Progress'),
          ),
        ],
      ),
    );
  }
}
