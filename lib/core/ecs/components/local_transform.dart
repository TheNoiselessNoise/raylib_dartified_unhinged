part of '../../raylib_dartified_unhinged.dart';

class CLocalTransform<T extends App<T>> extends Comp<T> {
  static const double _defaultRotation = 0;

  Vector2D offset; // OFFSET from a parent
  double rotation; // radians
  Vector2D scale;  // 1,1 is identity

  CLocalTransform(super.app, {
    super.populateDefaults,
    Vector2D? offset,
    this.rotation = _defaultRotation,
    Vector2D? scale,
  }) :
    offset = offset ?? .zero(),
    scale = scale ?? .one();

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

  // persistence

  static const typeId = '__comp__CLocalTransform';
  
  @override String get persistentTypeId => typeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'offset': offset.getPersistableData(),
    'rotation': rotation,
    'scale': scale.getPersistableData(),
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);

    final offsetData = data.getList<double>('offset');
    offset.restorePersistableData(offsetData);

    rotation = data.getDouble('rotation', _defaultRotation);

    final scaleData = data.getList<double>('scale');
    scale.restorePersistableData(scaleData);
  }
}

class CLocalTransformSnapshot<T extends App<T>> extends CompSnapshot<T, CLocalTransform<T>> {
  late Vector2D offset;
  late double rotation;
  late Vector2D scale;
  
  CLocalTransformSnapshot(super.id);

  @override
  CLocalTransform<T> createInstance(T app) => .new(app,
    offset: offset.copy(),
    rotation: rotation,
    scale: scale.copy(),
  );
}