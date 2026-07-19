// Run it: dart run test_empty_app.dart
import '_base.dart';

typedef G = TestEmptyApp;

// NOTE: should open an empty app with a dummy scene present
class TestEmptyApp extends ExampleRaylibApp<G> {
  TestEmptyApp(super.backend);
}

void main() => runExample((backend) => G(backend));
