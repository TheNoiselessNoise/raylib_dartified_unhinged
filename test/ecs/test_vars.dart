import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';
import 'package:test/test.dart';

typedef G = TestApp;

class TestApp extends App<G> {
  TestApp(super.backend); 
}

void main() {
  group('Variables', () {
    late TestApp app;
    VarKey<int> varCount = .new('count');

    setUp(() => app = .new(HeadlessBackend()));

    test('set', () {
      app.setVar(varCount, 100);
      expect(app.getVar(varCount), equals(100));
    });

    test('get or set', () {
      expect(app.getOrSetVar(varCount, 100), equals(100));
    });

    test('get missing', () {
      expect(app.getVar(varCount), equals(null));
    });

    test('get with fallback', () {
      expect(app.getVarSafe(varCount, 100), equals(100));
    });

    test('has', () {
      expect(app.hasVar(varCount), equals(false));
      app.setVar(varCount, 100);
      expect(app.hasVar(varCount), equals(true));
    });

    test('increment', () {
      app.incVar(varCount);
      app.incVar(varCount);
      app.incVar(varCount);
      expect(app.getVar(varCount), equals(3));
    });

    test('decrement', () {
      app.decVar(varCount);
      app.decVar(varCount);
      app.decVar(varCount);
      expect(app.getVar(varCount), equals(-3));
    });
  });
}
