// dart run test_entity_group.dart
import '_base.dart';

class SimpleEntity extends Entity<G> {
  final int i;

  int get size => 42;

  SimpleEntity(super.app, this.i) {
    addComp(CLocalTransform(app, offset: .vec2(i * size, i * size)));
    addComp(CCircleCollider(app, radius: size / 2, debugDraw: true));
  }

  @override
  void onDraw(double dt) => onTransform((t) {
    rl.CoreD.DrawText('$id', t.position.x, t.position.y, 20, .RAYWHITE);
  });
}

// NOTE: constrain the group for only `SimpleEntity` types
//       you can still use generic type `AnyEntityGroup<G>`
class SimpleEntityGroup extends EntityGroup<G, SimpleEntity> {
  final int speed = 1;

  SimpleEntityGroup(super.app) {
    addComp(CTransform(app, position: screenSize.divideBy(2)));
    addComp(CVelocity(app, linearDamping: 10));
    addComp(CBoundsConstraint(app, area: .bounds(0, 0, screenHeight, screenWidth)));

    for (int i = 0; i < 4; i++) {
      addEntity(SimpleEntity(app, i));
    }
  }

  @override
  void onUpdate(double dt) => onVelocity((v) {
    if (rl.CoreD.IsKeyDown(.KEY_A)) v.velocity.x -= dt * speed;
    if (rl.CoreD.IsKeyDown(.KEY_D)) v.velocity.x += dt * speed;
    if (rl.CoreD.IsKeyDown(.KEY_W)) v.velocity.y -= dt * speed;
    if (rl.CoreD.IsKeyDown(.KEY_S)) v.velocity.y += dt * speed;
  });
}

class EmptyScene extends DrawScene<G> {
  EmptyScene(super.app);

  @override
  void onStart() {
    addEntity(SimpleEntityGroup(app));
  }
}

typedef G = EmptyGame;

class EmptyGame extends ExampleRaylibApp<G> {
  EmptyGame(super.backend);

  @override
  void onInit() {
    rl.CoreD.InitWindow(screenWidth, screenHeight, "test_entity_group");
    rl.CoreD.SetWindowMonitor(0);

    addScene(EmptyScene(this));
  }
}

void main() => runExample((backend) => G(backend));