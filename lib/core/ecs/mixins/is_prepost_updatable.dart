part of '../../raylib_dartified_unhinged.dart';

/// Adds pre-update and post-update lifecycle hooks to an ECS object.
///
/// The **on** phase only, update boundaries are not cancelable.
mixin IsPrePostUpdatable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {
  List<void Function(E self, double dt)> _onPreUpdateFns = [];

  List<void Function(E self, double dt)> _onPostUpdateFns = [];

  /// Registers [fn] to be called before the update phase each frame.
  @nonVirtual
  E listenOnPreUpdate(void Function(E self, double dt) fn) {
    _onPreUpdateFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called after the update phase each frame.
  @nonVirtual
  E listenOnPostUpdate(void Function(E self, double dt) fn) {
    _onPostUpdateFns.add(fn);
    return self;
  }

  /// Notifies all pre-update listeners and calls [onPreUpdate].
  void _doPreUpdate(double dt) {
    _onPreUpdateFns.forEach((f) => f(self, dt));
    onPreUpdate(dt);
  }

  /// Notifies all post-update listeners and calls [onPostUpdate].
  void _doPostUpdate(double dt) {
    _onPostUpdateFns.forEach((f) => f(self, dt));
    onPostUpdate(dt);
  }

  /// Override to react before the update phase each frame.
  ///
  /// Called after all registered [listenOnPreUpdate] listeners.
  void onPreUpdate(double dt) {}

  /// Override to react after the update phase each frame.
  ///
  /// Called after all registered [listenOnPostUpdate] listeners.
  void onPostUpdate(double dt) {}
}