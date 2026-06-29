part of '../../raylib_dartified_unhinged.dart';

class CLifetime<T extends App<T>> extends Comp<T> {
  double timeLeft;
  bool _enqueued = false;

  CLifetime(super.app, this.timeLeft);

  @override
  void onUpdate(double dt) {
    if (_enqueued) return;
    timeLeft -= dt;
    if (timeLeft <= 0) {
      _enqueued = true;
      command(RemoveEntityCommand(app, entity));
    }
  }

  // clone

  @override
  CLifetime<T> createInstance() => .new(app, timeLeft);

  // state

  @override
  CLifetimeSnapshot<T> createSnapshot() {
    final snapshot = CLifetimeSnapshot<T>(namedId);
    snapshot.timeLeft = timeLeft;
    snapshot._enqueued = _enqueued;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CLifetimeSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    timeLeft = snapshot.timeLeft;
    _enqueued = snapshot._enqueued;
  }
}

class CLifetimeSnapshot<T extends App<T>> extends CompSnapshot<T, CLifetime<T>> {
  late double timeLeft;
  late bool _enqueued;
  
  CLifetimeSnapshot(super.namedId);

  @override
  CLifetime<T> createInstance(T app) {
    final c = CLifetime<T>(app, timeLeft);
    c._enqueued = _enqueued;
    return c;
  }
}