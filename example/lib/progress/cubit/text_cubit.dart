import 'package:bloc/bloc.dart';

class ProgressCubit extends Cubit<int> {
  ProgressCubit() : super(0);

  Future<void> start() async {
    for (var i = 0; i <= 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      emit(i);
    }
  }
}
