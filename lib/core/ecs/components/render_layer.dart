part of '../../raylib_dartified_unhinged.dart';

class CRenderLayer<T extends App<T>> extends Comp<T> {
  String layer;

  CRenderLayer(super.app, this.layer);

  // clone

  @override
  CRenderLayer<T> createInstance() => .new(app, layer);

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
}

class CRenderLayerSnapshot<T extends App<T>> extends CompSnapshot<T, CRenderLayer<T>> {
  late String layer;
  
  CRenderLayerSnapshot(super.namedId);

  @override
  CRenderLayer<T> createInstance(T app) => .new(app, layer);
}