part of '../../raylib_dartified_unhinged.dart';

class COutOfBounds<T extends App<T>> extends Comp<T> {
  bool checkLeft;
  bool checkTop;
  bool checkRight;
  bool checkBottom;

  bool left = false;
  bool top = false;
  bool right = false;
  bool bottom = false;
  void Function(COutOfBounds<T> self)? then;

  bool triggerOnce;

  COutOfBounds(super.app, {
    this.checkLeft = true,
    this.checkTop = true,
    this.checkRight = true,
    this.checkBottom = true,
    this.then,
    this.triggerOnce = true,
  });

  bool _thenCalled = false;
  void reset() => _thenCalled = false;

  @override
  void onUpdate(double dt) {
    final screen = sceneBounds.size;
    final bounds = entity.bounds;
    if (bounds == null) return;

    left = checkLeft && bounds.right < 0;
    top = checkTop && bounds.bottom < 0;
    right = checkRight && bounds.left > screen.x;
    bottom = checkBottom && bounds.top > screen.y;

    if (!(left || top || right || bottom)) return;
    
    if (then != null && !_thenCalled) {
      if (triggerOnce) _thenCalled = true;
      then!(this);
    } else {
      command(RemoveEntityCommand(app, entity));
    }
  }

  @override
  COutOfBounds<T> createInstance() => .new(app,
    checkLeft: checkLeft,
    checkTop: checkTop,
    checkRight: checkRight,
    checkBottom: checkBottom,
    then: then,
    triggerOnce: triggerOnce,
  );

  // state

  @override
  COutOfBoundsSnapshot<T> createSnapshot() {
    final snapshot = COutOfBoundsSnapshot<T>(namedId);
    snapshot.checkLeft = checkLeft;
    snapshot.checkTop = checkTop;
    snapshot.checkRight = checkRight;
    snapshot.checkBottom = checkBottom;

    snapshot.left = left;
    snapshot.top = top;
    snapshot.right = right;
    snapshot.bottom = bottom;
    snapshot.then = then;

    snapshot.triggerOnce = triggerOnce;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant COutOfBoundsSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    checkLeft = snapshot.checkLeft;
    checkTop = snapshot.checkTop;
    checkRight = snapshot.checkRight;
    checkBottom = snapshot.checkBottom;

    left = snapshot.left;
    top = snapshot.top;
    right = snapshot.right;
    bottom = snapshot.bottom;
    then = snapshot.then;

    triggerOnce = snapshot.triggerOnce;
  }
}

class COutOfBoundsSnapshot<T extends App<T>> extends CompSnapshot<T, COutOfBounds<T>> {
  late bool checkLeft;
  late bool checkTop;
  late bool checkRight;
  late bool checkBottom;

  late bool left;
  late bool top;
  late bool right;
  late bool bottom;
  late void Function(COutOfBounds<T> self)? then;

  late bool triggerOnce;
  
  COutOfBoundsSnapshot(super.namedId);

  @override
  COutOfBounds<T> createInstance(T app) {
    final c = COutOfBounds<T>(app,
      checkLeft: checkLeft,
      checkTop: checkTop,
      checkRight: checkRight,
      checkBottom: checkBottom,
      then: then,
      triggerOnce: triggerOnce,
    );

    c.left = left;
    c.top = top;
    c.right = right;
    c.bottom = bottom;

    return c;
  }
}