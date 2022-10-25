import 'package:example/progress/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ProgressPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProgressCubit(),
      child: const ProgressView(),
    );
  }
}

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: BlocBuilder<ProgressCubit, int>(
          builder: (context, state) {
            if (state == 0) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ProgressCubit>().start();
                  },
                  child: const Text('Start'),
                ),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state == 100 ? 'Done' : 'Progress: $state%',
                  style: Theme.of(context).textTheme.headline4,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: state / 100),
              ],
            );
          },
        ),
      ),
    );
  }
}
