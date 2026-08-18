part of '../../raylib_dartified_unhinged.dart';

/// Adds an update lifecycle hook to an ECS object.
///
/// The **on** phase only, updating is not cancelable.
mixin IsUpdatable<T extends App<T>, E extends ECSBase<T>> on Self<E>, ECSBase<T> {
  List<void Function(E self, double dt)> _onUpdateFns = [];

  /// Registers [fn] to be called during the update phase each frame.
  @nonVirtual
  E listenOnUpdate(void Function(E self, double dt) fn) {
    _onUpdateFns.add(fn);
    return self;
  }

  /// Propagates the update phase through listeners and the [onUpdate] hook.
  void _doUpdate(double dt) {
    _onUpdateFns.forEach((f) => f(self, dt));
    onUpdate(dt);
  }

  /// Override to react during the update phase each frame.
  ///
  /// Called after all registered [listenOnUpdate] listeners.
  void onUpdate(double dt) {}
}