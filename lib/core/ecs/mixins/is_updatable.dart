part of '../../raylib_dartified_unhinged.dart';

/// Adds an update lifecycle hook to an ECS object.
///
/// The **on** phase only, updating is not cancelable.
mixin IsUpdatable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T> 
{
  late final hookOnUpdateKey = ECSHookKey<void Function(E self, double dt)>(
    'IsUpdatable', 'onUpdate'
  );

  Iterable<void Function(E self, double dt)> get _onUpdateFns
    => hooksOf(hookOnUpdateKey);

  /// Registers [fn] to be called during the update phase each frame.
  @nonVirtual
  E listenOnUpdate(void Function(E self, double dt) fn) {
    addHook(hookOnUpdateKey, fn);
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