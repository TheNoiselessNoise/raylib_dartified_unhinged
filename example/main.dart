// Demonstrates two scenes connected by a custom event:
//   - [FirstScene] having a bouncing ball, a mouse-following ball that emits
//     particles, and a button that switches to the next scene.
//   - [SecondScene] which switches back to the first scene after 5 seconds.
import 'package:raylib_dartified_unhinged/raylib_dartified_unhinged.dart';

/// Shorthand alias for [MyApp].
typedef G = MyApp;

/* =========================
  EVENTS
========================= */

/// Fired when the active scene should advance to the next one.
class SwitchSceneEvent extends Event<G> {
  SwitchSceneEvent(super.app);
}

/* =========================
  ENTITIES
========================= */

/// A pulsing ball that moves around the screen, bouncing off of edges.
class BallEntity extends Entity<G> {
  BallEntity(super.app) {
    addComp(CTransform(app, position: sceneBounds.position.divideBy(2)));
    addComp(CVelocity(app, velocity: .vec2(-100, 100)));
    addComp(CCircleCollider(app, radius: 32, debugColor: .GREEN, debugDraw: true));
    addComp(CBoundsBounce(app));
    addComp(CPulse(app, speed: 10));
  }
}

/// A short-lived particle spawned by [BallEntityFollowingMouse].
/// Drifts downward with a random horizontal offset and removes itself
/// when it leaves the screen.
class ParticleEntity extends Entity<G> {
  ParticleEntity(super.app) {
    addComp(CTransform(app));
    addComp(CCircleCollider(app, radius: 8, debugColor: .PINK, debugDraw: true));
    addComp(CVelocity(app, velocity: .vec2(
      rl.rand() * -100 + 50,
      rl.rand() * 100 + 50
    )));
    addComp(COutOfBounds(app));
  }
}

/// A pulsing ball that follows the mouse cursor and continuously
/// emits [ParticleEntity] particles from its position.
class BallEntityFollowingMouse extends Entity<G> {
  final double radius = 32;

  BallEntityFollowingMouse(super.app) {
    addComp(CTransform(app));
    addComp(CCircleCollider(app, radius: radius, debugColor: .AZURE, debugDraw: true));
    addComp(CPulse(app, speed: 10));
    addComp(CAnyParticleEmitter(app, rate: 20, factory: () =>
      ParticleEntity(app).replaceComp(transform!.clone())
    ));
  }

  @override
  void onUpdate(double dt) => onTransform((t) {
    t.position = rl.CoreD.GetMousePosition();
  });
}

/* =========================
  SCENES
========================= */

/// The first scene. Shows a bouncing ball, a mouse-following ball,
/// and a button that switches to the next scene on double-click.
class FirstScene extends FWidgetScene<G> {
  FirstScene(super.app);

  @override
  ColorD get backgroundColor => .RED;

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText('FirstScene', 20, 20, 20, .WHITE);

    final particlesCount = QueryEntity.On<ParticleEntity>().Count;
    rl.CoreD.DrawText('ParticleEntity count: $particlesCount', 20, 60, 20, .WHITE);
  }

  @override
  void onStart() {
    addEntity(FCenter(app,
      vertical: true,
      child: FButton(app,
        onDoubleClickFn: (_) => emit(SwitchSceneEvent(app), scope: .global),
        child: FPadding.all(app, 16,
          child: FLabel(app, text: 'Double-click to go to second scene'),
        ),
      ),
    ));

    addEntity(BallEntity(app));
    addEntity(BallEntityFollowingMouse(app));
  }
}

/// The second scene. Automatically switches back to the first scene
/// after [_switchAfter] seconds.
class SecondScene extends DrawScene<G> {
  SecondScene(super.app);

  static const _switchAfter = 5.0;
  double _elapsed = 0;

  @override
  ColorD get backgroundColor => .BLUE;

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText('SecondScene', 20, 20, 20, .WHITE);
    rl.CoreD.DrawText('Will go back to first scene after ${(_switchAfter - _elapsed).f3} seconds.', 20, 50, 20, .WHITE);
  }

  @override
  void onEnter() {
    _elapsed = 0;

    task(DelayTask(app,
      seconds: _switchAfter,
      action: (_) => emit(SwitchSceneEvent(app), scope: .global),
    ));
  }

  @override
  void onBeginFrame(double dt) {
    _elapsed += dt;
  }
}

/* =========================
  APP
========================= */

/// Extension to access Raylib from anywhere.
extension on HasAppAccess<G> {
  Raylib get rl => (backend as RaylibBackend).rl;
}

/// The application.
class MyApp extends App<G> {
  MyApp(super.backend);

  @override
  bool shouldExit() => rl.CoreD.WindowShouldClose();

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, 'pub.dev example');
    addScene(FirstScene(app));
    addScene(SecondScene(app));
  }

  @override
  void onEvent(Event<G> event) {
    if (event is SwitchSceneEvent) {
      callback(() => app.nextScene());
    }
  }
}

/// Raylib-specific entry point. Provides the concrete [Raylib] instance
/// to [MyApp] while keeping the app itself backend-agnostic.
class MyAppRaylib extends UnhingedRaylibGame<G> {
  @override
  G create(RaylibBackend backend) => G(backend);
}

void main() => runRaylib(
  MyAppRaylib(),
  nativeLibPath: 'raylib-5.5_linux_amd64/lib',
);