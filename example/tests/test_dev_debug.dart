// Run it: dart run test_dev_debug.dart
import '_base.dart';

class MyEvent extends Event<G> {
  MyEvent(super.app);
}

class RectEntity extends Entity<G> {
  static final double radius = 32;

  RectEntity(super.app, int i) {
    addComp(CTransform(app, position: .vec2(radius * i, radius * i)));
    addComp(CVelocity(app, velocity: .zero()));
    addComp(CRectCollider(app,
      size: .vec2(radius, radius),
      debugColor: .GREEN,
      debugDraw: true,
      enableRotation: true,
    ));
    addComp(CBoundsBounce(app));
    addComp(CPulse(app, speed: 10));
  }
}

class TestDevDebugScene extends DrawScene<G> {
  TestDevDebugScene(super.app) {
    for (int i = 1; i <= 10; i++) {
      addEntity(RectEntity(app, i));
    }
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_SPACE)) {
      emit(MyEvent(app), scope: .global);
    }
  }
}

typedef G = TestDevDebugApp;

class TestDevDebugApp extends ExampleRaylibApp<G> {
  late DebugAppSystem<G> debugSystem;

  TestDevDebugApp(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_dev_debug");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(TestDevDebugScene(app));
    addSystem(debugSystem = DebugAppSystem(app));

    debugSystem.devWatch('last rect pos',
      () => scene
        .getEntities()
        .whereType<RectEntity>().last
        .get<CTransform<G>>()?.position
    );

    debugSystem.devBreakOn<MyEvent>();
  }
}

void main() => runExample((backend) => G(backend));
