// Run it: dart run test_animations.dart
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

class MyComp extends Comp<G> {
  MyComp(super.app);

  // NOTE: for clone() to work
  @override
  MyComp createInstance() => .new(app);
}

class MyEntity extends Entity<G> {
  MyEntity(super.app) {
    addComp(MyComp(app));
  }

  // NOTE: for clone() to work
  @override
  MyEntity createInstance() => .new(app);
}

class TestHeadlessBackendScene extends Scene<G> {
  late MyEntity myEntity;

  TestHeadlessBackendScene(super.app) {
    addEntity(myEntity = MyEntity(app));
  }

  // NOTE: for clone() to work
  @override
  TestHeadlessBackendScene createInstance() => .new(app);
}

typedef G = TestHeadlessBackendApp;

class TestHeadlessBackendApp extends App<G> {
  TestHeadlessBackendApp(super.backend);

  @override
  void onInit() => addScene(TestHeadlessBackendScene(app));

  // NOTE: for clone() to work
  @override
  TestHeadlessBackendApp createInstance() => .new(backend);
}

// void main() {
//   final headless = HeadlessBackend();
//   final app = TestHeadlessBackendApp(headless);
//   app.init();
//   app.frame();
//   app.exit();
//   print(app.currentScene);
// }

class TestHeadlessBackendBridge extends UnhingedRaylibGame<G> {
  @override
  G create(RaylibBackend backend) => G(backend);

  @override
  void init(Raylib rl) => app = create(.new(rl));

  @override
  bool shouldClose(Raylib rl) => true;

  @override
  void loop(Raylib rl) {}

  @override
  void close(Raylib rl) {}

  @override
  void dispose(Raylib rl) {}
}

void main() {
  late TestHeadlessBackendBridge bridge;

  // backend agnostic raylib initialization
  runRaylib(bridge = .new(), nativeLibPath: 'raylib-5.5_linux_amd64/lib');

  bridge.app.init();
  bridge.app.frame(); // frame 1
  bridge.app.frame(); // frame 2
  bridge.app.frame(); // frame 3
  bridge.app.exit();

  // TestHeadlessBackendScene(id=1)
  print(bridge.app.currentScene);

  // MyEntity(id=1)
  print(bridge.app.currentScene.QueryEntity.First);

  // MyEntity(id=2)
  print(bridge.app.clone().currentScene.QueryEntity.First);
}
