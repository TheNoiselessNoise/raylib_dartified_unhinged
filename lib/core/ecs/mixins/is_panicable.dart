part of '../../raylib_dartified_unhinged.dart';

// TODO: use this

/// Panic policy for handling exceptions.
enum PanicPolicy {
  /// Suppress the exception entirely and do nothing.
  swallow,

  /// Run standard panic handling.
  handle,

  /// Re-throw the exception so it bubbles up to the parent.
  rethrowError,
}

/// Adds a panic lifecycle hook to an ECS object.
mixin IsPanicable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  /// Configures how this object reacts to unhandled exceptions by default.
  PanicPolicy get panicPolicy => .handle;

  late final hookOnBeforePanicKey = ECSHookKey<HookResult Function(E self, Object error, StackTrace stack)>(
    'IsPanicable', 'onBeforePanic'
  );

  late final hookOnPanicKey = ECSHookKey<void Function(E self, Object error, StackTrace stack)>(
    'IsPanicable', 'onPanic'
  );

  late final hookOnAfterPanicKey = ECSHookKey<void Function(E self, Object error, StackTrace stack)>(
    'IsPanicable', 'onAfterPanic'
  );

  Iterable<HookResult Function(E self, Object error, StackTrace stack)> get _onBeforePanicFns
    => hooksOf(hookOnBeforePanicKey);

  Iterable<void Function(E self, Object error, StackTrace stack)> get _onPanicFns
    => hooksOf(hookOnPanicKey);

  Iterable<void Function(E self, Object error, StackTrace stack)> get _onAfterPanicFns
    => hooksOf(hookOnAfterPanicKey);

  /// Registers [fn] as a before-panic listener.
  ///
  /// [fn] returns a [HookResult] to control execution flow:
  /// - [HookResult.proceed] continues normally.
  /// - [HookResult.skip] skips the core action but runs the after-phase.
  /// - [HookResult.cancel] aborts the operation entirely.
  @nonVirtual
  E listenOnBeforePanic(HookResult Function(E self, Object error, StackTrace stack) fn) {
    addHook(hookOnBeforePanicKey, fn);
    return self;
  }

  /// Registers [fn] to be called when this object is about to panic.
  /// 
  /// Called when the panic operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnPanic(void Function(E self, Object error, StackTrace stack) fn) {
    addHook(hookOnPanicKey, fn);
    return self;
  }

  /// Registers [fn] as an after-panic listener.
  ///
  /// Called only if the panic was not canceled.
  @nonVirtual
  E listenOnAfterPanic(void Function(E self, Object error, StackTrace stack) fn) {
    addHook(hookOnAfterPanicKey, fn);
    return self;
  }

  /// Runs all before-panic listeners and [onBeforePanic], combining their [HookResult] decisions.
  ///
  /// Prioritizes [HookResult.cancel], followed by [HookResult.skip], defaulting to [HookResult.proceed].
  @mustCallSuper
  HookResult _doOnBeforePanic(Object error, StackTrace stack) {
    HookResult result = .proceed;
    for (final f in _onBeforePanicFns) {
      result = _mergeHookResult(result, f(self, error, stack));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforePanic(error, stack));
  }

  /// Runs all panic listeners and [onPanic].
  @mustCallSuper
  void _doOnPanic(Object error, StackTrace stack) {
    _onPanicFns.forEach((f) => f(self, error, stack));
    onPanic(error, stack);
  }

  /// Runs all after-panic listeners and [onAfterPanic].
  @mustCallSuper
  void _doOnAfterPanic(Object error, StackTrace stack) {
    _onAfterPanicFns.forEach((f) => f(self, error, stack));
    onAfterPanic(error, stack);
  }

  /// Override to intercept the before-panic phase from within the class.
  ///
  /// Returns a [HookResult] (defaults to [HookResult.proceed]). 
  /// Called after all registered [listenOnBeforePanic] listeners.
  HookResult onBeforePanic(Object error, StackTrace stack) => .proceed;

  /// Override to react when a panic is about to happen.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnPanic] listeners.
  void onPanic(Object error, StackTrace stack) {}

  /// Override to react after a panic occured.
  ///
  /// Called after all registered [listenOnAfterPanic] listeners.
  void onAfterPanic(Object error, StackTrace stack) {}

  void _runSafely(void Function() action) {
    try {
      action();
    } catch (error, stack) {
      final result = _doOnBeforePanic(error, stack);
      if (result == .cancel) return;

      if (result == .proceed) {
        switch (panicPolicy) {
          case .swallow:
            // do nothing
            break;
          case .handle:
            _doOnPanic(error, stack);
            break;
          case .rethrowError:
            _doOnAfterPanic(error, stack);
            rethrow;
        }
      }

      if (result != .cancel) {
        _doOnAfterPanic(error, stack);
      }
    }
  }
}