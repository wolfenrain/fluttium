import 'package:example/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TextPage extends StatelessWidget {
  const TextPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const TextPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TextCubit(),
      child: const TextView(),
    );
  }
}

class TextView extends StatefulWidget {
  const TextView({super.key});

  @override
  State<TextView> createState() => _TextViewState();
}

class _TextViewState extends State<TextView> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    _controller!.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller!.removeListener(_onChange);
    _controller!.dispose();
    super.dispose();
  }

  void _onChange() {
    context.read<TextCubit>().change(_controller!.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Enter text'),
            ),
            const SizedBox(height: 32),
            const Center(child: TextDisplay()),
          ],
        ),
      ),
    );
  }
}

class TextDisplay extends StatelessWidget {
  const TextDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.select((TextCubit cubit) => cubit.state);
    return Text('Result: $text');
  }
}
