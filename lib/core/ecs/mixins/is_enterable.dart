part of '../../raylib_dartified_unhinged.dart';

/// Adds an enter lifecycle hook to an ECS object.
/// 
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsEnterable<
  T extends App<T>,
  E extends ECSBase<T>
> on
  Self<E>,
  ECSBase<T>
{
  late final hookOnBeforeEnterKey = ECSHookKey<bool Function(E self)>(
    'IsEnterable', 'onBeforeEnter'
  );

  late final hookOnEnterKey = ECSHookKey<void Function(E self)>(
    'IsEnterable', 'onEnter'
  );

  late final hookOnAfterEnterKey = ECSHookKey<void Function(E self)>(
    'IsEnterable', 'onAfterEnter'
  );

  Iterable<bool Function(E self)> get _onBeforeEnterFns
    => hooksOf(hookOnBeforeEnterKey);

  Iterable<void Function(E self)> get _onEnterFns
    => hooksOf(hookOnEnterKey);

  Iterable<void Function(E self)> get _onAfterEnterFns
    => hooksOf(hookOnAfterEnterKey);

  /// Registers [fn] as a before-enter listener.
  ///
  /// [fn] returning `false` cancels the enter.
  @nonVirtual
  E listenOnBeforeEnter(bool Function(E self) fn) {
    addHook(hookOnBeforeEnterKey, fn);
    return self;
  }

  /// Registers [fn] to be called when this object is entered.
  /// 
  /// Called when the enter operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnEnter(void Function(E self) fn) {
    addHook(hookOnEnterKey, fn);
    return self;
  }

  /// Registers [fn] as an after-enter listener.
  ///
  /// Called only if the enter was not canceled.
  @nonVirtual
  E listenOnAfterEnter(void Function(E self) fn) {
    addHook(hookOnAfterEnterKey, fn);
    return self;
  }

  /// Runs all before-enter listeners and [onBeforeEnter].
  ///
  /// Returns `false` if any listener or the override cancels the enter.
  @mustCallSuper
  bool _doOnBeforeEnter() {
    if (!_onBeforeEnterFns.every((f) => f(self))) return false;
    return onBeforeEnter();
  }

  /// Runs all enter listeners and [onEnter].
  @mustCallSuper
  void _doOnEnter() {
    _onEnterFns.forEach((f) => f(self));
    onEnter();
  }

  /// Runs all after-enter listeners and [onAfterEnter].
  @mustCallSuper
  void _doOnAfterEnter() {
    _onAfterEnterFns.forEach((f) => f(self));
    onAfterEnter();
  }

  /// Override to cancel an enter from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEnter] listeners.
  bool onBeforeEnter() => true;

  /// Override to react when an enter is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnEnter] listeners.
  void onEnter() {}

  /// Override to react after an enter has completed.
  ///
  /// Called after all registered [listenOnAfterEnter] listeners.
  void onAfterEnter() {}
}