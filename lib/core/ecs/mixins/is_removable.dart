part of '../../raylib_dartified_unhinged.dart';

/// Adds removal lifecycle hooks to an ECS object.
///
/// Provides a three-phase removal contract:
/// - **before** => cancelable; any listener or override returning `false` aborts removal
/// - **on** => the operation is about to complete; listeners are notified before the act completes
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsRemovable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  /// Whether this object has been removed.
  bool isRemoved = false;

  List<bool Function(E self)> _onBeforeRemoveFns = [];

  List<void Function(E self)> _onRemoveFns = [];

  List<void Function(E self)> _onAfterRemoveFns = [];

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returning `false` cancels the removal.
  @nonVirtual
  E listenOnBeforeRemove(bool Function(E self) fn) {
    _onBeforeRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnRemove(void Function(E self) fn) {
    _onRemoveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if removal was not canceled.
  @nonVirtual
  E listenOnAfterRemove(void Function(E self) fn) {
    _onAfterRemoveFns.add(fn);
    return self;
  }

  /// Runs all before-remove listeners and [onBeforeRemove].
  ///
  /// Returns `false` if any listener or the override cancels removal.
  bool _doOnBeforeRemove() {
    if (!_onBeforeRemoveFns.every((f) => f(self))) return false;
    return onBeforeRemove();
  }

  /// Runs all remove listeners and [onRemove].
  void _doOnRemove() {
    _onRemoveFns.forEach((f) => f(self));
    onRemove();
  }

  /// Runs all after-remove listeners and [onAfterRemove].
  void _doOnAfterRemove() {
    _onAfterRemoveFns.forEach((f) => f(self));
    onAfterRemove();
  }

  /// Notifies listeners and calls [onRemove] immediately before removal completes.
  ///
  /// Sets [isRemoved] and is a no-op if already removed.
  void _doRemove() {
    if (isRemoved) return;
    isRemoved = true;
    _doOnRemove();
  }

  /// Override to cancel removal from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeRemove] listeners.
  bool onBeforeRemove() => true;

  /// Override to react after removal has completed.
  ///
  /// Called after all registered [listenOnAfterRemove] listeners.
  void onAfterRemove() {}

  /// Override to react when removal is about to complete.
  ///
  /// Called after all registered [listenOnRemove] listeners.
  void onRemove() {}
}