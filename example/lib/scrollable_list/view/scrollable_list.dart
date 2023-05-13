import 'package:flutter/material.dart';

class ScrollableListPage extends StatefulWidget {
  const ScrollableListPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ScrollableListPage(),
    );
  }

  @override
  State<ScrollableListPage> createState() => _ScrollableListPageState();
}

class _ScrollableListPageState extends State<ScrollableListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scrollable List')),
      body: Semantics(
        label: 'list_view',
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('List item $index'),
            );
          },
        ),
      ),
    );
  }
}
