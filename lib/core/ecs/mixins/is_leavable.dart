part of '../../raylib_dartified_unhinged.dart';

/// Adds a leave lifecycle hook to an ECS object.
///
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsLeavable<T extends App<T>, E extends ECSBase<T>> on Self<E> {

  List<bool Function(E self)> _onBeforeLeaveFns = [];

  List<void Function(E self)> _onLeaveFns = [];

  List<void Function(E self)> _onAfterLeaveFns = [];

  /// Registers [fn] as a before-leave listener.
  ///
  /// [fn] returning `false` cancels the enter.
  @nonVirtual
  E listenOnBeforeLeave(bool Function(E self) fn) {
    _onBeforeLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] to be called when this object is left.
  /// 
  /// Called when the leave operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnLeave(void Function(E self) fn) {
    _onLeaveFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-leave listener.
  ///
  /// Called only if the leave was not canceled.
  @nonVirtual
  E listenOnAfterLeave(void Function(E self) fn) {
    _onAfterLeaveFns.add(fn);
    return self;
  }

  /// Runs all before-leave listeners and [onBeforeLeave].
  ///
  /// Returns `false` if any listener or the override cancels the leave.
  bool _doOnBeforeLeave() {
    if (!_onBeforeLeaveFns.every((f) => f(self))) return false;
    return onBeforeLeave();
  }

  /// Runs all leave listeners and [onLeave].
  void _doOnLeave() {
    _onLeaveFns.forEach((f) => f(self));
    onLeave();
  }

  /// Runs all after-leave listeners and [onAfterLeave].
  void _doOnAfterLeave() {
    _onAfterLeaveFns.forEach((f) => f(self));
    onAfterLeave();
  }

  /// Override to cancel an leave from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeLeave] listeners.
  bool onBeforeLeave() => true;

  /// Override to react when an leave is about to complete.
  ///
  /// Called by the host after all before-checks have passed.
  /// 
  /// Called after all registered [listenOnLeave] listeners.
  void onLeave() {}

  /// Override to react after an leave has completed.
  ///
  /// Called after all registered [listenOnAfterLeave] listeners.
  void onAfterLeave() {}
}