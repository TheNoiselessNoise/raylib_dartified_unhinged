part of '../../raylib_dartified_unhinged.dart';

// simple colored rect
class CSprite<T extends App<T>> extends Comp<T> {
  Vector2D size; // unscaled local size
  ColorD? color;

  // cached for drawing
  RectangleD rect = .zero(); // dest rect (centered)
  Vector2D origin = .zero(); // origin relative to rec (usually center)

  CSprite(super.app, {
    Vector2D? size,
    this.color,
  }) : size = size ?? .vec2(50, 50);

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
}

class CSpriteSnapshot<T extends App<T>> extends CompSnapshot<T, CSprite<T>> {
  late Vector2D size;
  late ColorD? color;
  late RectangleD rect;
  late Vector2D origin;
  
  CSpriteSnapshot(super.namedId);

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