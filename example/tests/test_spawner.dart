// Run it: dart run test_spawner.dart
import '_base.dart';

class BallEntity extends Entity<G> {
  BallEntity(super.app) {
    addComp(CVelocity(app,
      velocity: .vec2(
        (rand() * 300) * (rand() < .5 ? 1 : -1),
        (rand() * 300) * (rand() < .5 ? 1 : -1)
      ),
      linearDamping: 0,
    ));
    addComp(CCircleCollider(app, tag: 'ball', radius: 8, debugDraw: true));
    addComp(CPhysicsBody(app, mass: 1.0, restitution: 1.0));
    addComp(COutOfBounds(app));
  }
}

class SpawnerEntity extends Entity<G> {
  SpawnerEntity(super.app) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CAnyParticleEmitter(app, rate: 20, factory: createBall));
    addComp(CCircleCollider(app, tag: 'spawner', radius: 8, debugDraw: true));
  }

  BallEntity createBall() {
    final BallEntity ball = .new(app);

    // set the position to this spawner entity
    ball.addComp(transform!.clone());

    return ball;
  }
}

class TestSpawnerScene extends DrawScene<G> {
  TestSpawnerScene(super.app);

  @override
  void onStart() {
    addEntity(SpawnerEntity(app));
  }

  @override
  void onPostDraw(double dt) {
    final ballCount = QueryEntity.On<BallEntity>().Count;
    DrawText('Ball count: $ballCount', 20, 20, 20, .RED);
    DrawText('Press [SPACE] to toggle emitter.', 20, screenHeight - 40, 20, .BLUE);
  }

  @override
  void onInput() {
    if (IsKeyPressed(.KEY_SPACE)) {
      QueryEntity.DoFirst<SpawnerEntity>((s) {
        s.get<CAnyParticleEmitter<G>>()!.toggleEnabled();
      });
    }
  }
}

typedef G = TestSpawner;

class TestSpawner extends ExampleRaylibApp<G> {
  TestSpawner(super.backend);

  @override
  void onInit() {
    InitWindow(screenWidth, screenHeight, "game_test_spawner");
    SetWindowMonitor(0);
    SetTargetFPS(60);

    addScene(TestSpawnerScene(app));
  }
}

void main() => runExample((backend) => G(backend));
