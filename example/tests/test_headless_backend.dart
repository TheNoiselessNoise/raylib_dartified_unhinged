// Run it: dart run test_animations.dart
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

class MyComp extends Comp<G> {
  MyComp(super.app);
}

class MyEntity extends Entity<G> {
  MyEntity(super.app) {
    addComp(MyComp(app));
  } 
}

class TestHeadlessBackendScene extends DrawScene<G> {
  late MyEntity myEntity;

  TestHeadlessBackendScene(super.app) {
    addEntity(myEntity = MyEntity(app));
  }
}

typedef G = TestHeadlessBackendApp;

class TestHeadlessBackendApp extends App<G> {
  TestHeadlessBackendApp(super.backend);

  @override
  void onInit() => addScene(TestHeadlessBackendScene(app));
}

class TestHeadlessBackendBridge extends UnhingedRaylibGame<G> {
  @override
  G create(RaylibBackend backend) => G(backend);

  @override
  bool shouldClose(Raylib rl) => true;
}

void main() {
  late TestHeadlessBackendBridge bridge;

  runRaylib(bridge = .new(), nativeLibPath: 'raylib-5.5_linux_amd64/lib');

  print(bridge.app.currentScene);
}
