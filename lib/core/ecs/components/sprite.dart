part of '../../raylib_dartified_unhinged.dart';

// simple colored rect
class CSprite<T extends App<T>> extends Comp<T> {
  static const List<double> _defaultSize = [50, 50];

  Vector2D size; // unscaled local size
  ColorD? color;

  // cached for drawing
  RectangleD rect = .zero(); // dest rect (centered)
  Vector2D origin = .zero(); // origin relative to rec (usually center)

  CSprite(super.app, {
    super.populateDefaults,
    Vector2D? size,
    this.color,
  }) : size = size ?? .vec2(_defaultSize[0], _defaultSize[1]);

  @override
  void onUpdate(double dt) => entity.onTransform((t) {
    final w = size.x * t.scale.x;
    final h = size.y * t.scale.y;

    rect.set(t.position.x - w / 2, t.position.y - h / 2, w, h);
    origin.set(w / 2, h / 2);
  });

  @override
  void onDraw(double dt) => entity.onTransform((t) {
    backend.render.drawRectanglePro(
      rect,
      origin,
      t.rotation * 180.0 / math.pi,
      color ?? .WHITE,
    );
  });

  // clone

  @override
  CSprite<T> createInstance() {
    final c = CSprite<T>(app,
      size: size.copy(),
      color: color,
    );
    c.rect = rect.copy();
    c.origin = origin.copy();
    return c;
  }
  
  // state

  @override
  CSpriteSnapshot<T> createSnapshot() {
    final snapshot = CSpriteSnapshot<T>(namedId);
    snapshot.size = size.copy();
    snapshot.color = color?.copy();
    snapshot.rect = rect.copy();
    snapshot.origin = origin.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CSpriteSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    size = snapshot.size.copy();
    color = snapshot.color?.copy();
    rect = snapshot.rect.copy();
    origin = snapshot.origin.copy();
  }

  // persistence

  static const typeId = '__comp__CSprite';
  
  @override String get persistentTypeId => typeId;

  @override
  @mustCallSuper
  MapData getPersistableData({bool force = false}) => {
    ...super.getPersistableData(force: force),
    'size': size,
    'color': color?.getPersistableData(),
    'rect': rect.getPersistableData(),
    'origin': origin.getPersistableData(),
  };

  @override
  @mustCallSuper
  void restorePersistableData(MapTraversable data, {String? id}) {
    super.restorePersistableData(data, id: id);

    final sizeData = data.getList<double>('size', _defaultSize);
    size.restorePersistableData(sizeData);

    final colorData = data.getListOrNull<int>('color');
    if (colorData != null) color?.restorePersistableData(colorData);

    final rectData = data.getList<double>('rect');
    rect.restorePersistableData(rectData);

    final originData = data.getList<double>('origin');
    origin.restorePersistableData(originData);
  }
}

class CSpriteSnapshot<T extends App<T>> extends CompSnapshot<T, CSprite<T>> {
  late Vector2D size;
  late ColorD? color;
  late RectangleD rect;
  late Vector2D origin;
  
  CSpriteSnapshot(super.id);

  @override
  CSprite<T> createInstance(T app) {
    final c = CSprite<T>(app,
      size: size.copy(),
      color: color?.copy(),
    );
    c.rect = rect.copy();
    c.origin = origin.copy();
    return c;
  }
}