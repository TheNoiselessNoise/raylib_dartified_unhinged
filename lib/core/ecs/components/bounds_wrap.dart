part of '../../raylib_dartified_unhinged.dart';

// wraps the entity around the screen
class CBoundsWrap<T extends App<T>> extends Comp<T> {
  late Bounds area;

  CBoundsWrap(super.app, {
    Bounds? area
  }) {
    this.area = area ?? .bounds(0, 0, screenHeight, screenWidth);
  }

  @override
  void onUpdate(double dt) {
    final screen = sceneBounds.size;
    final bounds = entity.bounds;

    entity.onTransform((t) {
      final hw = (bounds?.width ?? 0) / 2;
      final hh = (bounds?.height ?? 0) / 2;

      if (t.position.x + hw < 0) t.position.x = screen.x + hw;
      if (t.position.x - hw > screen.x) t.position.x = -hw;
      if (t.position.y + hh < 0) t.position.y = screen.y + hh;
      if (t.position.y - hh > screen.y) t.position.y = -hh;
    });
  }

  // clone

  @override
  CBoundsWrap<T> createInstance() => .new(app,
    area: area.copy(),
  );

  // state

  @override
  CBoundsWrapSnapshot<T> createSnapshot() {
    final snapshot = CBoundsWrapSnapshot<T>(namedId);
    snapshot.area = area.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CBoundsWrapSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    area = snapshot.area.copy();
  }
}

class CBoundsWrapSnapshot<T extends App<T>> extends CompSnapshot<T, CBoundsWrap<T>> {
  late Bounds area;
  
  CBoundsWrapSnapshot(super.namedId);

  @override
  CBoundsWrap<T> createInstance(T app) => .new(app,
    area: area.copy(),
  );
}