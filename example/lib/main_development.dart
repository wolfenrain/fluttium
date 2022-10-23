import 'package:example/app/app.dart';
import 'package:example/bootstrap.dart';

void main() {
  bootstrap(() => const App(environment: 'Development'));
}
