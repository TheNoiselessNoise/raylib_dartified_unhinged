import 'package:meta/meta.dart';

mixin Base {
  @mustCallSuper
  void test() => print('base');
}

mixin One on Base {
  @override
  @mustCallSuper
  void test() {
    super.test();
    print('one');
  }
}

mixin Two on Base {
  @override
  @mustCallSuper
  void test() {
    super.test();
    print('two');
  }
}

class A with Base, One, Two {
  const A();
}

void main() {
  A().test();
}