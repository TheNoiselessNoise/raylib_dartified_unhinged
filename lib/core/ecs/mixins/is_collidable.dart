part of '../../raylib_dartified_unhinged.dart';

/// Adds collision lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Complements [CCollider]
/// (which hooks from the *host* side) by giving the object being collided its own three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsCollidable<
  T extends App<T>,
  E extends ECSBase<T>,
  C extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnBeforeCollisionKey = ECSHookKey<bool Function(E self, C other)>(
    'IsCollidable', 'onBeforeCollision'
  );

  late final hookOnCollisionKey = ECSHookKey<void Function(E self, C other)>(
    'IsCollidable', 'onCollision'
  );

  late final hookOnAfterCollisionKey = ECSHookKey<void Function(E self, C other)>(
    'IsCollidable', 'onAfterCollision'
  );

  Iterable<bool Function(E self, C other)> get _onBeforeCollisionFns
    => hooksOf(hookOnBeforeCollisionKey);

  Iterable<void Function(E self, C other)> get _onCollisionFns
    => hooksOf(hookOnCollisionKey);

  Iterable<void Function(E self, C other)> get _onAfterCollisionFns
    => hooksOf(hookOnAfterCollisionKey);

  /// Registers [fn] as a before-collision listener.
  ///
  /// [fn] returning `false` cancels the collision.
  @nonVirtual
  E listenOnBeforeCollision(bool Function(E self, C other) fn) {
    addHook(hookOnBeforeCollisionKey, fn);
    return self;
  }

  /// Registers [fn] as a collision listener.
  ///
  /// Called when the collision operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnCollision(void Function(E self, C other) fn) {
    addHook(hookOnCollisionKey, fn);
    return self;
  }

  /// Registers [fn] as an after-collision listener.
  ///
  /// Called only if the collision was not canceled.
  @nonVirtual
  E listenOnAfterCollision(void Function(E self, C other) fn) {
    addHook(hookOnAfterCollisionKey, fn);
    return self;
  }

  /// Runs all before-collision listeners and [onBeforeCollision].
  ///
  /// Returns `false` if any listener or the override cancels the collision.
  @mustCallSuper
  bool _doOnBeforeCollision(C other) {
    if (!_onBeforeCollisionFns.every((f) => f(self, other))) return false;
    return onBeforeCollision(other);
  }

  /// Runs all collision listeners and [onCollision].
  @mustCallSuper
  void _doOnCollision(C other) {
    _onCollisionFns.forEach((f) => f(self, other));
    onCollision(other);
  }

  /// Runs all after-collision listeners and [onAfterCollision].
  @mustCallSuper
  void _doOnAfterCollision(C other) {
    _onAfterCollisionFns.forEach((f) => f(self, other));
    onAfterCollision(other);
  }

  /// Override to cancel the collision from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeCollision] listeners.
  bool onBeforeCollision(C other) => true;

  /// Override to react when the collision is about to complete.
  ///
  /// Called after all registered [listenOnCollision] listeners.
  void onCollision(C other) {}

  /// Override to react after the collision has completed.
  ///
  /// Called after all registered [listenOnAfterCollision] listeners.
  void onAfterCollision(C other) {}
}