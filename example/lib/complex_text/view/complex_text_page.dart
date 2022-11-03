import 'package:flutter/material.dart';

class ComplexTextPage extends StatelessWidget {
  const ComplexTextPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ComplexTextPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ComplexTextView();
  }
}

class ComplexTextView extends StatelessWidget {
  const ComplexTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complex Text')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: const [
              Text('Simple text'),
              Text('Text with regexp syntax: (15) [a-z]'),
              Text('Text with special characters like: m², m³, m/s²'),
            ],
          ),
        ),
      ),
    );
  }
}
