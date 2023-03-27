import 'package:example/complex_text/complex_text.dart';
import 'package:example/counter/counter.dart';
import 'package:example/drawer/drawer.dart';
import 'package:example/progress/progress.dart';
import 'package:example/scrollable_list/scrollable_list.dart';
import 'package:example/simple_menu/simple_menu.dart';
import 'package:example/text/text.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({required this.environment, super.key});

  final String environment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppView(environment: environment),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({required this.environment, super.key});

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
            onPressed: () => Navigator.of(context).push(DrawerPage.route()),
            child: const Text('Drawer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(TextPage.route()),
            child: const Text('Text'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(ProgressPage.route()),
            child: const Text('Progress'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              ComplexTextPage.route(),
            ),
            child: const Text('Complex Text'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              SimpleMenuPage.route(),
            ),
            child: const Text('Simple Menu'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              ScrollableListPage.route(),
            ),
            child: const Text('Scrollable List'),
          ),
        ],
      ),
    );
  }
}
