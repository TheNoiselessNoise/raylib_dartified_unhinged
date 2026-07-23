part of '../../raylib_dartified_unhinged.dart';

// world position, scale and rotation
class CTransform<T extends App<T>> extends Comp<T> {
  static const double _defaultRotation = 0;

  late Vector2D prevPosition;

  Vector2D position; // CENTER position in world space
  double rotation;   // radians
  Vector2D scale;    // 1,1 is identity

  CTransform(super.app, {
    super.populateDefaults,
    Vector2D? position,
    this.rotation = _defaultRotation,
    Vector2D? scale,
  }) :
    position = position ?? .zero(),
    scale = scale ?? .one()
  {
    prevPosition = this.position.copy();
  }

  @override
  @mustCallSuper
  void onUpdate(double dt) {
    if (isDisabled) return;
    prevPosition = position.copy();
  }

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

  // persistence

  static const typeId = '__comp__CTransform';
  
  @override String get persistentTypeId => typeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'position': position.getPersistableData(),
    'rotation': rotation,
    'scale': scale.getPersistableData(),
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);

    final positionData = data.getList<double>('position');
    position.restorePersistableData(positionData);

    rotation = data.getDouble('rotation', _defaultRotation);

    final scaleData = data.getList<double>('scale');
    scale.restorePersistableData(scaleData);
  }
}

class CTransformSnapshot<T extends App<T>> extends CompSnapshot<T, CTransform<T>> {
  late Vector2D position;
  late double rotation;
  late Vector2D scale;
  
  CTransformSnapshot(super.id);

  @override
  CTransform<T> createInstance(T app) => .new(app,
    position: position.copy(),
    rotation: rotation,
    scale: scale.copy(),
  );
}