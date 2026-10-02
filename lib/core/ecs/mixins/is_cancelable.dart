part of '../../raylib_dartified_unhinged.dart';

/// Adds cancelation lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Cancelation is a one-way transition: once canceled, the object stays canceled.
/// The [cancel] method drives the full lifecycle: guards, listeners, and state change.
mixin IsCancelable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final stateIsCanceledKey = ECSStateKey<bool>(
    'IsCancelable', 'isCanceled',
    get: () => _isCanceled,
    set: (value) => _isCanceled = value,
  );

  @override
  @mustCallSuper
  void _registerBuiltinStateKeys() {
    super._registerBuiltinStateKeys();
    registerStateKey(stateIsCanceledKey);
  }

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeCancelKey = ECSHookKey<HookResult Function(E self)>(
    'IsCancelable', 'onBeforeCancel'
  );

  late final hookOnCancelKey = ECSHookKey<void Function(E self)>(
    'IsCancelable', 'onCancel'
  );

  late final hookOnAfterCancelKey = ECSHookKey<void Function(E self)>(
    'IsCancelable', 'onAfterCancel'
  );

  Iterable<HookResult Function(E self)> get _onBeforeCancelFns
    => hooksOf(hookOnBeforeCancelKey);

  Iterable<void Function(E self)> get _onCancelFns
    => hooksOf(hookOnCancelKey);

  Iterable<void Function(E self)> get _onAfterCancelFns
    => hooksOf(hookOnAfterCancelKey);

  /// Registers [fn] as a before-cancel listener.
  ///
  /// [fn] returning `false` cancels the cancel.
  @nonVirtual
  E listenOnBeforeCancel(HookResult Function(E self) fn) {
    addHook(hookOnBeforeCancelKey, fn);
    return self;
  }

  /// Registers [fn] as a cancel listener.
  ///
  /// Called when the cancel operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnCancel(void Function(E self) fn) {
    addHook(hookOnCancelKey, fn);
    return self;
  }

  /// Registers [fn] as an after-cancel listener.
  ///
  /// Called only if the cancel was not canceled.
  @nonVirtual
  E listenOnAfterCancel(void Function(E self) fn) {
    addHook(hookOnAfterCancelKey, fn);
    return self;
  }

  /// Runs all before-cancel listeners and [onBeforeCancel].
  ///
  /// Returns `false` if any listener or the override cancels the cancel.
  @mustCallSuper
  HookResult _doOnBeforeCancel() {
    HookResult result = .proceed;
    for (final f in _onBeforeCancelFns) {
      result = _mergeHookResult(result, f(self));
      if (result == .cancel) return result;
    }
    return _mergeHookResult(result, onBeforeCancel());
  }

  /// Runs all cancel listeners and [onCancel].
  @mustCallSuper
  void _doOnCancel() {
    _onCancelFns.forEach((f) => f(self));
    onCancel();
  }

  /// Runs all after-cancel listeners and [onAfterCancel].
  @mustCallSuper
  void _doOnAfterCancel() {
    _onAfterCancelFns.forEach((f) => f(self));
    onAfterCancel();
  }

  /// Override to cancel the cancel from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeCancel] listeners.
  HookResult onBeforeCancel() => .proceed;

  /// Override to react when the cancel is about to complete.
  ///
  /// Called after all registered [listenOnCancel] listeners.
  void onCancel() {}

  /// Override to react after the cancel has completed.
  ///
  /// Called after all registered [listenOnAfterCancel] listeners.
  void onAfterCancel() {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  bool _isCanceled = false;

  /// Whether this object has been canceled.
  bool get isCanceled => _isCanceled;

  /// Attempts to cancel this object.
  ///
  /// Returns `true` if cancelation succeeded, `false` if it was already
  /// canceled or any `before` hooks listeners vetoed it.
  bool cancel() {
    if (_isCanceled) return false;
    HookResult result = _doOnBeforeCancel();
    if (result == .cancel) return false;
    if (result == .proceed) _doOnCancel();
    _isCanceled = true;
    _doOnAfterCancel();
    return true;
  }
}