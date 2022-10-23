import 'package:bloc/bloc.dart';

class TextCubit extends Cubit<String> {
  TextCubit() : super('');

  void change(String value) => emit(value);
}
