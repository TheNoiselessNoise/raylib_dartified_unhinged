part of '../../raylib_dartified_unhinged.dart';

// world position, scale and rotation
class CTransform<T extends App<T>> extends Comp<T> {
  late Vector2D prevPosition;

  Vector2D position; // CENTER position in world space
  double rotation;   // radians
  Vector2D scale;    // 1,1 is identity

  CTransform(super.app, {
    Vector2D? position,
    this.rotation = 0,
    Vector2D? scale,
  }) :
    position = position ?? .zero(),
    scale = scale ?? .one()
  {
    prevPosition = this.position.copy();
  }

  @override
  @mustCallSuper
  void onUpdate(double dt) => prevPosition = position.copy();

  // clone

  @override
  @mustCallSuper
  CTransform<T> createInstance() {
    final c = CTransform<T>(app,
      position: position.copy(),
      rotation: rotation,
      scale: scale.copy(),
    );

    c.prevPosition = prevPosition.copy();

    return c;
  }

  // state

  @override
  CTransformSnapshot<T> createSnapshot() {
    final snapshot = CTransformSnapshot<T>(namedId);
    snapshot.position = position.copy();
    snapshot.rotation = rotation;
    snapshot.scale = scale.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CTransformSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    position = snapshot.position.copy();
    rotation = snapshot.rotation;
    scale = snapshot.scale.copy();
  }
}

class CTransformSnapshot<T extends App<T>> extends CompSnapshot<T, CTransform<T>> {
  late Vector2D position;
  late double rotation;
  late Vector2D scale;
  
  CTransformSnapshot(super.namedId);

  @override
  CTransform<T> createInstance(T app) => .new(app,
    position: position.copy(),
    rotation: rotation,
    scale: scale.copy(),
  );
}