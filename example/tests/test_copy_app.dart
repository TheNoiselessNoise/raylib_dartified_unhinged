// Run it: dart run test_copy_app.dart
import '_base.dart';

class MyEntity extends Entity<G> {
  MyEntity(super.app) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CRectCollider(app, debugDraw: true, size: .vec2(64, 64)));
  }

  @override
  void onUpdate(double dt) => on<CRectCollider<G>>((c) {
    c.debugColor = isClone ? .GREEN : .RED;
  });

  @override
  void onDraw(double dt) => on2<CTransform<G>, CRectCollider<G>>((t, c) {
    final bounds = this.bounds!;
    rl.CoreD.DrawText(
      isClone ? 'clone' : 'original',
      bounds.left, bounds.top, 18, isClone ? .GREEN : .RED
    );
  });

  @override
  MyEntity createInstance() => .new(app);
}

class MyScene extends DrawScene<G> {
  MyScene(super.app);

  @override
  void onStart() => addEntity(MyEntity(app));

  @override
  void onDrawBackground() => rl.CoreD.ClearBackground(isClone ? .RED : .GREEN);

  @override
  MyScene createInstance() => .new(app);
}

typedef G = MyGame;

class MyGame extends ExampleApp<G> {
  MyGame(super.rl);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_copy_app");
    rl.CoreD.SetWindowMonitor(0);
    addScene(MyScene(app));
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_C)) {
      // NOTE: This should copy the whole game, get the first scene,
      //       find the first MyEntity and change it's position.
      final copy = clone(.AllowAll());
      final newScene = copy.getScenes().first;
      final entity = newScene.QueryEntity.On<MyEntity>().First;
      final transform = entity.get<CTransform<G>>()!;
      transform.position = transform.position.sub(.vec2(10, 10));
      // NOTE: finally, replace current scene with our new cloned one
      swapScene(getCurrentScene(), newScene);
    }
  }

  @override
  MyGame createInstance() => .new(rl);
}

void main() => runExample((rl) => G(rl));
