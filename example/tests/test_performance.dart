// dart run test_performance.dart
import '_base.dart';

class PerformanceScene extends DrawScene<G> {
  PerformanceScene(super.app);

  int ballCount = 1000;

  /*
    At 60 FPS.

    gridCellSize = 48, enableEventEmitting = false
      > enableCollision = true  // ~28 FPS with 1000 balls
      > enableCollision = false // ~58 FPS with 1000 balls

    gridCellSize = 48, enableEventEmitting = true
      > enableCollision = true  // ~22 FPS with 1000 balls
      > enableCollision = false // ~58 FPS with 1000 balls
  */

  @override
  void onStart() {
    addSystem(CollisionResolverSystem(app,
      gridCellSize: 48,
      enableEventEmitting: true,
    ));
    addSystem(ScreenBounceSystem(app, bottom: true));

    /**
     * BALL ENTITY
     */

    for (int x = 0; x < ballCount; x++) {
      addEntity(Entity(app)
        .addComp(CTransform(app,
          position: .vec2(
            app.screenWidth / 2 + ((rl.rand() * 200) * (rl.rand() < .5 ? 1 : -1)),
            app.screenHeight / 2 + ((rl.rand() * 200) * (rl.rand() < .5 ? 1 : -1)),
          ),
        ))
        .addComp(CVelocity(app,
          velocity: .vec2(
            (rl.rand() * 220) * (rl.rand() < .5 ? 1 : -1),
            (rl.rand() * 260) * (rl.rand() < .5 ? 1 : -1)
          ),
          linearDamping: .05,
        ))
        .addComp(CPhysicsBody(app, mass: 1.0, restitution: 0.0))
        .addComp(CCircleCollider(app,
          tag: 'ball',
          radius: 8,
          debugDraw: true,
          enableCollision: true,
        ))
      );
    }
  }

  @override
  void onEvent(Event<G> event) => event.stopPropagation();

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText(
      'PERFORMANCE TEST',
      20, 20, 20, .RAYWHITE,
    );

    final pad = 10;
    final x = 50;
    final fs = 20;
    final y = app.screenHeight - 100;
    final text = 'Ball Count: $ballCount';
    final textw = rl.CoreD.MeasureText(text, fs);

    rl.CoreD.DrawRectangle(x - pad, y - pad, textw + pad * 2, fs * 2 + pad * 2, rl.CoreD.Fade(.BLUE, 0.5));
    rl.CoreD.DrawText(text, x, y, fs, .WHITE);
    rl.CoreD.DrawFPS(x, y + fs);
  }
}

typedef G = PerformanceTest;

class PerformanceTest extends ExampleRaylibApp<G> {
  PerformanceTest(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(800, 450, "test_performance");
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(PerformanceScene(app));
  }
}

void main() => runExample((backend) => G(backend));
