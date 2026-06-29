part of '../../raylib_dartified_unhinged.dart';

class CLocalTransform<T extends App<T>> extends Comp<T> {
  Vector2D offset; // OFFSET from a parent
  double rotation; // radians
  Vector2D scale;  // 1,1 is identity

  CLocalTransform(super.app, {
    required this.offset,
    this.rotation = 0,
    Vector2D? scale,
  }) : scale = scale ?? .one();

  // clone

  @override
  CLocalTransform<T> createInstance() => .new(app,
    offset: offset.copy(),
    rotation: rotation,
    scale: scale.copy(),
  );

  // state

  @override
  CLocalTransformSnapshot<T> createSnapshot() {
    final snapshot = CLocalTransformSnapshot<T>(namedId);
    snapshot.offset = offset.copy();
    snapshot.rotation = rotation;
    snapshot.scale = scale.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CLocalTransformSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    offset = snapshot.offset.copy();
    rotation = snapshot.rotation;
    scale = snapshot.scale.copy();
  }
}

class CLocalTransformSnapshot<T extends App<T>> extends CompSnapshot<T, CLocalTransform<T>> {
  late Vector2D offset;
  late double rotation;
  late Vector2D scale;
  
  CLocalTransformSnapshot(super.namedId);

  @override
  CLocalTransform<T> createInstance(T app) => .new(app,
    offset: offset.copy(),
    rotation: rotation,
    scale: scale.copy(),
  );
}