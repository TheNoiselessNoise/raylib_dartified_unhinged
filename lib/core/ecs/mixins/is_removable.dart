part of '../../raylib_dartified_unhinged.dart';

/// Adds removal lifecycle hooks to an ECS object.
///
/// Provides a three-phase removal contract:
/// - **before** => cancelable; any listener or override returning `false` aborts removal
/// - **on** => the operation is about to complete; listeners are notified before the act completes
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsRemovable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnBeforeRemoveKey = ECSHookKey<HookResult Function(E self)>(
    'IsRemovable', 'onBeforeRemove'
  );

  late final hookOnRemoveKey = ECSHookKey<void Function(E self)>(
    'IsRemovable', 'onRemove'
  );

  late final hookOnAfterRemoveKey = ECSHookKey<void Function(E self)>(
    'IsRemovable', 'onAfterRemove'
  );

  /// Whether this object has been removed.
  bool isRemoved = false;

  Iterable<HookResult Function(E self)> get _onBeforeRemoveFns
    => hooksOf(hookOnBeforeRemoveKey);

  Iterable<void Function(E self)> get _onRemoveFns
    => hooksOf(hookOnRemoveKey);

  Iterable<void Function(E self)> get _onAfterRemoveFns
    => hooksOf(hookOnAfterRemoveKey);

  /// Registers [fn] as a before-remove listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  @nonVirtual
  E listenOnBeforeRemove(HookResult Function(E self) fn) {
    addHook(hookOnBeforeRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as a remove listener.
  ///
  /// Called when the remove operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnRemove(void Function(E self) fn) {
    addHook(hookOnRemoveKey, fn);
    return self;
  }

  /// Registers [fn] as an after-remove listener.
  ///
  /// Called only if removal was not canceled.
  @nonVirtual
  E listenOnAfterRemove(void Function(E self) fn) {
    addHook(hookOnAfterRemoveKey, fn);
    return self;
  }

  /// Runs all before-remove listeners and [onBeforeRemove], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnBeforeRemove() {
    HookResult result = .proceed;
    for (final f in _onBeforeRemoveFns) {
      result = _mergeHookResult(result, f(self));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforeRemove());
  }

  /// Runs all remove listeners and [onRemove].
  @mustCallSuper
  void _doOnRemove() {
    _onRemoveFns.forEach((f) => f(self));
    onRemove();
  }

  /// Runs all after-remove listeners and [onAfterRemove].
  @mustCallSuper
  void _doOnAfterRemove() {
    _onAfterRemoveFns.forEach((f) => f(self));
    onAfterRemove();
  }

  /// Notifies listeners and calls [onRemove] immediately before removal completes.
  ///
  /// Sets [isRemoved] and is a no-op if already removed.
  @mustCallSuper
  void _doRemove() {
    if (isRemoved) return;
    isRemoved = true;
    _doOnRemove();
  }

  /// Override to intercept the before-remove phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnBeforeRemove] listeners.
  HookResult onBeforeRemove() => .proceed;

  /// Override to react after removal has completed.
  ///
  /// Called after all registered [listenOnAfterRemove] listeners.
  void onAfterRemove() {}

  /// Override to react when removal is about to complete.
  ///
  /// Called after all registered [listenOnRemove] listeners.
  void onRemove() {}
}