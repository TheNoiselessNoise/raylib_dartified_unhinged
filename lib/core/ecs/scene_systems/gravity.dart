part of '../../raylib_dartified_unhinged.dart';

class GravitySystem<T extends App<T>> extends SceneSystem<T> {
  Vector2D gravity;

  GravitySystem(super.app, {
    Vector2D? gravity
  }) : gravity = gravity ?? .zero();

  @override
  void onPreUpdate(double dt) => scene.QueryEntity.DoForEachWith2<CTransform<T>, CVelocity<T>>(
    (e, t, v) => v.velocity.y += gravity.y * dt
  );

  // clone

  @override
  GravitySystem<T> createInstance() => .new(app,
    gravity: gravity.copy(),
  );
  
  // state

  @override
  GravitySystemSnapshot<T> createSnapshot() {
    final snapshot = GravitySystemSnapshot<T>(namedId);
    snapshot.gravity = gravity.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant GravitySystemSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    gravity = snapshot.gravity.copy();
  }
}

class GravitySystemSnapshot<T extends App<T>> extends SceneSystemSnapshot<T, GravitySystem<T>> {
  late Vector2D gravity;
  
  GravitySystemSnapshot(super.namedId);

  @override
  GravitySystem<T> createInstance(T app) => .new(app,
    gravity: gravity.copy(),
  );
}