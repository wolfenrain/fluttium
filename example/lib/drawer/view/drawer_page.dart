import 'package:example/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const DrawerPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DrawerCubit(),
      child: const DrawerView(),
    );
  }
}

class DrawerView extends StatefulWidget {
  const DrawerView({super.key});

  @override
  State<DrawerView> createState() => _DrawerViewState();
}

class _DrawerViewState extends State<DrawerView> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  void _change(String value) {
    context.read<DrawerCubit>().change(value);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: const Text('Drawer'),
        actions: [
          IconButton(
            tooltip: 'Open Drawer',
            icon: const Icon(Icons.menu),
            onPressed: () => _key.currentState!.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: const Text('Value 1'),
              onTap: () => _change('Value 1'),
            ),
            ListTile(
              title: const Text('Value 2'),
              onTap: () => _change('Value 2'),
            ),
            ListTile(
              title: const Text('Value 3'),
              onTap: () => _change('Value 3'),
            ),
          ],
        ),
      ),
      body: const Center(child: DrawerText()),
    );
  }
}

class DrawerText extends StatelessWidget {
  const DrawerText({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = context.watch<DrawerCubit>().state;
    return Text('Clicked: $value', style: theme.textTheme.displayMedium);
  }
}
