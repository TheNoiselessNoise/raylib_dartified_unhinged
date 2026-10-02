part of '../../raylib_dartified_unhinged.dart';

/// Adds pre-update and post-update lifecycle hooks to an ECS object.
mixin IsPrePostUpdatable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnPreUpdateKey = ECSHookKey<HookResult Function(E self, double dt)>(
    'IsPrePostUpdatable', 'onPreUpdate'
  );

  late final hookOnPostUpdateKey = ECSHookKey<void Function(E self, double dt)>(
    'IsPrePostUpdatable', 'onPostUpdate'
  );

  Iterable<HookResult Function(E self, double dt)> get _onPreUpdateFns
    => hooksOf(hookOnPreUpdateKey);

  Iterable<void Function(E self, double dt)> get _onPostUpdateFns
    => hooksOf(hookOnPostUpdateKey);

  /// Registers [fn] as a pre-update listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  /// Registers [fn] to be called before the update phase each frame.
  @nonVirtual
  E listenOnPreUpdate(HookResult Function(E self, double dt) fn) {
    addHook(hookOnPreUpdateKey, fn);
    return self;
  }

  /// Registers [fn] to be called after the update phase each frame.
  @nonVirtual
  E listenOnPostUpdate(void Function(E self, double dt) fn) {
    addHook(hookOnPostUpdateKey, fn);
    return self;
  }

  /// Runs all pre-update listeners and [onPreUpdate], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnPreUpdate(double dt) {
    HookResult result = .proceed;
    for (final f in _onPreUpdateFns) {
      result = _mergeHookResult(result, f(self, dt));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onPreUpdate(dt));
  }

  /// Notifies all post-update listeners and calls [onPostUpdate].
  @mustCallSuper
  void _doOnPostUpdate(double dt) {
    _onPostUpdateFns.forEach((f) => f(self, dt));
    onPostUpdate(dt);
  }

  /// Override to intercept the pre-update phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnPreUpdate] listeners.
  HookResult onPreUpdate(double dt) => .proceed;

  /// Override to react after the update phase each frame.
  ///
  /// Called after all registered [listenOnPostUpdate] listeners.
  void onPostUpdate(double dt) {}
}