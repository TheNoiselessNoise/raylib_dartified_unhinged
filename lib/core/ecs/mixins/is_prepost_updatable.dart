part of '../../raylib_dartified_unhinged.dart';

/// Adds pre-update and post-update lifecycle hooks to an ECS object.
///
/// The **on** phase only, update boundaries are not cancelable.
mixin IsPrePostUpdatable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnPreUpdateKey = ECSHookKey<void Function(E self, double dt)>(
    'IsPrePostUpdatable', 'onPreUpdate'
  );

  late final hookOnPostUpdateKey = ECSHookKey<void Function(E self, double dt)>(
    'IsPrePostUpdatable', 'onPostUpdate'
  );

  Iterable<void Function(E self, double dt)> get _onPreUpdateFns
    => hooksOf(hookOnPreUpdateKey);

  Iterable<void Function(E self, double dt)> get _onPostUpdateFns
    => hooksOf(hookOnPostUpdateKey);

  /// Registers [fn] to be called before the update phase each frame.
  @nonVirtual
  E listenOnPreUpdate(void Function(E self, double dt) fn) {
    addHook(hookOnPreUpdateKey, fn);
    return self;
  }

  /// Registers [fn] to be called after the update phase each frame.
  @nonVirtual
  E listenOnPostUpdate(void Function(E self, double dt) fn) {
    addHook(hookOnPostUpdateKey, fn);
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