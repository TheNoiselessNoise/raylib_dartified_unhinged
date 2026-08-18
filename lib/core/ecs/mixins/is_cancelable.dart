part of '../../raylib_dartified_unhinged.dart';

/// Adds cancelation lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Cancelation is a one-way transition: once canceled, the object stays canceled.
/// The [cancel] method drives the full lifecycle: guards, listeners, and state change.
mixin IsCancelable<T extends App<T>, E extends ECSBase<T>> on ECSBase<T>, Self<E> {

  bool _isCanceled = false;

  /// Whether this object has been canceled.
  bool get isCanceled => _isCanceled;

  List<bool Function(E self)> _onBeforeCancelFns = [];

  List<void Function(E self)> _onCancelFns = [];

  List<void Function(E self)> _onAfterCancelFns = [];

  /// Registers [fn] as a before-cancel listener.
  ///
  /// [fn] returning `false` cancels the cancel.
  @nonVirtual
  E listenOnBeforeCancel(bool Function(E self) fn) {
    _onBeforeCancelFns.add(fn);
    return self;
  }

  /// Registers [fn] as a cancel listener.
  ///
  /// Called when the cancel operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnCancel(void Function(E self) fn) {
    _onCancelFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-cancel listener.
  ///
  /// Called only if the cancel was not canceled.
  @nonVirtual
  E listenOnAfterCancel(void Function(E self) fn) {
    _onAfterCancelFns.add(fn);
    return self;
  }

  /// Runs all before-cancel listeners and [onBeforeCancel].
  ///
  /// Returns `false` if any listener or the override cancels the cancel.
  bool _doOnBeforeCancel() {
    if (!_onBeforeCancelFns.every((f) => f(self))) return false;
    return onBeforeCancel();
  }

  /// Runs all cancel listeners and [onCancel].
  void _doOnCancel() {
    _onCancelFns.forEach((f) => f(self));
    onCancel();
  }

  /// Runs all after-cancel listeners and [onAfterCancel].
  void _doOnAfterCancel() {
    _onAfterCancelFns.forEach((f) => f(self));
    onAfterCancel();
  }

  /// Override to cancel the cancel from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeCancel] listeners.
  bool onBeforeCancel() => true;

  /// Override to react when the cancel is about to complete.
  ///
  /// Called after all registered [listenOnCancel] listeners.
  void onCancel() {}

  /// Override to react after the cancel has completed.
  ///
  /// Called after all registered [listenOnAfterCancel] listeners.
  void onAfterCancel() {}

  /// Attempts to cancel this object.
  ///
  /// Returns `true` if cancelation succeeded, `false` if it was already
  /// canceled or any `before` hooks listeners vetoed it.
  bool cancel() {
    if (_isCanceled) return false;
    if (!_doOnBeforeCancel()) return false;
    _doOnCancel();
    _isCanceled = true;
    _doOnAfterCancel();
    return true;
  }
}