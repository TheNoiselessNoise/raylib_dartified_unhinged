part of '../../raylib_dartified_unhinged.dart';

// keep the entity inside the bounds
class CBoundsConstraint<T extends App<T>> extends Comp<T> {
  late Bounds area;

  CBoundsConstraint(super.app, {
    Bounds? area,
  }) {
    this.area = area ?? .bounds(0, 0, screenHeight, screenWidth);
  }

  @override
  void onUpdate(double dt) => entity.on2<CTransform<T>, CVelocity<T>>((t, v) {
    final bounds = entity.bounds!;

    var dx = v.velocity.x;
    var dy = v.velocity.y;

    if (bounds.left + dx < area.left) {
      dx = area.left - bounds.left;
    } else if (bounds.right + dx > area.right) {
      dx = area.right - bounds.right;
    }

    if (bounds.top + dy < area.top) {
      dy = area.top - bounds.top;
    } else if (bounds.bottom + dy > area.bottom) {
      dy = area.bottom - bounds.bottom;
    }

    t.position.x += dx;
    t.position.y += dy;
  });

  // clone

  @override
  CBoundsConstraint<T> createInstance() => .new(app,
    area: area.copy(),
  );

  // state

  @override
  CBoundsConstraintSnapshot<T> createSnapshot() {
    final snapshot = CBoundsConstraintSnapshot<T>(namedId);
    snapshot.area = area.copy();
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CBoundsConstraintSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    area = snapshot.area.copy();
  }
}

class CBoundsConstraintSnapshot<T extends App<T>> extends CompSnapshot<T, CBoundsConstraint<T>> {
  late Bounds area;
  
  CBoundsConstraintSnapshot(super.namedId);

  @override
  CBoundsConstraint<T> createInstance(T app) => .new(app,
    area: area.copy(),
  );
}
