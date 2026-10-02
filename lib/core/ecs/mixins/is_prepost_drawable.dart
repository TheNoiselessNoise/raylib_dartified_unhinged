part of '../../raylib_dartified_unhinged.dart';

/// Adds pre-draw and post-draw lifecycle hooks to an ECS object.
mixin IsPrePostDrawable<
  T extends App<T>, 
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnPreDrawKey = ECSHookKey<HookResult Function(E self, double dt)>(
    'IsPrePostDrawable', 'onPreDraw'
  );

  late final hookOnPostDrawKey = ECSHookKey<void Function(E self, double dt)>(
    'IsPrePostDrawable', 'onPostDraw'
  );

  Iterable<HookResult Function(E self, double dt)> get _onPreDrawFns
    => hooksOf(hookOnPreDrawKey);

  Iterable<void Function(E self, double dt)> get _onPostDrawFns
    => hooksOf(hookOnPostDrawKey);

  /// Registers [fn] as a pre-draw listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  /// Registers [fn] to be called before the update phase each frame.
  @nonVirtual
  E listenOnPreDraw(HookResult Function(E self, double dt) fn) {
    addHook(hookOnPreDrawKey, fn);
    return self;
  }

  /// Registers [fn] to be called after the draw phase each frame.
  @nonVirtual
  E listenOnPostDraw(void Function(E self, double dt) fn) {
    addHook(hookOnPostDrawKey, fn);
    return self;
  }

  /// Runs all pre-draw listeners and [onPreDraw], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnPreDraw(double dt) {
    HookResult result = .proceed;
    for (final f in _onPreDrawFns) {
      result = _mergeHookResult(result, f(self, dt));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onPreDraw(dt));
  }

  /// Notifies all post-draw listeners and calls [onPostDraw].
  @mustCallSuper
  void _doOnPostDraw(double dt) {
    _onPostDrawFns.forEach((f) => f(self, dt));
    onPostDraw(dt);
  }

  /// Override to react before the draw phase each frame.
  ///
  /// Called after all registered [listenOnPreDraw] listeners.
  HookResult onPreDraw(double dt) => .proceed;

  /// Override to react after the draw phase each frame.
  ///
  /// Called after all registered [listenOnPostDraw] listeners.
  void onPostDraw(double dt) {}
}