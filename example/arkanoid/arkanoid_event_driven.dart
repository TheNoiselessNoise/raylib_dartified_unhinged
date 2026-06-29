// dart run arkanoid_test.dart
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

typedef G = Arkanoid;

/* =========================
  EVENTS
========================= */

class BallHitBrick extends Event<G> {
  final Entity<G> brick;
  BallHitBrick(super.app, this.brick);
}

class BallLost extends Event<G> {
  BallLost(super.app);
}

class MovePaddle extends Event<G> {
  final double axis; // -1..1
  MovePaddle(super.app, this.axis);
}

class SpawnBall extends Event<G> {
  SpawnBall(super.app);
}

/* =========================
  PADDLE
========================= */

class PaddleEntity extends Entity<G> {
  PaddleEntity(super.app);

  double speed = 600;

  @override
  void onAdd(_) {
    addComp(CTransform(app, position: .vec2(screenWidth / 2, screenHeight - 40)));
    addComp(CVelocity(app));
    addComp(CPhysicsBody(app, mass: 0, restitution: 1));
    addComp(CRectCollider(app,
      tag: 'paddle',
      size: .vec2(120, 20),
      debugDraw: true,
    ));
  }

  @override
  void onEvent(Event<G> e) {
    if (e is MovePaddle) {
      on<CVelocity<G>>((v) {
        v.velocity.x = e.axis * speed;
      });
    }
  }
}

/* =========================
  BALL
========================= */

class BallEntity extends Entity<G> {
  BallEntity(super.app);

  @override
  void onAdd(_) {
    addComp(CTransform(app,
      position: sceneBounds.size.divideBy(2),
    ));
    addComp(CVelocity(app,
      velocity: .vec2(
        (rl.rand() * 300) * (rl.rand() < .5 ? 1 : -1),
        (rl.rand() * 300) * (rl.rand() < .5 ? 1 : -1)
      ),
      linearDamping: 0,
    ));
    addComp(CCircleCollider(app, tag: 'ball', radius: 8, debugDraw: true));
    addComp(CPhysicsBody(app, mass: 1.0, restitution: 1.0));
  }
}

/* =========================
  BRICK
========================= */

class BrickEntity extends Entity<G> {
  final Vector2D position;

  BrickEntity(super.app, this.position);

  @override
  void onAdd(_) {
    addComp(CTransform(app, position: position));
    addComp(CRectCollider(app,
      tag: 'brick',
      size: .vec2(60, 20),
      debugDraw: true,
      debugColor: .ORANGE,
    ));
    addComp(CPhysicsBody(app, mass: 0, restitution: 1));
  }
}

/* =========================
  SYSTEMS
========================= */

class PaddleInputSystem extends SceneSystem<G> {
  final String K_left = 'left';
  final String K_right = 'right';

  PaddleInputSystem(super.app);

  @override
  void onAdd(ECSBase<G> parent) {
    super.onAdd(parent);

    input.mapKey(K_left, .KEY_A);
    input.mapKey(K_right, .KEY_D);
  }

  @override
  void onPreUpdate(double dt) {
    double axis = 0;
    if (input.isKeyDown(K_left)) axis = -1;
    if (input.isKeyDown(K_right)) axis = 1;
    scene.QueryEntity.DoFirst<PaddleEntity>((p) => p.emit(MovePaddle(app, axis), scope: .scene));
  }
}

class ArkanoidRulesSystem extends SceneSystem<G> {
  int score = 0;

  ArkanoidRulesSystem(super.app);

  @override
  void onEvent(Event<G> e) {
    if (e is EventCollision<G>) {
      final ballBrick = e.as<BallEntity, BrickEntity>();

      if (ballBrick != null) {
        final (ball, brick) = ballBrick;
        scene.command(RemoveEntityCommand(app, brick));
        score += 100;
      }
    }

    if (e is BallLost) {
      emit(SpawnBall(app), scope: .scene);
    }
  }

  @override
  void onPreDraw(double dt) {
    rl.CoreD.DrawText('Score: $score', 20, screenHeight - 40, 20, .WHITE);
  }
}

class BallSpawnerSystem extends SceneSystem<G> {
  BallSpawnerSystem(super.app);

  @override
  void onEvent(Event<G> e) {
    if (e is SpawnBall) {
      scene.addEntity(BallEntity(app));
    }
  }
}

/* =========================
  SCENE
========================= */

class ArkanoidScene extends DrawScene<G> {
  ArkanoidScene(super.app);

  @override
  void onStart() {
    addSystem(PaddleInputSystem(app));
    addSystem(CollisionResolverSystem(app));
    addSystem(ArkanoidRulesSystem(app));
    addSystem(BallSpawnerSystem(app));
    addSystem(ScreenBounceSystem(app));

    addEntity(PaddleEntity(app));
    emit(SpawnBall(app), scope: .scene); // start with a ball

    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 10; x++) {
        addEntity(BrickEntity(
          app,
          .vec2(80 + x * 65, 60 + y * 30),
        ));
      }
    }
  }

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText(
      'EVENT-DRIVEN ARKANOID',
      20, 20, 20, .RAYWHITE,
    );
  }
}

/* =========================
  GAME
========================= */

class Arkanoid extends App<G> {
  final String K_q = 'q';

  Arkanoid(super.rl);

  @override
  bool shouldExit() => rl.CoreD.WindowShouldClose();

  @override
  void onInit() {
    rl.CoreD.InitWindow(800, 450, 'arkanoid_structure_first');
    rl.CoreD.SetWindowMonitor(0);
    rl.CoreD.SetTargetFPS(60);

    addScene(ArkanoidScene(this));

    input.mapKey(K_q, .KEY_Q);
  }

  @override
  void onInput() {
    if (input.isKeyPressed(K_q)) {
      scene.command(ExitAppCommand(app));
    }
  }
}

class ArkanoidEventDriven extends UnhingedRaylibGame<G> {
  @override
  G create(Raylib rl) => G(rl);
}

void main() => runRaylib(
  ArkanoidEventDriven(),
  nativeLibPath: 'raylib-5.5_linux_amd64/lib'
);
