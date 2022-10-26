import 'package:bloc/bloc.dart';

class DrawerCubit extends Cubit<String> {
  DrawerCubit() : super('None');

  void change(String value) => emit(value);
}
