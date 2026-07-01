// Run it: dart run test_copy_policy.dart
import '_base.dart';

class Comp1 extends Comp<G> {
  Comp1(super.app);

  @override
  Comp1 createInstance() => .new(app);
}

class Comp2 extends Comp<G> {
  Comp2(super.app);

  @override
  Comp2 createInstance() => .new(app);
}

class MyEntity extends Entity<G> {
  MyEntity(super.app) {
    addComp(Comp1(app));
    addComp(Comp2(app));
  }

  @override
  MyEntity createInstance() => .new(app);
}

class MyScene extends DrawScene<G> {
  MyScene(super.app);

  @override
  void onStart() => addEntity(MyEntity(app));

  @override
  void onDrawBackground() {
    rl.CoreD.DrawText('$scene', 20, 20, 20, .WHITE);

    int y = 40;
    final myEntity = QueryEntity.First;
    for (final (i, comp) in myEntity.getComponents().indexed) {
      rl.CoreD.DrawText('$i) $comp', 20, y+=20, 20, .WHITE);
    }
  }

  @override
  MyScene createInstance() => .new(app);
}

class MyGameClonePolicy extends ClonePolicy<G> {
  @override
  bool allow(CloneKind kind, { ECSBase<G>? owner, Object? payload }) {
    // allow only comp1
    if (kind == .component) {
      return payload is Comp1;
    }

    return true;
  }
}

typedef G = MyGame;

class MyGame extends ExampleRaylibApp<G> {
  MyGame(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_copy_policy");
    rl.CoreD.SetWindowMonitor(0);
    addScene(MyScene(app));
  }

  @override
  void onInput() {
    if (rl.CoreD.IsKeyPressed(.KEY_C)) {
      final copy = clone(.AllowAll(MyGameClonePolicy()));
      swapScene(getCurrentScene(), copy.getScenes().first);
    }
  }

  @override
  MyGame createInstance() => .new(backend);
}

void main() => runExample((backend) => G(backend));
