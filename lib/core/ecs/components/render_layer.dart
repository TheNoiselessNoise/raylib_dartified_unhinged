part of '../../raylib_dartified_unhinged.dart';

class CRenderLayer<T extends App<T>> extends Comp<T> {
  late String layer;

  CRenderLayer(super.app, {
    super.populateDefaults,
    String? layer,
  }) : layer = layer ?? RenderLayers.world.name;

  // clone

  @override
  CRenderLayer<T> createInstance() => .new(app,
    layer: layer,
  );

  // state

  @override
  CRenderLayerSnapshot<T> createSnapshot() {
    final snapshot = CRenderLayerSnapshot<T>(namedId);
    snapshot.layer = layer;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CRenderLayerSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    layer = snapshot.layer;
  }

  // persistence

  static const typeId = '__comp__CRenderLayer';
  
  @override String get persistentTypeId => typeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'layer': layer,
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);

    layer = data.getString('layer');
  }
}

class CRenderLayerSnapshot<T extends App<T>> extends CompSnapshot<T, CRenderLayer<T>> {
  late String layer;
  
  CRenderLayerSnapshot(super.id);

  @override
  CRenderLayer<T> createInstance(T app) => .new(app,
    layer: layer,
  );
}