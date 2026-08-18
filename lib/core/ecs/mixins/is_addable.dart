part of '../../raylib_dartified_unhinged.dart';

/// Adds add lifecycle hooks to an ECS object, from the object's own perspective.
///
/// Complements [IsAppSystemManagable], [IsSceneSystemManagable], [IsSceneManagable], [IsEntityManagable], [IsComponentManagable]
/// (which hooks from the *host* side) by giving the object being added its own three-phase contract:
/// - **before** => cancelable; any listener or override returning `false` aborts the operation
/// - **on** => the operation is about to complete; called by the host after all before-checks pass
/// - **after** => the operation has completed; side-effects and cleanup go here
mixin IsAddable<T extends App<T>, E extends ECSBase<T>> on ECSBase<T>, Self<E> {

  /// Whether this object has been added to a host.
  bool _isAdded = false;
  
  bool get isAdded => _isAdded;

  List<bool Function(E self, ECSBase<T> parent)> _onBeforeAddFns = [];

  List<void Function(E self, ECSBase<T> parent)> _onAddFns = [];

  List<void Function(E self, ECSBase<T> parent)> _onAfterAddFns = [];

  /// Registers [fn] as a before-add listener.
  ///
  /// [fn] returning `false` cancels the add.
  @nonVirtual
  E listenOnBeforeAdd(bool Function(E self, ECSBase<T> parent) fn) {
    _onBeforeAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an add listener.
  ///
  /// Called when the add operation is about to happen and was not canceled.
  @nonVirtual
  E listenOnAdd(void Function(E self, ECSBase<T> parent) fn) {
    _onAddFns.add(fn);
    return self;
  }

  /// Registers [fn] as an after-add listener.
  ///
  /// Called only if the add was not canceled.
  @nonVirtual
  E listenOnAfterAdd(void Function(E self, ECSBase<T> parent) fn) {
    _onAfterAddFns.add(fn);
    return self;
  }

  /// Runs all before-add listeners and [onBeforeAdd].
  ///
  /// Returns `false` if any listener or the override cancels the add.
  bool _doOnBeforeAdd(ECSBase<T> parent) {
    if (!_onBeforeAddFns.every((f) => f(self, parent))) return false;
    return onBeforeAdd(parent);
  }

  /// Runs all add listeners and [onAdd].
  void _doOnAdd(ECSBase<T> parent) {
    _onAddFns.forEach((f) => f(self, parent));
    onAdd(parent);
  }

  /// Runs all after-add listeners and [onAfterAdd].
  void _doOnAfterAdd(ECSBase<T> parent) {
    _onAfterAddFns.forEach((f) => f(self, parent));
    onAfterAdd(parent);
  }

  /// Override to cancel the add from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeAdd] listeners.
  bool onBeforeAdd(ECSBase<T> parent) => true;

  /// Override to react when the add is about to complete.
  ///
  /// Called after all registered [listenOnAdd] listeners.
  void onAdd(ECSBase<T> parent) {}

  /// Override to react after the add has completed.
  ///
  /// Called after all registered [listenOnAfterAdd] listeners.
  void onAfterAdd(ECSBase<T> parent) {}

  /// Commits the add: sets [isAdded], assigns [parent], and notifies listeners.
  ///
  /// No-op if already added.
  void _doAdd(ECSBase<T> parent) {
    if (isAdded) return;
    this.parent ??= parent;
    _isAdded = true;
    _doOnAdd(parent);
  }
}