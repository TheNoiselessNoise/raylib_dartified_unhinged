part of '../../raylib_dartified_unhinged.dart';

class ScreenBounceSystem<T extends App<T>> extends SceneSystem<T> {
  double restitution; // 1.0 = perfect bounce, <1 = energy loss
  bool left;
  bool top;
  bool right;
  bool bottom;

  ScreenBounceSystem(super.app, {
    this.restitution = 1,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
  });

  @override
  void onPostUpdate(double dt) {
    final screen = sceneBounds.size;

    scene.QueryEntity.DoForEachWith2<CTransform<T>, CVelocity<T>>((e, t, v) {
      final bounds = e.bounds;
      if (bounds == null) return;

      final pos = t.position;
      final vel = v.velocity;

      final body = e.get<CPhysicsBody<T>>();
      final isKinematic = body != null && body.mass == 0;

      double rx = bounds.width / 2;
      double ry = bounds.height / 2;

      // LEFT
      final minX = rx;
      if (left && pos.x < minX) {
        pos.x = minX;
        if (vel.x < 0) vel.x = isKinematic ? 0 : -vel.x * restitution;
      }

      // RIGHT
      final maxX = screen.x - rx;
      if (right && pos.x > maxX) {
        pos.x = maxX;
        if (vel.x > 0) vel.x = isKinematic ? 0 : -vel.x * restitution;
      }

      // TOP
      final minY = ry;
      if (top && pos.y < minY) {
        pos.y = minY;
        if (vel.y < 0) vel.y = isKinematic ? 0 : -vel.y * restitution;
      }

      // BOTTOM
      final maxY = screen.y - ry;
      if (bottom && pos.y > maxY) {
        pos.y = maxY;
        if (vel.y > 0) vel.y = isKinematic ? 0 : -vel.y * restitution;
      }
    });
  }

  // clone

  @override
  ScreenBounceSystem<T> createInstance() => .new(app,
    restitution: restitution,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
  
  // state

  @override
  ScreenBounceSystemSnapshot<T> createSnapshot() {
    final snapshot = ScreenBounceSystemSnapshot<T>(namedId);
    snapshot.restitution = restitution;
    snapshot.left = left;
    snapshot.top = top;
    snapshot.right = right;
    snapshot.bottom = bottom;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant ScreenBounceSystemSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    restitution = snapshot.restitution;
    left = snapshot.left;
    top = snapshot.top;
    right = snapshot.right;
    bottom = snapshot.bottom;
  }
}

class ScreenBounceSystemSnapshot<T extends App<T>> extends SceneSystemSnapshot<T, ScreenBounceSystem<T>> {
  late double restitution;
  late bool left;
  late bool top;
  late bool right;
  late bool bottom;
  
  ScreenBounceSystemSnapshot(super.namedId);

  @override
  ScreenBounceSystem<T> createInstance(T app) => .new(app,
    restitution: restitution,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}