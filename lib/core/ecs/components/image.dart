part of '../../raylib_dartified_unhinged.dart';

class CImage<T extends App<T>> extends Comp<T> {
  TextureD texture;

  /// If provided, draws a sub-rect from the texture (sprite sheet).
  /// If null, draws the full texture.
  RectangleD? sourceRect;

  ColorD? tint;

  // cached drawing data
  RectangleD source = .zero();
  RectangleD dest = .zero();
  Vector2D origin = .zero();

  /// Optional: override draw size in world units.
  /// If null, we try CSprite.size; if absent, we fall back to texture size.
  Vector2D? size;

  CImage(
    super.app, {
    required this.texture,
    this.sourceRect,
    this.tint,
    this.size,
  });

  Vector2D _getLocalSize() {
    if (size != null) return size!;
    final sprite = entity.get<CSprite<T>>();
    if (sprite != null) return sprite.size;

    // Fallback to texture dimensions (assuming your Texture2D exposes width/height)
    return .vec2(texture.width, texture.height);
  }

  @override
  void onUpdate(double dt) => entity.onTransform((t) {
    // Source rect
    if (sourceRect != null) {
      source = sourceRect!.copy();
    } else {
      source.set(0, 0, texture.width, texture.height);
    }

    // Dest rect: centered on transform.position, scaled by transform.scale
    final local = _getLocalSize();
    final w = local.x * t.scale.x;
    final h = local.y * t.scale.y;

    dest.set(
      t.position.x - w / 2,
      t.position.y - h / 2,
      w,
      h,
    );

    // Rotate/scale around center
    origin.set(w / 2, h / 2);
  });

  @override
  void onDraw(double dt) => entity.onTransform((t) {
    backend.render.drawTexturePro(
      texture,
      source,
      dest,
      origin,
      t.rotation * 180.0 / math.pi,
      tint ?? .WHITE,
    );
  });

  // clone

  @override
  CImage<T> createInstance() {
    final c = CImage<T>(
      app,
      texture: texture,
      sourceRect: sourceRect?.copy(),
      tint: tint,
      size: size?.copy(),
    );
    c.source = source.copy();
    c.dest = dest.copy();
    c.origin = origin.copy();
    return c;
  }

  // state

  @override
  CImageSnapshot<T> createSnapshot() {
    final snapshot = CImageSnapshot<T>(namedId);
    snapshot.texture = texture.copy();
    snapshot.sourceRect = sourceRect?.copy();
    snapshot.tint = tint?.copy();
    snapshot.source = source.copy();
    snapshot.dest = dest.copy();
    snapshot.origin = origin.copy();
    snapshot.size = size?.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CImageSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    texture = snapshot.texture.copy();
    sourceRect = snapshot.sourceRect?.copy();
    tint = snapshot.tint?.copy();
    source = snapshot.source.copy();
    dest = snapshot.dest.copy();
    origin = snapshot.origin.copy();
    size = snapshot.size?.copy();
  }
}

class CImageSnapshot<T extends App<T>> extends CompSnapshot<T, CImage<T>> {
  late TextureD texture;
  late RectangleD? sourceRect;
  late ColorD? tint;
  late RectangleD source;
  late RectangleD dest;
  late Vector2D origin;
  late Vector2D? size;
  
  CImageSnapshot(super.namedId);

  @override
  CImage<T> createInstance(T app) {
    final c = CImage<T>(
      app,
      texture: texture,
      sourceRect: sourceRect?.copy(),
      tint: tint,
      size: size?.copy(),
    );
    c.source = source.copy();
    c.dest = dest.copy();
    c.origin = origin.copy();
    return c;
  }
}