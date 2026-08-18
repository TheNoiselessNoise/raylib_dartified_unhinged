part of '../../raylib_dartified_unhinged.dart';

/// Adds a one-shot start lifecycle hook to an ECS object.
///
/// The **on** phase only, starting is not cancelable and fires at most once
/// regardless of how many times [_doStart] is called.
mixin IsStartable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnStartKey = ECSHookKey<void Function(E self)>(
    'IsStartable', 'onStart'
  );

  /// Whether this object has already started.
  bool hasStarted = false;

  Iterable<void Function(E self)> get _onStartFns
    => hooksOf(hookOnStartKey);

  /// Registers [fn] to be called when this object starts.
  ///
  /// [fn] will fire at most once, on the first [_doStart] call.
  @nonVirtual
  E listenOnStart(void Function(E self) fn) {
    addHook(hookOnStartKey, fn);
    return self;
  }

  /// Commits the start: sets [hasStarted], notifies listeners, and calls [onStart].
  ///
  /// No-op if already started.
  void _doStart() {
    if (hasStarted) return;
    hasStarted = true;
    _onStartFns.forEach((fn) => fn(self));
    onStart();
  }

  /// Override to react when this object starts.
  ///
  /// Called after all registered [listenOnStart] listeners. Fires at most once.
  void onStart() {}
}