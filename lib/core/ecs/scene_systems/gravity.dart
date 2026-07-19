part of '../../raylib_dartified_unhinged.dart';

class GravitySystem<T extends App<T>> extends SceneSystem<T> {
  Vector2D gravity;

  GravitySystem(super.app, {
    super.populateDefaults,
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
    final snapshot = GravitySystemSnapshot<T>(id);
    snapshot.gravity = gravity.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant GravitySystemSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    gravity = snapshot.gravity.copy();
  }

  // persistence
  
  static const typeId = '__sceneSystem__GravitySystem';
  
  @override String get persistentTypeId => typeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'gravity': gravity.getPersistableData(),
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);

    final gravityData = data.getList<double>('gravity');
    gravity.restorePersistableData(gravityData);
  }
}

class GravitySystemSnapshot<T extends App<T>> extends SceneSystemSnapshot<T, GravitySystem<T>> {
  late Vector2D gravity;
  
  GravitySystemSnapshot(super.id);

  @override
  GravitySystem<T> createInstance(T app) => .new(app,
    gravity: gravity.copy(),
  );
}